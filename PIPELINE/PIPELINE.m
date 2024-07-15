% PIPELINE
% SIMI - Blackrock - DLC - Pipeline for aligning neural data to behavioral events and 3D bodypart trajectories.
% Author: Neekon Saadat [JUIN - SEPT 2024]

addpath("../../../INPUT/create_trial_folders"); % refactor script from wls collection into its own exported function and folder
addpath("../../../INPUT/extract_initial_keypoints"); % refactor script from KEYPOINTS collection into its own exported function and folder
addpath("../../../INPUT/dlc_csv_to_struct/"); % refactor script from dlc_to_simi_mat collection into its own exported function and folder
addpath("../../../OUTPUT/EVENT_MARKING/"); 
addpath("../../../OUTPUT/KEYPOINT_TRANSITIONS/assign_constant_keypoints"); % Create new script to iterate keypoint shift marks from _events.mat files, generate constant keypoint epochs per trial
addpath("../../../OUTPUT/weighted_least_squares"); % refactor wls collection to split up functions, using standalone script here.

%% Step 1: Create Trial Folder Structure
% IN: DeepLabCut 'Videos/' folder
% OUT: PIPELINE trial-based folder structure
% <trialName>/CAM<camNum>/<trialName>.ns5 <~ Symlink
% <trialName>/CAM<camNum>/<trialName>.ns6 <~ Symlink
% <trialName>/CAM<camNum>/<trialName>-<camNum>.avi <~ Symlink to copy in DLC folder
% <trialName>/CAM<camNum>/<trialName>-<camNum>_frame00001.png <~ First frame of video
% <trialName>/CAM<camNum>/<trialName>-<camNum><DLC_MODEL_NAME>.csv <~ 2D DLC Trajectory 
SOURCEDIR = uigetdir(".", "Please Select Directory of DeepLabCut Output (\'Videos/\')");




%% Step 2: Extract Keypoints For Initial Frames
% IN: Trial Folder Structure (frame00001.png)
% OUT: Keypoints struct per trial/camera
% <trialName>/CAM<camNum>/<trialName>-<camNum>_keypoints.mat

%% Step 3: Convert DLC files to .mat Structs
% IN: Trial Folder Structure (DLC .csv Files)
% OUT: DLC .mat files for each camera
% <trialName>/CAM<camNum>/<trialName>-<camNum>_trajectory.mat

%% Step 3a: Mark Events GUI
% IN: Trial Folder Structure (DLC .mat Files and Videos)
% OUT: Event Marks .mat file for trial
% <trialName>/<trialName>_events.mat

%% Step 3b: Assign Constant Keypoints
% IN: Trial Folder Structure (Events .mat File and Videos)
% OUT: Keypoints .mat file for each camera
% <trialName>/CAM<camNum>/<trialName>-<camNum>_keypoints.mat 

%% Step 3c (optional): Plot Bodyparts and Keypoints, Events Over Videos
% IN: Trial Folder Structure (DLC .mat files, Events .mat files, Keypoints .mat files, and Videos)
% OUT: Plotted Points Over All Videos
% <trialName>/CAM<camNum>/<trialName>-<camNum>_overlayed.avi

%% Step 4: Execute WLS For All Trials
% IN: Trial Folder Structure (All Containing Files)
% OUT: 3D Trajectories File Per Trial
% <trialName>/<trialName>_trajectory.mat

%% Step 5: Convert ECoG Data to .mat Files
% IN: Trial Folder Structure (Blackrock .ns5 and .ns6 Files)
% OUT: ECoG Data .mat file
% <trialName>/<trialName>_ecog.mat

%% Step 6: Export Trial Structs
% IN: Trial Folder Structure (All Containing Files)
% OUT: Three Export Files: _TRAJECTORY.mat, _EVENTS.mat, and _ECOG.mat <~ Public Files are ALLCAPS, Private Files are lowercase
% <trialName>/<trialName>_ECOG.mat
% <trialName>/<trialName>_EVENTS.mat
% <trialName>/<trialName>_TRAJECTORY.mat
