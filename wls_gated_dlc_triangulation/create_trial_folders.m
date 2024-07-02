function create_trial_folders(videosFolderPath)
    
    % Store list of video files in 'videos' path
    aviFiles = dir(fullfile(videosFolderPath, '*.mp4'));

    % Iterate avi and csv files to produce desired folder structure
    for i = 1:length(aviFiles)
        % Extract Regex parts from filename
        [~, aviName, ~] = fileparts(aviFiles(i).name);
        aviNameSegments = regexp(aviName, "[_-]", "split");
        
        % Separate trial and camera angle from filename
        trialName = strjoin(aviNameSegments(1:4), '_');
        cameraAngle = aviNameSegments{end};

        % Create trial dir
        trialDir = fullfile(videosFolderPath, trialName);
        if ~exist(trialDir, "dir")
            mkdir(trialDir);
        end

        % Create camera dir
        cameraDir = fullfile(trialDir, sprintf("CAM%c",cameraAngle));
        if ~exist(cameraDir, "dir")
            mkdir(cameraDir);
        end

        % Copy trajectory CSV to camera dir
        trajectoryFile = fullfile(videosFolderPath, sprintf("%s*.csv",aviName));
        if exist(trajectoryFile, "file")
            copyfile(trajectoryFile, cameraDir, 'f');
        end

        % Write first frame to camera dir
        videoFilePath = fullfile(videosFolderPath, aviFiles(i).name);
        video = VideoReader(videoFilePath);
        frame = readFrame(video);
        frameFileName = sprintf("frame0001.png");
        imwrite(frame, fullfile(cameraDir, frameFileName));
    end
end 
