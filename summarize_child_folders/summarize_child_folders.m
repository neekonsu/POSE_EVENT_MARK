% Prompt user to select a directory
folderPath = uigetdir('', 'Select a directory');
if isequal(folderPath, 0)
    disp('User selected Cancel');
    return;
end

% Get list of all video files in the directory and subdirectories
fileList = dir(fullfile(folderPath, '**', '*.mp4'));
fileList = [fileList; dir(fullfile(folderPath, '**', '*.avi'))];

% Initialize cell array to store filenames and lengths
fileInfo = {'Filename', 'Length (seconds)'};

% Loop through each file and get its duration
for i = 1:length(fileList)
    videoFile = fullfile(fileList(i).folder, fileList(i).name);
    
    % Use VideoReader to get video duration
    video = VideoReader(videoFile);
    duration = video.Duration;
    
    % Append file information to the cell array
    fileInfo = [fileInfo; {videoFile, duration}];
end

% Convert cell array to table
fileInfoTable = cell2table(fileInfo(2:end,:), 'VariableNames', fileInfo(1,:));

% Prompt user to specify output CSV file location
[outputFile, outputPath] = uiputfile('*.csv', 'Save CSV file as');
if isequal(outputFile, 0)
    disp('User selected Cancel');
    return;
end

% Write table to CSV
outputFileName = fullfile(outputPath, outputFile);
writetable(fileInfoTable, outputFileName);

disp(['CSV file created: ', outputFileName]);