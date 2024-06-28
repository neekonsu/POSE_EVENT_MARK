% OVERVIEW: The following program takes a folder populated with .avi videos
% of behavioral experiments, csv files corresponding to DLC markerless
% pose estimates of each video, and h5/pickle files containing the same
% information. The goal of this program is to utilize multiple camera
% angles available for each experiment to estimate a consolidated 3D
% trajectory of bodyparts. The purpose of these trajectories is for use in
% marking behavioral events for subsequent analysis of corresponding LFP
% signals.
% DESIGN OBJECTIVES: This program shall be compatible with the default
% folder-structure of DLC video-analysis output. This program shall create
% a new folder corresponding to each experiment, and shall create one
% subfolder corresponding to each camera angle present in that experiment.
% This program shall provide a GUI for marking fixed points and known 
% distances in the first frame of each video to enable point triangulation.
% This program shall use an optimization technique such as least squares
% regression to decide the optimal 3D position of each bodypart in each
% frame. This program shall weigh point regression by accounting for the
% associated confidence score of those points. This program shall exclude
% point coordinates any camera angle which assigns a confidence below a set
% threshold in order to exclude angles wherein the bodypart is obfuscated
% or invisible from the result of regression. This program shall output a
% consolidated csv file containing the 3D coordinate, 2D coordinate, and
% confidence values for each body part, as well as an indication of any 2D
% coordinates excluded by thresholding and an indication of any 2D point
% unavailable/invisible for a given frame, camera angle, and body part.

% Folder structure (after DLC analyze-videos)
% <DLC_PROJECT>/
% |-videos/
%   |-<VIDEO_NAME>_resnet50_<DLC_PROJECT>_Jun11shuffle1_<MAX_ITERATIONS>_meta.pickle
%   |-<VIDEO_NAME>_resnet50_<DLC_PROJECT>_Jun11shuffle1_<MAX_ITERATIONS>.h5
%   |-<VIDEO_NAME>_resnet50_<DLC_PROJECT>_Jun11shuffle1_<MAX_ITERATIONS>.csv
%   ...
%   |-<VIDEO_NAME>.avi
%   ...
% |-training-datasets/
% |-lebeled-data/
% |-evaluation-result/
% |-dlc-models/

% Folder structure (after create_trial_folders(*))
% <DLC_PROJECT>/
% |-videos/
%   |-<VIDEO_NAME>_resnet50_<DLC_PROJECT>_Jun11shuffle1_<MAX_ITERATIONS>_meta.pickle
%   |-<VIDEO_NAME>_resnet50_<DLC_PROJECT>_Jun11shuffle1_<MAX_ITERATIONS>.h5
%   |-<VIDEO_NAME>_resnet50_<DLC_PROJECT>_Jun11shuffle1_<MAX_ITERATIONS>.csv
%   ...
%   |-<VIDEO_NAME>.avi
%   ...
%   |-<TRIAL_NAME>/
%       |-<TRIAL_NAME>_3D_TRAJECTORY.mat
%       |-<TRIAL_NAME>_3D_TRAJECTORY.csv
%       |-<TRIAL_NAME>_3D_TRAJECTORY.gif
%       |-CAM1/
%           |-frame0001.png
%           ...
%           |-frame000<N>.png
%           |-keypoints.csv
%           |-<VIDEO_NAME>_resnet50_<DLC_PROJECT>_Jun11shuffle1_<MAX_ITERATIONS>.csv
%       |-CAM2/
%           |-frame0001.png
%           ...
%           |-frame000<N>.png
%           |-keypoints.csv
%           |-<VIDEO_NAME>_resnet50_<DLC_PROJECT>_Jun11shuffle1_<MAX_ITERATIONS>.csv
%       ...
%       |-CAM<N>/
%           |-frame0001.png
%           ...
%           |-frame000<N>.png
%           |-keypoints.csv
%           |-<VIDEO_NAME>_resnet50_<DLC_PROJECT>_Jun11shuffle1_<MAX_ITERATIONS>.csv
% |-training-datasets/
% |-lebeled-data/
% |-evaluation-result/
% |-dlc-models/

% Step 1: Select videos folder containing all .avi and .csv corresponding
% to trials, found in DLC project folder
videosFolderPath = prompt_video_folder();
% Step 2: Create folder structure for analyzing 3D trajectories on
% per-trial basis
create_trial_folders(videosFolderPath);

% Step 3: Select single trial for extracting 3D trajectories and label
% keypoints
trialDir = uigetdir("*", "Select trial directory to process");
label_keypoints(trialDir);

% Step 4: Load pose data, triangulate, optimize, and generate 3D trajectories
points = weighted_least_squares_triangulation(trialDir);
save("trialDir", "points");

% Step 5: Generate GIF animation of 3D trajectories
generate_gif(uigetfile("*.mat", "Select .mat file containing 3D trajectory"));
