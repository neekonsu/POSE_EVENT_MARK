function [trial_names, video_names, trajectory_names] = create_trial_folders(videosFolderPath, blackrockFolderPath)
    
    % Store list of video files in 'videos' path
    aviFiles = dir(fullfile(videosFolderPath, '*.avi'));

    % Store list of ns5 and ns6 Blackrock ECoG files
    ns6Files = dir(fullfile(blackrockFolderPath, '*.ns6'));

    % Store list of extracted trial names used in creation of trial folders.
    trial_names = [];
    % Store list of extracted video names used in creation of trial folders.
    video_names = [];
    % Store list of extracted trajectory names used in creation of trial folders.
    trajectory_names = [];
    % Store list of extracted blackrock naems used in crteation of trial folders.
    blackrock_names = [];

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
        trajectoryFile = fullfile(videosFolderPath, sprintf("%s*.mat",aviName));
        if exist(trajectoryFile, "file")
            copyfile(trajectoryFile, cameraDir, 'f');
            trajectory_names = [trajectory_names, trajectoryFile]; %#ok<AGROW>
        else
            disp("No trajectory file found for video %s", aviName);
        end

        % Copy Blackrock ns5 and ns6 files to trial dir
        ns5File = fullfile(blackrockFolderPath, sprintf("%s.ns5", trialName));
        ns6File = fullfile(blackrockFolderPath, sprintf("%s.ns6", trialName));
        if exist(ns5File, "file") && exist(ns6File, "file")
            copyfile(ns5File, trialDir, 'f');
            copyfile(ns6File, trialDir, 'f');
            blackrock_names = [blackrock_names, sprintf("%s.ns6", trialName)]; %#ok<AGROW>
        else
            disp("One or both Blackrock files (ns5 & ns6) unavailable for trial: %s", trialName);
        end

        % Write first frame to camera dir and move source video
        videoFilePath = fullfile(videosFolderPath, aviFiles(i).name);
        video = VideoReader(videoFilePath);
        frame = readFrame(video);
        frameFileName = sprintf("frame00001.png");
        imwrite(frame, fullfile(cameraDir, frameFileName));
        movefile(videoFilePath, cameraDir);
    end

    if ~isempty(setdiff(ns6Files, blackrock_names))
        disp("The following Blackrock files were not used during the initialization of trial folders:");
        disp(setdiff(ns6Files, blackrock_names));
    end
end 
