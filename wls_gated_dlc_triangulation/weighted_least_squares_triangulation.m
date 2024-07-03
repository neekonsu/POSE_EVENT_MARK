function points = weighted_least_squares_triangulation(trialDir)
    % Store the trialName
    [~, trialName, ~] = fileparts(trialDir);

    % Get list of camera folders [checked]
    camFolders = dir(fullfile(trialDir, '*'));
    camFolders = camFolders([camFolders.isdir] & ~ismember({camFolders.name}, {'.', '..'}));
    
    % Number of camera folders [checked]
    numCams = length(camFolders);
    
    % Initialize storage for basis vectors, projections, trajectories, and likelihoods
    basis_vectors_all = cell(numCams, 1);
    projections_all = cell(numCams, 1);
    trajectories_all = cell(numCams, 1);
    likelihoods_all = cell(numCams, 1);
    
    % Iterate over each camera directory
    for i = 1:numCams
        % Store Camera Folder
        camFolder = camFolders(i);

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
            error('No corresponding pose CSV file found for %s', camFolders(i).name);
        end

        % Load the pose CSV file
        pose = readmatrix(fullfile(camFolderPath, csvFile{1}));
        
        % Extract the distances (column 5) for each key point
        d1 = keypoints{3, 5};
        d2 = keypoints{4, 5};
        d3 = keypoints{5, 5};
        
        % Define the basis vectors using the distances
        i_vector = [d1; 0; 0];
        j_vector = [0; d2; 0];
        k_vector = [0; 0; d3];
        
        % Define the projections from keypoints
        P_i = [keypoints{3, 2}; keypoints{3, 3}];
        P_j = [keypoints{4, 2}; keypoints{4, 3}];
        P_k = [keypoints{5, 2}; keypoints{5, 3}];
        
        % Stack the projections into a single column vector
        projections = [P_i; P_j; P_k];
        
        % Stack the basis vectors into a matrix
        basis_vectors = [i_vector; j_vector; k_vector];
        
        % Extract the x, y, and likelihood columns from the pose file
        % Assume the pose file has the following columns: scorer, bodyparts, coords (x, y, likelihood)
        x_cols = 2:3:size(pose, 2);
        y_cols = 3:3:size(pose, 2);
        likelihood_cols = 4:3:size(pose, 2);
        
        % Store number of frames & bodyparts for current camera's pose data
        num_frames = size(pose, 1);
        num_points = length(x_cols);

        % Create matrix points and likelihoods for current camera
        trajectories_all{i} = zeros(num_frames, num_points, 2);
        likelihoods_all{i} = zeros(num_frames, num_points);

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

                x_point = trajectories_all{i}(frame, point, 1);
                y_point = trajectories_all{i}(frame, point, 2);

                likelihood = likelihoods(frame, point);
                
                % Add basis vectors to X
                X = [X; basis_vectors];
                
                % Add likelihoods to W
                W = blkdiag(W, likelihood * eye(2));
                
                % Add observations to y
                y = [y; x_point; y_point];
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