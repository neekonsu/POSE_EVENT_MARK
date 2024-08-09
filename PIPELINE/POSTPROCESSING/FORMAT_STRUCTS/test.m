% 
% Add summary helper-function to path
addpath("../../PREPROCESSING/mat_struct_summary/");
addpath("format_evt_struct");
% Prompt user for input mat file to convert
[evt_file, path] = uigetfile("*.mat", "Select Event File");
% Add parent directory to path
addpath(path);
% Load old struct into local variable
old_struct = load(evt_file);
% Update old struct with new formatting
updated_struct = format_evt_struct(old_struct);
% Save Struct Locally
save(evt_file, 'updated_struct');
% Summarize New Struct
% mat_struct_summary();

% % Update old struct with new formatting
% updated_struct = format_trj_struct();
% % Save Struct Locally
% save("testNewStructTrj", 'updated_struct');
% % Summarize New Struct
% mat_struct_summary();