import cv2
import pandas as pd
import numpy as np
from tqdm import tqdm
import argparse

def read_csv(filename):
    df = pd.read_csv(filename, header=[1, 2])
    body_parts = df.columns.levels[0].tolist()[1:]  # Ignore scorer column
    return df, body_parts

def normalize_likelihood(df):
    min_val = df.min().min()
    max_val = df.max().max()
    return (df - min_val) / (max_val - min_val)

def generate_color_palette(df):
    start_color = np.array([249, 82, 91, 255])  # Red
    end_color = np.array([219, 219, 221, 255])  # Grey
    colors = np.empty((len(df), 4), dtype=np.uint8)
    
    for i in range(len(df)):
        val = df.iloc[i].values[0]
        colors[i] = (1.0 - val) * start_color + val * end_color
    return colors

def overlay_bodypart_on_video(video_file, output_file, df, colors):
    cap = cv2.VideoCapture(video_file)
    fourcc = cv2.VideoWriter_fourcc(*'XVID')
    out = cv2.VideoWriter(output_file, fourcc, 20.0, (int(cap.get(3)), int(cap.get(4))))

    for frame_idx in tqdm(range(len(df))):
        ret, frame = cap.read()
        if not ret:
            break

        for part, color in zip(df.columns.levels[0][1:], colors):
            x, y = int(df[(part, 'x')].iloc[frame_idx]), int(df[(part, 'y')].iloc[frame_idx])
            if 0 <= x < frame.shape[1] and 0 <= y < frame.shape[0]:
                cv2.circle(frame, (x, y), 6, color.tolist(), 2)
        
        out.write(frame)

    cap.release()
    out.release()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Overlay body part coordinates on video.')
    parser.add_argument('csv_file', type=str, help='Path to the CSV file')
    parser.add_argument('video_file', type=str, help='Path to the video file')
    parser.add_argument('output_file', type=str, help='Path to the output video file')
    args = parser.parse_args()

    df, body_parts = read_csv(args.csv_file)
    likelihood_df = df.xs('likelihood', level=1, axis=1)
    normalized_likelihood_df = normalize_likelihood(likelihood_df)
    colors = generate_color_palette(normalized_likelihood_df)

    overlay_bodypart_on_video(args.video_file, args.output_file, df, colors)