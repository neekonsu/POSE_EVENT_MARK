% OVERVIEW: The following program takes a folder populated with .avi videos
% of behavioral experiments, csv files corresponding to DLC markerless
% pose estimates of each video, and h5/pickle files containing the same
% information. The goal of this program is to utilize multiple camera
% angles available for each experiment to estimate a consolidated 3D
% trajectory of bodyparts. The purpose of these trajectories is for use in
% marking behavioral events for subsequent analysis of corresponding LFP
% signals.
% DESIGN OBJECTIVES: This program shall be compatible with the default
% folder-structure of DLC video-analysis output. This program shall create
% a new folder corresponding to each experiment, and shall create one
% subfolder corresponding to each camera angle present in that experiment.
% This program shall provide a GUI for marking fixed points and known 
% distances in the first frame of each video to enable point triangulation.
% This program shall use an optimization technique such as least squares
% regression to decide the optimal 3D position of each bodypart in each
% frame. This program shall weigh point regression by accounting for the
% associated confidence score of those points. This program shall exclude
% point coordinates any camera angle which assigns a confidence below a set
% threshold in order to exclude angles wherein the bodypart is obfuscated
% or invisible from the result of regression. This program shall output a
% consolidated csv file containing the 3D coordinate, 2D coordinate, and
% confidence values for each body part, as well as an indication of any 2D
% coordinates excluded by thresholding and an indication of any 2D point
% unavailable/invisible for a given frame, camera angle, and body part.

% Folder structure (after DLC analyze-videos)
% <DLC_PROJECT>/
% |-videos/
%   |-<VIDEO_NAME>_resnet50_<DLC_PROJECT>_Jun11shuffle1_<MAX_ITERATIONS>_meta.pickle
%   |-<VIDEO_NAME>_resnet50_<DLC_PROJECT>_Jun11shuffle1_<MAX_ITERATIONS>.h5
%   |-<VIDEO_NAME>_resnet50_<DLC_PROJECT>_Jun11shuffle1_<MAX_ITERATIONS>.csv
%   ...
%   |-<VIDEO_NAME>.avi
%   ...
% |-training-datasets/
% |-lebeled-data/
% |-evaluation-result/
% |-dlc-models/

function videosFolderPath = prompt_video_folder()
    disp('[I] Prompt user to select videos path');
    % Prompt the user to select a folder
    videosFolderPath = uigetdir("*", "Select videos folder inside DLC Project");
    
    % Check if the user selected a folder or cancelled the operation
    if videosFolderPath == 0
        disp('User cancelled the folder selection.');
    else
        disp(['Selected folder: ', videosFolderPath]);
    end
end

function create_trial_folders(videosFolderPath)
    
    % Store list of video files in 'videos' path
    aviFiles = dir(fullfile(videosFolderPath, '*.avi'));

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
        frameFileName = sprintf("frame%04d.png", frameIndex);
        imwrite(frame, fullfile(cameraDir, frameFileName));
    end
end 

function label_keypoints(trialDir)
    % LABEL_KEYPOINTS   Function to label keypoints on frames in a given trial directory
    % trialDir: Directory containing folders for each camera angle during a
    % single trial. Typically 8 Camera Angles

    folderPath = trialDir; % Set the folder path to the trial directory
    camFolders = dir(fullfile(folderPath, '*')); % List all items in the directory
    % Filter out non-directory items and the '.' and '..' entries
    camFolders = camFolders([camFolders.isdir] & ~ismember({camFolders.name}, {'.', '..'}));

    % Define the keypoints to be labeled
    keypoints = {'origin', 'keypoint1', 'keypoint2', 'keypoint3'};
    numCams = length(camFolders); % Number of camera folders

    for i = 1:numCams
        % Read the first frame of the current camera
        frame = imread(fullfile(folderPath, camFolders(i).name, 'frame0001.png'));
        
        % Get image size
        [imgHeight, imgWidth, ~] = size(frame);
        
        % Define margin
        margin = 30;
        
        % Get screen size
        screenSize = get(0, 'ScreenSize');
        screenWidth = screenSize(3);
        screenHeight = screenSize(4);
        
        % Calculate figure position to center it on the screen
        figWidth = imgWidth + 2 * margin;
        figHeight = imgHeight + 2 * margin;
        figX = (screenWidth - figWidth) / 2;
        figY = (screenHeight - figHeight) / 2;
        
        % Create a figure window with specified size and margin, centered on screen
        hFig = figure('Name', camFolders(i).name, ...
                      'Position', [figX, figY, figWidth, figHeight]);
        
        % Create an axes that provides the desired margins
        ax = axes('Position', [margin / figWidth, margin / figHeight, ...
                               imgWidth / figWidth, imgHeight / figHeight]);
        
        imshow(frame, 'Parent', ax); % Display the frame in the specified axes
        hold on; % Hold the current image for plotting

        coordinates = -ones(length(keypoints), 2); % Initialize coordinates to -1 (for skipped points)
        distances_m = zeros(length(keypoints) - 1, 1); % Initialize distances array (m)
        distances_px = zeros(length(keypoints) - 1, 1); % Initialize distances array (px)
        angles_rad = zeros(length(keypoints) - 1, 1); % Initialize angles array (rad)

        % Prompt the user to select the origin
        title('Select the origin');
        [x_origin, y_origin] = ginput(1); % Get the (x, y) coordinates of the origin
        if ~isempty(x_origin)
            plot(x_origin, y_origin, 'ro'); % Plot the selected origin on the image
            coordinates(1, :) = [x_origin, y_origin]; % Store the origin coordinates
        else
            errMsg = 'Origin must be selected to continue';
            disp(errMsg);
            errordlg(errMsg, 'Error');
            close(hFig); % Close the figure
            return;
        end

        for k = 2:length(keypoints)
            % Prompt the user to select the keypoint
            title(sprintf('Select %s or press Enter to skip', keypoints{k}));
            [x, y] = ginput(1); % Get the (x, y) coordinates of the selected point
            if ~isempty(x)
                plot(x, y, 'ro'); % Plot the selected point on the image
                coordinates(k, :) = [x, y]; % Store the coordinates

                % Calculate the distance in pixels
                distances_px(k - 1) = sqrt((x - x_origin)^2 + (y - y_origin)^2);
                
                % Calculate the angle in radians
                angles_rad(k - 1) = atan2(y - y_origin, x - x_origin);
                
                % Prompt the user to enter the distance to the origin in meters
                distance_m = inputdlg(sprintf('Enter the distance between origin and %s (in meters):', keypoints{k}));
                if ~isempty(distance_m)
                    distances_m(k - 1) = str2double(distance_m{1}); % Store the distance in meters
                else
                    errMsg = 'Distance must be entered to continue';
                    disp(errMsg);
                    errordlg(errMsg, 'Error');
                    close(hFig); % Close the figure
                    return;
                end
            end
        end

        % Combine coordinates, distances, and angles into one array
        data = cell(length(keypoints) + 1, 6);
        data(1, :) = {'Point', 'X (px)', 'Y (px)', 'Distance (px)', 'Distance (m)', 'Angle (rad)'};
        data(2:end, 1) = keypoints';
        data(2:end, 2:3) = num2cell(coordinates);
        data(2:end, 4) = num2cell([0; distances_px]); % Distance in pixels
        data(2:end, 5) = num2cell([0; distances_m]); % Distance in meters
        data(2:end, 6) = num2cell([0; angles_rad]); % Angle in radians

        % Save data to a CSV file
        csvPath = fullfile(folderPath, camFolders(i).name, 'keypoints.csv');
        fid = fopen(csvPath, 'w');
        [rows, cols] = size(data);
        for r = 1:rows
            for c = 1:cols
                var = data{r, c};
                if isnumeric(var)
                    var = num2str(var);
                end
                fprintf(fid, '%s', var);
                if c < cols
                    fprintf(fid, ',');
                end
            end
            fprintf(fid, '\n');
        end
        fclose(fid);

        close(hFig); % Close the figure
    end
end

function points = weighted_least_squares_triangulation(trialDir)
    % Get list of camera folders
    camFolders = dir(fullfile(trialDir, '*'));
    camFolders = camFolders([camFolders.isdir] & ~ismember({camFolders.name}, {'.', '..'}));
    
    % Number of camera folders
    numCams = length(camFolders);
    
    % Initialize storage for basis vectors, projections, trajectories, and likelihoods
    basis_vectors_all = cell(numCams, 1);
    projections_all = cell(numCams, 1);
    trajectories_all = cell(numCams, 1);
    likelihoods_all = cell(numCams, 1);
    
    % Preallocate trajectory and likelihood matrices assuming uniformity across cameras
    % This will be determined during the first iteration
    firstCameraProcessed = false;

    % Iterate over each camera directory
    for i = 1:numCams
        % Define the path for the current camera folder
        camFolder = fullfile(trialDir, camFolders(i).name);
        
        % Load the keypoints.csv file
        keypoints = readcell(fullfile(camFolder, 'keypoints.csv'));
        
        % Extract the camera number from the camera folder name
        camNum = regexp(camFolders(i).name, '\d+', 'match', 'once');
        
        % Construct the expected pose CSV filename pattern
        csvPattern = sprintf('%s-%s*.csv', trialDir, camNum);
        
        % Find the corresponding pose CSV file
        csvFile = dir(fullfile(camFolder, csvPattern));
        
        if isempty(csvFile)
            warning('CSV file not found for camera %s', camFolders(i).name);
            continue;
        end

        % Load the pose CSV file
        pose = readmatrix(fullfile(camFolder, csvFile(1).name));
        
        % Extract the distances (column 5) for each key point
        d1 = keypoints{2, 5};
        d2 = keypoints{3, 5};
        d3 = keypoints{4, 5};
        
        % Define the basis vectors using the distances
        i_vector = [d1; 0; 0];
        j_vector = [0; d2; 0];
        k_vector = [0; 0; d3];
        
        % Define the projections from keypoints
        P_i = [keypoints{2, 2}; keypoints{2, 3}];
        P_j = [keypoints{3, 2}; keypoints{3, 3}];
        P_k = [keypoints{4, 2}; keypoints{4, 3}];
        
        % Stack the projections into a single column vector
        projections = [P_i; P_j; P_k];
        
        % Stack the basis vectors into a matrix
        basis_vectors = [i_vector, j_vector, k_vector];
        
        % Extract the x, y, and likelihood columns from the pose file
        % Assume the pose file has the following columns: scorer, bodyparts, coords (x, y, likelihood)
        x_cols = 2:3:size(pose, 2);
        y_cols = 3:3:size(pose, 2);
        likelihood_cols = 4:3:size(pose, 2);
        
        if ~firstCameraProcessed
            num_frames = size(pose, 1);
            num_points = length(x_cols);
            firstCameraProcessed = true;
            
            for k = 1:numCams
                trajectories_all{k} = zeros(num_frames, num_points, 2);
                likelihoods_all{k} = zeros(num_frames, num_points);
            end
        end
        
        % Fill the trajectories and likelihoods matrices
        trajectories_all{i}(:, :, 1) = pose(:, x_cols);
        trajectories_all{i}(:, :, 2) = pose(:, y_cols);
        likelihoods_all{i} = pose(:, likelihood_cols);
        
        % Store the basis vectors and projections for this camera
        basis_vectors_all{i} = basis_vectors;
        projections_all{i} = projections;
    end

    % Initialize the points matrix
    points = zeros(num_frames, num_points, 3);

    % Iterate over each frame and each point
    for frame = 1:num_frames
        for point = 1:num_points
            % Initialize matrices X, W, and vector y
            X = [];
            W = [];
            y = [];
            
            % Construct X, W, and y for all cameras
            for i = 1:numCams
                basis_vectors = basis_vectors_all{i};
                likelihoods = likelihoods_all{i};
                x = trajectories_all{i}(frame, point, 1);
                y_point = trajectories_all{i}(frame, point, 2);
                likelihood = likelihoods(frame, point);
                
                % Add basis vectors to X
                X = [X; basis_vectors];
                
                % Add likelihoods to W
                W = blkdiag(W, likelihood * eye(2));
                
                % Add observations to y
                y = [y; x; y_point];
            end
            
            % Solve for the 3D point using weighted least squares
            b = (X' * W * X) \ (X' * W * y);
            
            % Store the 3D coordinates
            points(frame, point, :) = b;
        end
    end
    
    % Display the results
    disp('3D Points:');
    disp(points);
end

function generate_gif(trialDir)
    % Construct the path to the optimized trajectory CSV file
    optimizedTrajectoryFile = fullfile(trialDir, sprintf('%s_optimized_trajectory.csv', trialDir));

    % Read the CSV file
    data = readtable(optimizedTrajectoryFile);

    % Extract the unique body parts
    bodyParts = unique(data.bodypart);

    % Initialize a 3D array to store the body parts data
    numFrames = max(data.frame);
    numBodyParts = length(bodyParts);
    bodyParts3D = zeros(numFrames, numBodyParts, 3);

    % Populate the 3D array with data from the CSV file
    for i = 1:height(data)
        frameIndex = data.frame(i);
        bodyPartIndex = strcmp(bodyParts, data.bodypart{i});
        bodyParts3D(frameIndex, bodyPartIndex, :) = [data.x(i), data.y(i), data.z(i)];
    end

    % Generate the GIF
    filename = fullfile(trialDir, '3D_trajectory.gif');
    for frameIndex = 1:numFrames
        scatter3(bodyParts3D(frameIndex, :, 1), bodyParts3D(frameIndex, :, 2), bodyParts3D(frameIndex, :, 3), 'filled');
        axis equal;
        drawnow;
        frame = getframe(gcf);
        im = frame2im(frame);
        [imind, cm] = rgb2ind(im, 256);
        if frameIndex == 1
            imwrite(imind, cm, filename, 'gif', 'Loopcount', inf, 'DelayTime', 0.1);
        else
            imwrite(imind, cm, filename, 'gif', 'WriteMode', 'append', 'DelayTime', 0.1);
        end
    end
end

% Step 1: Select videos folder containing all .avi and .csv corresponding
% to trials, found in DLC project folder
videosFolderPath = prompt_video_folder();
% Step 2: Create folder structure for analyzing 3D trajectories on
% per-trial basis
create_trial_folders(videosFolderPath);

% Step 3: Select single trial for extracting 3D trajectories and label
% keypoints
trialDir = uigetdir("*", "Select trial directory to process");
label_keypoints(trialDir);

% Step 4: Load pose data, triangulate, optimize, and generate 3D trajectories
points = weighted_least_squares_triangulation(trialDir);
save("trialDir", "points");

% Step 5: Generate GIF animation of 3D trajectories
generate_gif(uigetfile("*.mat", "Select .mat file containing 3D trajectory"));
