use clap::Parser;
use csv::Reader;
use image::{DynamicImage, ImageBuffer, Rgba};
use indicatif::{ProgressBar, ProgressStyle};
use std::error::Error;
use std::path::PathBuf;

use ffmpeg_next as ffmpeg;
use ffmpeg_next::codec::context::Context;
use ffmpeg_next::codec::encoder::video::Video as VideoEncoder;
use ffmpeg_next::format::context::{Input, Output};
use ffmpeg_next::format::{flag, Pixel};
use ffmpeg_next::frame::Video as Frame;
use ffmpeg_next::software::scaling::{context::Context as ScalingContext, flag::Flags};

#[derive(Parser)]
#[clap(name = "Overlay Bodypart on Video")]
#[clap(version = "1.0")]
#[clap(about = "Overlay bodypart data on video frames")]
struct Cli {
    #[clap(short, long, value_parser)]
    csv_file: PathBuf,
    #[clap(short, long, value_parser)]
    video_file: PathBuf,
    #[clap(short, long, value_parser)]
    output_folder: PathBuf,
}

fn read_csv(
    csv_file: &PathBuf,
) -> Result<(Vec<f64>, Vec<f64>, Vec<f64>), Box<dyn Error>> {
    let mut rdr = Reader::from_path(csv_file)?;
    let mut x_coords = Vec::new();
    let mut y_coords = Vec::new();
    let mut likelihood = Vec::new();

    for result in rdr.records() {
        let record = result?;
        x_coords.push(record[1].parse::<f64>()?);
        y_coords.push(record[2].parse::<f64>()?);
        likelihood.push(record[3].parse::<f64>()?);
    }

    Ok((x_coords, y_coords, likelihood))
}

fn normalize_likelihood(likelihood: &[f64]) -> Vec<f64> {
    let min_val = likelihood.iter().cloned().fold(f64::INFINITY, f64::min);
    let max_val = likelihood.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
    likelihood
        .iter()
        .map(|&val| (val - min_val) / (max_val - min_val))
        .collect()
}

fn generate_color_palette(likelihood: &[f64]) -> Vec<Rgba<u8>> {
    let start_color = [249, 82, 91, 255]; // Red
    let end_color = [219, 219, 221, 255]; // Grey
    likelihood
        .iter()
        .map(|&val| {
            Rgba([
                ((1.0 - val) * start_color[0] as f64 + val * end_color[0] as f64) as u8,
                ((1.0 - val) * start_color[1] as f64 + val * end_color[1] as f64) as u8,
                ((1.0 - val) * start_color[2] as f64 + val * end_color[2] as f64) as u8,
                255,
            ])
        })
        .collect()
}

fn overlay_bodypart_on_video(
    video_file: &PathBuf,
    output_folder: &PathBuf,
    x_coords: &[f64],
    y_coords: &[f64],
    colors: &[Rgba<u8>],
) -> Result<(), Box<dyn Error>> {
    ffmpeg::init()?;

    let mut input_ctx = Input::from_path(video_file)?;

    let input_stream = input_ctx
        .streams()
        .best(ffmpeg::media::Type::Video)
        .ok_or(ffmpeg::Error::StreamNotFound)?;
    let input_video_stream_index = input_stream.index();
    let input_width = input_stream.codec().width();
    let input_height = input_stream.codec().height();
    let input_format = input_stream.codec().format();
    let input_frame_rate = input_stream.frame_rate();
    let input_time_base = input_stream.time_base();

    let codec = ffmpeg::codec::decoder::find(input_stream.codec().id()).ok_or(ffmpeg::Error::DecoderNotFound)?;
    let mut decoder = codec.video()?;

    let scaler = ScalingContext::get(
        input_format,
        input_width,
        input_height,
        Pixel::RGB24,
        input_width,
        input_height,
        Flags::BILINEAR,
    )?;

    let mut output_path = output_folder.clone();
    output_path.push("overlayed_output.mp4");
    let mut output_ctx = Output::create(&output_path)?;

    let global_header = output_ctx.format().flags().contains(flag::Flags::GLOBAL_HEADER);

    let mut encoder = ffmpeg::codec::encoder::find(ffmpeg::codec::Id::H264)
        .ok_or(ffmpeg::Error::EncoderNotFound)?
        .video()?;

    encoder.set_width(input_width);
    encoder.set_height(input_height);
    encoder.set_format(Pixel::YUV420P);
    encoder.set_frame_rate(input_frame_rate);
    encoder.set_time_base(input_time_base);

    if global_header {
        encoder.set_flags(ffmpeg::codec::flag::Flags::GLOBAL_HEADER);
    }

    let mut context = Context::new();
    context.set_encoder(encoder)?;
    let mut encoder = context.encoder().open()?;

    let mut output_stream = output_ctx.add_stream(encoder)?;

    if global_header {
        output_stream.set_flags(ffmpeg::codec::flag::Flags::GLOBAL_HEADER);
    }

    output_ctx.write_header()?;

    let frame_count = input_ctx.duration() as usize;
    let bar = ProgressBar::new(frame_count as u64);
    bar.set_style(
        ProgressStyle::default_bar()
            .template("{msg} {wide_bar} {pos}/{len} ({eta})")?
            .progress_chars("=>-"),
    );

    let mut decoded = Frame::empty();
    let mut scaler_frame = Frame::empty();
    let mut encoded = ffmpeg::Packet::empty();

    for (i, (x, y)) in x_coords.iter().zip(y_coords.iter()).enumerate() {
        while let Ok(true) = input_ctx.read(&mut decoded) {
            if decoded.index() == input_video_stream_index {
                let mut image = ImageBuffer::<Rgba<u8>, _>::from_raw(
                    decoded.width(),
                    decoded.height(),
                    decoded.data(0).to_vec(),
                ).ok_or("Failed to create image buffer")?;

                image.put_pixel(*x as u32, *y as u32, colors[i]);

                let dynamic_image = DynamicImage::ImageRgba8(image);
                let rgb_image = dynamic_image.to_rgb8();

                scaler.run(&decoded, &mut scaler_frame)?;

                let mut frame = Frame::empty();
                frame.plane_mut::<(u8, u8, u8)>(0).copy_from_slice(rgb_image.as_flat_samples().as_slice());

                if encoder.encode(&frame, &mut encoded)? {
                    output_ctx.write_frame(&encoded)?;
                }

                bar.inc(1);
                break;
            }
        }
    }

    bar.finish();

    Ok(())
}

fn main() -> Result<(), Box<dyn Error>> {
    let args = Cli::parse();

    let (x_coords, y_coords, likelihood) = read_csv(&args.csv_file)?;
    let likelihood = normalize_likelihood(&likelihood);
    let colors = generate_color_palette(&likelihood);

    overlay_bodypart_on_video(
        &args.video_file,
        &args.output_folder,
        &x_coords,
        &y_coords,
        &colors,
    )?;

    Ok(())
}