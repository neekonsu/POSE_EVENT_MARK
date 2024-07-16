function [trial_names, video_names, trajectory_names] = create_trial_folders(videosFolderPath)
    
    % Store list of video files in 'videos' path
    aviFiles = dir(fullfile(videosFolderPath, '*.avi'));

    % Store list of extracted trial names used in creation of trial folders.
    trial_names = [];

    % Store list of extracted names from videos used in creation of trial folders.
    video_names = [];

    % Iterate avi and csv files to produce desired folder structure
    for i = 1:length(aviFiles)
        % Extract Regex parts from filename
        [~, aviName, ~] = fileparts(aviFiles(i).name);
        aviNameSegments = regexp(aviName, "[_-]", "split");
        video_names = [video_names, aviName]; %#ok<AGROW>
        
        % Separate trial and camera angle from filename
        trialName = strjoin(aviNameSegments(1:end-1), '_');
        trial_names = [trial_names, trialName]; %#ok<AGROW>
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
        else
            disp("Camera directory already exists for %s, skipping.", cameraDir);
        end

        % Copy trajectory CSV to camera dir
        trajectoryFile = fullfile(videosFolderPath, sprintf("%s*.csv",aviName));
        if exist(trajectoryFile, "file")
            copyfile(trajectoryFile, cameraDir, 'f');
            trajectory_names = [trajectory_names, trajectoryFile]; %#ok<AGROW>
        else
            disp("No trajectory file found for video %s", aviName);
        end

        % Write first frame to camera dir
        videoFilePath = fullfile(videosFolderPath, aviFiles(i).name);
        video = VideoReader(videoFilePath);
        frame = readFrame(video);
        frameFileName = sprintf("frame0001.png");
        imwrite(frame, fullfile(cameraDir, frameFileName));
    end
end 
