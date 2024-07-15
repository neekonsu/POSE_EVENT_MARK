% Prompt user for starting frame
startingFrame = input('Enter the starting frame: ');

% Prompt user for ending frame
endingFrame = input('Enter the ending frame: ');

% Prompt user to select a CSV file
[csvFile, csvPath] = uigetfile('*.csv', 'Select a CSV file');
if isequal(csvFile, 0)
    disp('User selected Cancel');
    return;
end

% Read the CSV file
csvFullFileName = fullfile(csvPath, csvFile);
data = readtable(csvFullFileName);

% Ensure the frame indices are within the valid range
if startingFrame < 1 || endingFrame > height(data) || startingFrame > endingFrame
    error('Invalid frame range specified.');
end

% Extract the snippet data based on the starting and ending frame
snippetData = data(startingFrame:endingFrame, :);

% Generate the new file name
[~, baseFileName, ~] = fileparts(csvFile);
snippetFileName = sprintf('%s_snippet_%d_%d.csv', baseFileName, startingFrame, endingFrame);

% Prompt user to specify output CSV file location
[outputFile, outputPath] = uiputfile(snippetFileName, 'Save CSV file as');
if isequal(outputFile, 0)
    disp('User selected Cancel');
    return;
end

% Write the snippet data to the new CSV file
outputFullFileName = fullfile(outputPath, outputFile);
writetable(snippetData, outputFullFileName);

disp(['Snippet CSV file created: ', outputFullFileName]);