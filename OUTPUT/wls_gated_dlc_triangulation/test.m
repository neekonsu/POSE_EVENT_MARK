% videoFoldersPath = prompt_video_folder();
% 
% create_trial_folders(videoFoldersPath);
% 
trialDir = uigetdir;
% 
% label_keypoints(trialDir);

weighted_least_squares_triangulation(trialDir);