% Prompt user for starting frame
startingFrame = input('Enter the starting frame: ');

% Prompt user for ending frame
endingFrame = input('Enter the ending frame: ');

% Prompt user to select a video file
[videoFile, videoPath] = uigetfile({'*.mp4;*.avi', 'Video Files (*.mp4, *.avi)'}, 'Select a Video File');
if isequal(videoFile, 0)
    disp('User selected Cancel');
    return;
end

% Read the video file
videoFullFileName = fullfile(videoPath, videoFile);
videoReader = VideoReader(videoFullFileName);

% Ensure the frame indices are within the valid range
if startingFrame < 1 || endingFrame > videoReader.NumFrames || startingFrame > endingFrame
    error('Invalid frame range specified.');
end

% Create VideoWriter object to write the output video
[~, baseFileName, ~] = fileparts(videoFile);
snippetFileName = sprintf('%s_snippet_%d_%d.mp4', baseFileName, startingFrame, endingFrame);
[outputFile, outputPath] = uiputfile(snippetFileName, 'Save Video File as');
if isequal(outputFile, 0)
    disp('User selected Cancel');
    return;
end
outputFullFileName = fullfile(outputPath, outputFile);
videoWriter = VideoWriter(outputFullFileName, 'MPEG-4');
videoWriter.FrameRate = videoReader.FrameRate;
open(videoWriter);

% Read and write the specified frames
videoReader.CurrentTime = (startingFrame - 1) / videoReader.FrameRate;
for frame = startingFrame:endingFrame
    if hasFrame(videoReader)
        img = readFrame(videoReader);
        writeVideo(videoWriter, img);
    end
end

% Close the VideoWriter object
close(videoWriter);

disp(['Snippet video file created: ', outputFullFileName]);