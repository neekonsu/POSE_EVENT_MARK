function points = weighted_least_squares_triangulation(trialDir)
    % Store the trialName
    [~, trialName, ~] = fileparts(trialDir);

    % Get list of camera folders
    camFolders = dir(fullfile(trialDir, '*'));
    camFolders = camFolders([camFolders.isdir] & ~ismember({camFolders.name}, {'.', '..'}));
    
    % Number of camera folders
    numCams = length(camFolders);
    
    % Initialize storage for basis vectors, projections, trajectories, and likelihoods
    projection_mat_all = cell(numCams, 1);
    trajectories_all = cell(numCams, 1);
    likelihoods_all = cell(numCams, 1);

    num_frames = 0;
    
    % Iterate over each camera directory
    for cam = 1:numCams
        % Store Camera Folder
        camFolder = camFolders(cam);

        % Define the path for the current camera folder and ls
        camFolderPath = fullfile(trialDir, camFolder.name);
        camFiles  = {dir(camFolderPath).name};

        % Extract the camera number from the camera folder name
        camNum = regexp(camFolder.name, '\d+', 'match', 'once');

        % Construct the expected pose CSV filename pattern
        poseFilePattern = sprintf('^%s-%s.*\\.csv$', trialName, camNum);

        % Filter files in camera folder by regexp
        csvFile   = camFiles(~cellfun('isempty', regexp(camFiles, poseFilePattern)));
        
        % Load the keypoints.csv file
        keypoints = readcell(fullfile(camFolderPath, 'keypoints.csv'));

        % Check if the corresponding pose CSV file was found
        if isempty(csvFile)
            error('No corresponding pose CSV file found for %s', camFolders(cam).name);
        end

        % Load the pose CSV file
        pose = readmatrix(fullfile(camFolderPath, csvFile{1}));
        
        % Extract the distances (column 5) for each key point
        d1 = keypoints{3, 5};
        d2 = keypoints{4, 5};
        d3 = keypoints{5, 5};
        
        % Define the projections from keypoints
        P_i = [keypoints{3, 2}; keypoints{3, 3}];
        P_j = [keypoints{4, 2}; keypoints{4, 3}];
        P_k = [keypoints{5, 2}; keypoints{5, 3}];
        
        % Construct the system of equations to solve for the projection matrix elements
        D = [
            d1, 0, 0, 0, 0, 0;
            0, d1, 0, 0, 0, 0;
            0, 0, d2, 0, 0, 0;
            0, 0, 0, d2, 0, 0;
            0, 0, 0, 0, d3, 0;
            0, 0, 0, 0, 0, d3;
        ];
    
        p_vec = [P_i; P_j; P_k];
    
        % Solve for the projection matrix elements
        m_vec = D \ p_vec;
    
        % Reshape the result into the 2x3 projection matrix
        projection_mat = reshape(m_vec, [2, 3]);
    
        % Store projection matrix M for current camera into global struct
        projection_mat_all{cam} = projection_mat;
        
        % Extract the x, y, and likelihood columns from the pose file
        x_cols = 2:3:size(pose, 2);
        y_cols = 3:3:size(pose, 2);
        likelihood_cols = 4:3:size(pose, 2);
        
        % Store number of frames & bodyparts for current camera's pose data
        num_frames = size(pose, 1);
        num_bodyparts = length(x_cols);

        % Create matrix points and likelihoods for current camera
        trajectories_all{cam} = zeros(num_frames, num_bodyparts, 2);
        likelihoods_all{cam} = zeros(num_frames, num_bodyparts);

        % Fill the trajectories and likelihoods matrices
        trajectories_all{cam}(:, :, 1) = pose(:, x_cols);
        trajectories_all{cam}(:, :, 2) = pose(:, y_cols);
        likelihoods_all{cam} = pose(:, likelihood_cols);
    end

    % Initialize the points matrix
    points = struct();

    % Initialize the progress bar
    total_steps = num_bodyparts * num_frames;
    completed_steps = 0;
    waitbar_handle = waitbar(0, 'Processing...', 'Name', 'Weighted Least Squares Triangulation');
    tic; % Start timer
    
    for bodypart = 1:num_bodyparts
        % Initialize b array for the current body part
        b = zeros(num_frames, 3);
        
        for frame = 1:num_frames
            % Initialize matrices for WLS equation for current frame
            X = [];
            W = [];
            y = [];
            
            for cam = 1:numCams
                % Access projection mat M for current camera
                projection_mat = projection_mat_all{cam};
    
                % Access likelihoods for current camera
                likelihoods = likelihoods_all{cam};

                % Access x and y coordinates for current frame, cam, bp
                x_point = trajectories_all{cam}(frame, bodypart, 1);
                y_point = trajectories_all{cam}(frame, bodypart, 2);
    
                % Access likelihood for current frame, cam, bodypart
                likelihood = likelihoods(frame, bodypart);
    
                % Add projection matrix for current camera to X
                X = [X; projection_mat];
    
                % Add likelihood twice to W
                W = blkdiag(W, likelihood * eye(2));
    
                % Add current point column-wise to y
                y = [y; x_point; y_point];
            end
            
            % Solve for the 3D point using weighted least squares
            b(frame, :) = (X' * W * X) \ (X' * W * y);
            
            % Update progress bar
            completed_steps = completed_steps + 1;
            waitbar(completed_steps / total_steps, waitbar_handle, ...
                sprintf('Processing... %3.1f%% complete', completed_steps / total_steps * 100));
        end
        
        % Store the 3D coordinates for the current body part in the struct
        bodypart_name = bodypart_names{bodypart};
        points.(bodypart_name) = b;
    end
    
    close(waitbar_handle); % Close the progress bar
    
    % Prompt the user to select a save directory
    saveDir = uigetdir('', 'Select a directory to save the output');

    addpath("../../INPUT/mat_struct_summary");

    if saveDir ~= 0
        % Save the struct as '{trialName}_TRJ.mat'
        save(fullfile(saveDir, [trialName, '_TRJ.mat']), 'points');
        
        % Call the external function to print the struct summary
        mat_struct_summary(fullfile(saveDir, [trialName, '_TRJ.mat']));
    else
        disp('User canceled the directory selection');
    end
end