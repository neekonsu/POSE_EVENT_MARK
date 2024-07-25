function [trial_names, video_names, trajectory_names] = create_trial_folders(videosFolderPath)
    % Store list of video files in 'videos' path
    aviFiles = dir(fullfile(videosFolderPath, '*.mp4'));
    % Store list of extracted trial names used in creation of trial folders.
    trial_names = {};
    % Store list of extracted video names used in creation of trial folders.
    video_names = {};
    % Store list of extracted trajectory names used in creation of trial folders.
    trajectory_names = {};
    % Store list of extracted blackrock names used in creation of trial folders.
    blackrock_names = {};

    % Iterate avi and csv files to produce desired folder structure
    for i = 1:length(aviFiles)
        % Extract Regex parts from filename
        [~, aviName, ~] = fileparts(aviFiles(i).name);
        aviName = regexprep(aviName, '_reencoded$', '');
        aviNameSegments = regexp(aviName, '[_-]', 'split');
        video_names{end+1} = aviName; %#ok<AGROW>

        % Separate trial and camera angle from filename
        trialName = strjoin(aviNameSegments(1:end-1), '_');
        trial_names{end+1} = trialName; %#ok<AGROW>
        cameraAngle = aviNameSegments{end};

        % Create trial dir
        trialDir = fullfile(videosFolderPath, trialName);
        if ~exist(trialDir, 'dir')
            mkdir(trialDir);
        end

        % Create camera dir
        cameraDir = fullfile(trialDir, sprintf('CAM%c', cameraAngle));
        if ~exist(cameraDir, 'dir')
            mkdir(cameraDir);
        else
            fprintf('Camera directory already exists for %s, skipping.\n', cameraDir);
        end

        % Copy trajectory mat to camera dir
        trajectoryFiles = dir(fullfile(videosFolderPath, [aviName, '*_reencoded.mat']));
        if ~isempty(trajectoryFiles)
            copyfile(fullfile(trajectoryFiles(1).folder, trajectoryFiles(1).name), cameraDir, 'f');
            trajectory_names{end+1} = trajectoryFiles(1).name; %#ok<AGROW>
        else
            fprintf('No trajectory file found for video %s\n', aviName);
        end

        % Copy Blackrock ns5 and ns6 files to trial dir
        ns5File = dir(fullfile(videosFolderPath, [trialName, '*.ns5']));
        ns6File = dir(fullfile(videosFolderPath, [trialName, '*.ns6']));
        if exist(ns5File, 'file') && exist(ns6File, 'file')
            copyfile(ns5File, trialDir, 'f');
            copyfile(ns6File, trialDir, 'f');
            blackrock_names{end+1} = [trialName, '.ns6']; %#ok<AGROW>
        else
            fprintf('One or both Blackrock files (ns5 & ns6) unavailable for trial: %s\n', trialName);
        end

        % Write first frame to camera dir and move source video
        videoFilePath = fullfile(videosFolderPath, aviFiles(i).name);
        video = VideoReader(videoFilePath);
        frame = readFrame(video);
        frameFileName = 'frame00001.png';
        imwrite(frame, fullfile(cameraDir, frameFileName));
        movefile(videoFilePath, cameraDir);
    end
end