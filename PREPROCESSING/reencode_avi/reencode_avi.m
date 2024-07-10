% Prompt the user to select a folder
folder = uigetdir('.', 'Select a Folder Containing .avi Files');

% Check if the user selected a folder
if folder == 0
    disp('No folder selected. Exiting...');
    return;
end

% Get a list of all .avi files in the selected folder
aviFiles = dir(fullfile(folder, '*.avi'));

% Check if there are any .avi files in the folder
if isempty(aviFiles)
    disp('No .avi files found in the selected folder.');
    return;
end

% Full path to ffmpeg executable
ffmpegPath = '/opt/homebrew/bin/ffmpeg';  % Replace with the actual path from `which ffmpeg`

% Iterate over each .avi file and re-encode it
for k = 1:length(aviFiles)
    % Get the full path of the .avi file
    inputFile = fullfile(folder, aviFiles(k).name);
    
    % Get the base filename without the extension
    [~, baseFilename, ~] = fileparts(aviFiles(k).name);
    
    % Set the output filename with .mp4 extension
    outputFile = fullfile(folder, [baseFilename, '_reencoded.mp4']);
    
    % Re-encode the video using ffmpeg
    command = sprintf('"%s" -i "%s" -c:v libx264 -crf 23 -preset medium -c:a aac -b:a 192k "%s"', ...
                      ffmpegPath, inputFile, outputFile);
    status = system(command);
    
    % Check if re-encoding was successful
    if status == 0
        fprintf('Successfully re-encoded %s to %s\n', inputFile, outputFile);
    else
        fprintf('Failed to re-encode %s\n', inputFile);
    end
end

disp('Re-encoding completed.');