% Test script for keypoint processing

% Get the directory of the current script
scriptDir = fileparts(mfilename('fullpath'));

% Add paths relative to the script location
addpath('/Users/neekon/Documents/NeuroRestore/MATLAB/POSE_EVENT_MARK/OUTPUT/KEYPOINT_TRANSITIONS/keypoint_struct_from_csv');
addpath('/Users/neekon/Documents/NeuroRestore/MATLAB/POSE_EVENT_MARK/OUTPUT/KEYPOINT_TRANSITIONS/split_shifting_keypoints_1D');
addpath('/Users/neekon/Documents/NeuroRestore/MATLAB/POSE_EVENT_MARK/OUTPUT/KEYPOINT_TRANSITIONS/combine_keypoint_transitions');
addpath(fullfile(scriptDir, '..', 'generate_shifting_keypoints_1D'));

% Add the parent directory of the script to the path
addpath(fileparts(scriptDir));

% Generate dummy signal for keypoints
num_keypoints = 3;
dummy_signals = struct();
for i = 1:num_keypoints
    [~, signal] = generate_shifting_keypoints_1D(1000);
    dummy_signals.keypoint{i} = signal;
end

% Modify CSV to use dummy signals for x and y:
[file, path] = uigetfile('*.csv', 'Select the CSV file to modify');
if isequal(file, 0)
    error('User canceled file selection');
end
fullPath = fullfile(path, file);

% Read the CSV file headers
fid = fopen(fullPath, 'r');
header1 = fgetl(fid);
header2 = fgetl(fid);
header3 = fgetl(fid);
fclose(fid);

% Read the CSV file data
opts = detectImportOptions(fullPath);
opts.DataLines = [4, Inf]; % Start reading from the fourth row (after headers)
data = readtable(fullPath, opts);

% Parse the header to get keypoint names
keypoints = strsplit(header2, ',');
keypoint0_index = find(strcmpi(keypoints, 'keypoint0'), 1);
if isempty(keypoint0_index)
    error('Could not find "keypoint0" in the CSV header');
end
keypoints = keypoints(keypoint0_index:end); % Start from 'keypoint0'
keypoints = unique(keypoints); % Remove duplicates
csv_num_keypoints = length(keypoints);

% Check if we have more dummy signals than keypoints in the CSV
if num_keypoints > csv_num_keypoints
    warning('More dummy signals than keypoints in CSV. Filling all available keypoints.');
    num_keypoints = csv_num_keypoints;
elseif num_keypoints < csv_num_keypoints
    warning('Fewer dummy signals than keypoints in CSV. Looping dummy values to fill all keypoints.');
end

% Get the number of rows in the CSV file
csv_rows = height(data);

% Check if we have more rows in the dummy signals than in the CSV
if length(dummy_signals.keypoint{1}) > csv_rows
    error('Dummy signals have more rows than the CSV file. Please adjust the dummy signal length.');
end

% Replace x and y values for each keypoint
for i = 1:csv_num_keypoints
    dummy_index = mod(i-1, num_keypoints) + 1; % Loop dummy signals if necessary
    dummy_signal = dummy_signals.keypoint{dummy_index};
    x_col = keypoint0_index + (i-1)*3;
    y_col = keypoint0_index + (i-1)*3 + 1;
    
    % Fill x and y columns
    data{1:length(dummy_signal), x_col} = dummy_signal';  % Transpose here
    data{1:length(dummy_signal), y_col} = dummy_signal';  % Transpose here
end

% Write modified data back to CSV, preserving headers
fid = fopen(fullPath, 'w');
fprintf(fid, '%s\n', header1);
fprintf(fid, '%s\n', header2);
fprintf(fid, '%s\n', header3);
fclose(fid);

% Write the modified data to the CSV file
writetable(data, fullPath, 'WriteMode', 'append', 'WriteVariableNames', false);

% Now run the keypoint processing script
keypoint_struct_from_csv();

disp('Test completed successfully!');