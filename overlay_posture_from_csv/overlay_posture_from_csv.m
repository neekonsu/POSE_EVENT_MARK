% Set the default renderer
set(0, 'DefaultFigureRenderer', 'painters');

% Define the color palette
palette.color.ir = [249,82,91]/255;
palette.color.ird = [134,46,56]/255;
palette.color.bd = [25,211,197]/255;
palette.color.bl = [138,210,211]/255;
palette.color.yd = [252,176,33]/255;
palette.color.yl = [254,197,87]/255;
palette.color.vy = [240,223,0]/255;
palette.color.db = [49,51,53]/255;
palette.color.cg11 = [84,86,91]/255;
palette.color.cg9 = [117,118,121]/255;
palette.color.cg7 = [150,152,153]/255;
palette.color.cg4 = [187,186,186]/255;
palette.color.cg1 = [219,219,221]/255;

% Set the default color palette
palette.default_color = [palette.color.ir;
    palette.color.bd;
    palette.color.yd;
    palette.color.db;
    palette.color.bl;
    palette.color.yl];

% Select the CSV file using a file dialog
[csvFilename, csvPathname] = uigetfile("*.csv", "Select a CSV file to parse");

% Check if the user selected a file or canceled the dialog
if isequal(csvFilename, 0) || isequal(csvPathname, 0)
    disp('User canceled the CSV file selection');
    return;
end

% Read the entire CSV file without skipping any rows
fileID = fopen(fullfile(csvPathname, csvFilename));
rawData = textscan(fileID, '%s', 'Delimiter', '\n');
fclose(fileID);
rawData = rawData{1};

% Extract the body part names from the second row
bodyParts = strsplit(rawData{2}, ',');
bodyParts = matlab.lang.makeValidName(bodyParts);

% Read the data starting from the fourth line
dataStartLine = 4;
dataLines = rawData(dataStartLine:end);

% Prompt the user to select a body part from a dropdown menu
[selectionIndex, ok] = listdlg('PromptString', 'Select a body part:', ...
                               'SelectionMode', 'single', ...
                               'ListString', bodyParts(2:3:end));

if ~ok
    disp('User canceled the body part selection');
    return;
end

selectedBodyPart = bodyParts{(selectionIndex - 1) * 3 + 2};

% Initialize arrays for coordinates and likelihood
numLines = length(dataLines);
xCoords = zeros(numLines, 1);
yCoords = zeros(numLines, 1);
likelihood = zeros(numLines, 1);

% Loop through each data line to extract x, y coordinates and likelihood
for i = 1:numLines
    lineData = strsplit(dataLines{i}, ',');
    xCoords(i) = str2double(lineData{(selectionIndex - 1) * 3 + 2});
    yCoords(i) = str2double(lineData{(selectionIndex - 1) * 3 + 3});
    likelihood(i) = str2double(lineData{(selectionIndex - 1) * 3 + 4});
end

% Normalize likelihood to [0, 1] for color mapping
normalizedLikelihood = (likelihood - min(likelihood)) / (max(likelihood) - min(likelihood));

% Generate colors from red to grey
startColor = palette.color.ir;
endColor = palette.color.cg1;
colors = (1 - normalizedLikelihood) * startColor + normalizedLikelihood * endColor;

% Select the video file using a file dialog
[videoFilename, videoPathname] = uigetfile("*.avi;*.mp4", "Select a video file");

% Check if the user selected a file or canceled the dialog
if isequal(videoFilename, 0) || isequal(videoPathname, 0)
    disp('User canceled the video file selection');
    return;
end

% Read the video
videoReader = VideoReader(fullfile(videoPathname, videoFilename));

% Prompt the user to select the destination folder
destinationPath = uigetdir('', 'Select the destination folder');

% Check if the user selected a folder or canceled the dialog
if isequal(destinationPath, 0)
    disp('User canceled the folder selection');
    return;
end

% Generate the output video filename
[~, name, ~] = fileparts(videoFilename);
outputVideoFilename = fullfile(destinationPath, [name, '_overlayed_', selectedBodyPart, '.avi']);
videoWriter = VideoWriter(outputVideoFilename);
open(videoWriter);

% Create a figure for plotting
hFig = figure('Visible', 'off');

% Loop through each frame of the video
for k = 1:videoReader.NumFrames
    frame = read(videoReader, k);
    imshow(frame, 'Border', 'tight');
    hold on;
    
    % Plot the body part with the color corresponding to its likelihood
    if k <= numLines
        plot(xCoords(k), yCoords(k), 'o', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', colors(k, :), 'MarkerSize', 12, 'LineWidth', 2);
    end
    
    % Get the frame with the overlay
    overlayFrame = getframe(hFig);
    writeVideo(videoWriter, overlayFrame);
    hold off;
end

% Close the video writer
close(videoWriter);
close(hFig);

disp(['Overlay video saved to: ', outputVideoFilename]);
