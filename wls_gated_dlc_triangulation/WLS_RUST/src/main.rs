use nalgebra::{DMatrix, DVector};
use csv::ReaderBuilder;
use indicatif::{ProgressBar, ProgressStyle};
use regex::Regex;
use std::{error::Error, fs::{self, File}, io::{BufRead, BufReader}, path::{Path, PathBuf}};
use rfd::FileDialog;

fn find_csv_file(cam_folder_path: &Path) -> Result<PathBuf, Box<dyn Error>> {
    // Extract the trial name and camera number from the folder path
    let trial_name = cam_folder_path
        .parent()
        .and_then(|p| p.file_name())
        .and_then(|n| n.to_str())
        .ok_or("Unable to extract trial name")?;

    let cam_folder_name = cam_folder_path
        .file_name()
        .and_then(|n| n.to_str())
        .ok_or("Unable to extract camera folder name")?;

    let cam_num = Regex::new(r"\d+")
        .unwrap()
        .find(cam_folder_name)
        .ok_or("Unable to extract camera number")?
        .as_str();

    // Construct the regex pattern
    let pattern = format!(r"^{}-{}.*\.csv$", trial_name, cam_num);
    let regex = Regex::new(&pattern)?;

    // Search for matching CSV file
    for entry in fs::read_dir(cam_folder_path)? {
        let entry = entry?;
        let path = entry.path();
        if path.is_file() {
            if let Some(file_name) = path.file_name().and_then(|n| n.to_str()) {
                if regex.is_match(file_name) {
                    return Ok(path);
                }
            }
        }
    }
    Err(From::from("CSV file not found"))
}

/// Reads keypoints from a CSV file and returns them as a vector of vectors of f64.
///
/// # Arguments
///
/// * `file_path` - A string slice that holds the path to the keypoints CSV file.
///
/// # Returns
///
/// A `Result` which is:
/// - `Ok`: Contains a vector of vectors of f64, representing the keypoints.
/// - `Err`: Contains an error if reading or parsing the file fails.
///
/// # Errors
///
/// This function will return an error if the file cannot be read or if parsing fails.
fn read_keypoints(file_path: &str) -> Result<Vec<Vec<f64>>, Box<dyn Error>> {
    let mut rdr = ReaderBuilder::new().has_headers(true).from_path(file_path)?;
    let mut keypoints = Vec::new();

    for result in rdr.records() {
        let record = result?;
        let mut row = Vec::new();
        for field in record.iter().skip(1) {
            row.push(field.parse()?);
        }
        keypoints.push(row);
    }
    
    Ok(keypoints)
}

/// Reads pose data from a CSV file and returns it as a matrix of f64.
///
/// # Arguments
///
/// * `file_path` - A string slice that holds the path to the pose CSV file.
///
/// # Returns
///
/// A `Result` which is:
/// - `Ok`: Contains a DMatrix of f64, representing the pose data.
/// - `Err`: Contains an error if reading or parsing the file fails.
///
/// # Errors
///
/// This function will return an error if the file cannot be read or if parsing fails.
fn read_pose(file_path: &str) -> Result<DMatrix<f64>, Box<dyn Error>> {
    let file = File::open(file_path)?;
    let reader = BufReader::new(file);
    let mut lines = reader.lines();

    // Skip the first three header lines
    for _ in 0..4 {
        lines.next();
    }

    let mut data = Vec::new();

    let mut num_cols: usize = 0;
    for line in lines {
        let line = line?;
        let fields: Vec<&str> = line.split(',').collect();
        num_cols = fields.len();

        for field in fields {
            // Try to parse the field as f64 and push it into the data vector
            match field.parse::<f64>() {
                Ok(value) => data.push(value),
                Err(e) => return Err(Box::new(e)),
            }
        }
    }
    
    // Determine the number of rows
    let num_rows = data.len() / num_cols;

    Ok(DMatrix::from_vec(num_rows, num_cols, data))
}

/// Performs weighted least squares triangulation on pose data from multiple cameras.
///
/// This function reads keypoints and pose data from CSV files in a given trial directory,
/// computes projection matrices for each camera, and estimates 3D points using weighted least squares.
///
/// # Arguments
///
/// * `trial_dir` - A string slice that holds the path to the trial directory.
///
/// # Returns
///
/// A `Result` which is:
/// - `Ok`: If the triangulation completes successfully.
/// - `Err`: Contains an error if any step of the process fails.
///
/// # Errors
///
/// This function will return an error if reading any file or parsing data fails.
fn weighted_least_squares_triangulation(trial_dir: &str) -> Result<(), Box<dyn Error>> {
    let mut projection_mats = Vec::new();
    let mut trajectories = Vec::new();
    let mut likelihoods = Vec::new();
    
    let mut num_frames = 0;
    let mut num_bodyparts = 0;
    
    // Process each camera directory
    for entry in std::fs::read_dir(trial_dir)? {
        let entry = entry?;
        if entry.file_type()?.is_dir() {
            let cam_folder_path = entry.path();
            // let cam_folder_name = cam_folder_path.file_name().unwrap().to_str().unwrap(); TODO: FIGURE OUT IF NEEDED
            let keypoints_path = cam_folder_path.join("keypoints.csv");
            let keypoints = read_keypoints(keypoints_path.to_str().unwrap())?;
            
            let d1 = keypoints[1][3];
            let d2 = keypoints[2][3];
            let d3 = keypoints[3][3];
            
            let p_i = DVector::from_vec(vec![keypoints[1][0], keypoints[1][1]]);
            let p_j = DVector::from_vec(vec![keypoints[2][0], keypoints[2][1]]);
            let p_k = DVector::from_vec(vec![keypoints[3][0], keypoints[3][1]]);
            
            let d_matrix = DMatrix::from_row_slice(6, 6, &[
                d1, 0.0, 0.0, 0.0, 0.0, 0.0,
                0.0, d1, 0.0, 0.0, 0.0, 0.0,
                0.0, 0.0, d2, 0.0, 0.0, 0.0,
                0.0, 0.0, 0.0, d2, 0.0, 0.0,
                0.0, 0.0, 0.0, 0.0, d3, 0.0,
                0.0, 0.0, 0.0, 0.0, 0.0, d3,
            ]);
            
            let p_vec = DVector::from_vec(vec![p_i[0], p_i[1], p_j[0], p_j[1], p_k[0], p_k[1]]);
            let m_vec = d_matrix.try_inverse().unwrap() * p_vec;
            let projection_mat = DMatrix::from_row_slice(2, 3, m_vec.as_slice());
            projection_mats.push(projection_mat);
            
            // Read pose data
            let pose_path = find_csv_file(&cam_folder_path).unwrap();
            let pose = read_pose(pose_path.to_str().unwrap())?;
            num_frames = pose.nrows();
            num_bodyparts = pose.ncols() / 3;
            
            let x_cols: Vec<usize> = (1..pose.ncols()).step_by(3).collect();
            let y_cols: Vec<usize> = (2..pose.ncols()).step_by(3).collect();
            let likelihood_cols: Vec<usize> = (3..pose.ncols()).step_by(3).collect();
            
            let mut traj = vec![vec![[0.0; 2]; num_bodyparts]; num_frames];
            let mut lik = vec![vec![0.0; num_bodyparts]; num_frames];
            
            for frame in 0..num_frames {
                for (bp, &x_col) in x_cols.iter().enumerate() {
                    traj[frame][bp][0] = pose[(frame, x_col)];
                    traj[frame][bp][1] = pose[(frame, y_cols[bp])];
                    lik[frame][bp] = pose[(frame, likelihood_cols[bp])];
                }
            }
            trajectories.push(traj);
            likelihoods.push(lik);
        }
    }
    
    let total_steps = num_bodyparts * num_frames;
    let pb = ProgressBar::new(total_steps as u64);
    pb.set_style(ProgressStyle::default_bar()
        .template("{msg} [{elapsed_precise}] [{wide_bar:.cyan/blue}] {pos}/{len} ({eta})")?);
    
    let mut index_in_chunk = 1;
    let chunk_size = 100;
    let mut points = vec![vec![[0.0; 3]; num_bodyparts]; num_frames];
    
    for bodypart in 0..num_bodyparts {
        // Initialize matrices and vector for weighted least squares computation
        let mut x_mat = DMatrix::<f64>::zeros(0, 0);
        let mut w_mat = DMatrix::<f64>::zeros(0, 0);
        let mut y_vec = DVector::<f64>::zeros(0);
        
        for frame in 0..num_frames {
            for cam in 0..projection_mats.len() {
                // Get the projection matrix for the current camera
                let projection_mat = &projection_mats[cam];

                // Get the x and y coordinates of the current body part in the current frame for the current camera
                let x_point = trajectories[cam][frame][bodypart][0];
                let y_point = trajectories[cam][frame][bodypart][1];

                // Get the likelihood of the current body part in the current frame for the current camera
                let likelihood = likelihoods[cam][frame][bodypart];
                
                // Update x_mat to include the new projection matrix rows
                let new_x_rows = x_mat.nrows() + projection_mat.nrows();
                let new_x_cols = x_mat.ncols() + projection_mat.ncols();
                let mut new_x_mat = DMatrix::<f64>::zeros(new_x_rows, new_x_cols);
                
                // Update x_mat to include the new projection matrix in the diagonal
                new_x_mat.view_mut((0, 0), (x_mat.nrows(), x_mat.ncols())).copy_from(&x_mat);
                new_x_mat.view_mut((x_mat.nrows(), x_mat.ncols()), (projection_mat.nrows(), projection_mat.ncols())).copy_from(&projection_mat); // TODO: check this line in case X is incorrectly constructed
                x_mat = new_x_mat;
                
                // Update w_mat to include the new likelihood weights
                let eye2 = DMatrix::<f64>::identity(2, 2) * likelihood;
                let new_w_rows = w_mat.nrows() + eye2.nrows();
                let new_w_cols = w_mat.ncols() + eye2.ncols();
                let mut new_w_mat = DMatrix::<f64>::zeros(new_w_rows, new_w_cols);

                new_w_mat.view_mut((0, 0), (w_mat.nrows(), w_mat.ncols())).copy_from(&w_mat);
                new_w_mat.view_mut((w_mat.nrows(), w_mat.ncols()), (eye2.nrows(), eye2.ncols())).copy_from(&eye2); // TODO: check this line in case X is incorrectly constructed
                w_mat = new_w_mat;
                
                // Update y_vec to include the new 2D points
                y_vec = DVector::from_fn(y_vec.len() + 2, |i, _| {
                    if i < y_vec.len() {
                        y_vec[i]
                    } else {
                        if i == y_vec.len() { x_point } else { y_point }
                    }
                });
            }
            
            // DEBUG LINALG
            // Currently, the math below incorrectly generates b_chunk as a square matrix. 
            // It is unclear why, for a 100 point => 200 2D coordinate => 300 3D coordinate operation, it should generate a 
            // 600x600 matrix as the result. Once this is resolved, the program should run normally.
            // If the chunk size is reached, solve for the 3D points
            if index_in_chunk == chunk_size {
                let b_chunk = (x_mat.transpose() * &w_mat * &x_mat).try_inverse().unwrap() * x_mat.transpose() * &w_mat * y_vec.clone(); // .try_inverse().unwrap() * x_mat.transpose() * &w_mat * y_vec.clone();
                // Store the 3D coordinates in the points matrix
                for (i, val) in b_chunk.iter().enumerate() {
                    points[frame][bodypart][i] = *val;
                }
                // Reset matrices and vector for the next chunk
                x_mat = DMatrix::<f64>::zeros(0, 0);
                w_mat = DMatrix::<f64>::zeros(0, 0);
                y_vec = DVector::<f64>::zeros(0);
                index_in_chunk = 1;
            }
            
            // Increment the chunk index
            index_in_chunk += 1;

            // Update the progress bar
            pb.inc(1);
        }
        
        // Handle any remaining data for the current body part after the loop
        if x_mat.nrows() > 0 {
            let b_chunk = (x_mat.transpose() * &w_mat * &x_mat).try_inverse().unwrap() * x_mat.transpose() * &w_mat * y_vec.clone();
            let frame_offset = num_frames - (x_mat.nrows() / 2); // Calculate the frame offset for the remaining rows
            for (i, val) in b_chunk.iter().enumerate() {
                points[frame_offset][bodypart][i] = *val;
            }
        }
    }
    
    pb.finish_with_message("Processing complete");
    
    Ok(())
}

fn main() {
    // Hardcode default path used for testing with Sandbox data
    let default_path = "../../../SANDBOX_videos/Natalya_20200723_ARM_001";
    
    // Instantiate FileDialog
    let dialog: FileDialog = FileDialog::new();

    // Use match statement to assign to final path
    let trial_dir: String = match dialog.pick_folder() {
        Some(input_path) => {
            println!("Selected directory: {:?}", input_path);
            input_path.to_string_lossy().into_owned()
        },
        None => {
            println!("No directory selected");
            default_path.to_string()
        },
    };

    // Handle errors propagated from weighted_least_squares_triangulation(*)
    if let Err(e) = weighted_least_squares_triangulation(&trial_dir) {
        eprintln!("Error: {}", e);
    }

}
