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

        % Stack the basis vectors into a matrix
        basis_vectors = [i_vector; j_vector; k_vector];
        
        % Given:
        % M: Projection matrix for camera
        % e: basis 3D column vector scaled by measured distance di
        % P: point 2D column vector of e projected into camera perspective
        % Then we solve:
        % [m11*d1;m12*d1;m21*d2;m22*d2;m13*d3;m23*d3]=[P_i;P_j;P_k];
        % To find mij for the 2x3 matrix M corresponding to the current
        % camera
        % TODO: REPLACE WITH CORRECT ESTIMATION OF projection_mat for
        % current camera:
        % % Stack the projections into a single column vector
        % projections = [P_i; P_j; P_k];
        % % Store the basis vectors and projections for this camera
        % basis_vectors_all{i} = basis_vectors;
        % projections_all{i} = projections;
        
        % Extract the x, y, and likelihood columns from the pose file
        % Assume the pose file has the following columns: scorer, bodyparts, coords (x, y, likelihood)
        x_cols = 2:3:size(pose, 2);
        y_cols = 3:3:size(pose, 2);
        likelihood_cols = 4:3:size(pose, 2);
        
        % Store number of frames & bodyparts for current camera's pose data
        num_frames = size(pose, 1);
        num_bodyparts = length(x_cols);

        % Create matrix points and likelihoods for current camera
        trajectories_all{i} = zeros(num_frames, num_bodyparts, 2);
        likelihoods_all{i} = zeros(num_frames, num_bodyparts);

        % Fill the trajectories and likelihoods matrices
        trajectories_all{i}(:, :, 1) = pose(:, x_cols);
        trajectories_all{i}(:, :, 2) = pose(:, y_cols);
        likelihoods_all{i} = pose(:, likelihood_cols);
    end

    % Initialize the points matrix
    points = zeros(num_frames, num_bodyparts, 3);

    % LOOP DESCRIPTION
    % % The WLS estimation is split into chunks for memory.
    % % The loop estimates in chunks of 10,000 samples per bodypart
    % % Typical Computation:
    % % % ~3 chunks per bodypart
    % % % ~7 bodyparts
    % % % Total: 21 block computations to populate `b`

    % Set global index to split computation
    index_in_chunk = 1;
    chunk_size = 10000;
    b = [];
    
    for bodypart = 1:num_bodyparts
        % Initialize matrices for WLS equation for chunks
        X = [];
        W = [];
        y = [];
        
        % DESCRIPTION OF OPERATION:
        % For each frame, iterating each camera:
        % X: for the given frame and cam, add corresponding M to diagonal
        % of X.
        % W: For given frame and cam, add likelihood twice to diagonal of W
        % for x and y coordinates.
        % Y: For given frame and cam, append 2D point to column vector

        % DESCRIPTION OF VARIABLES:
        % projections_all{i}: M proj mat corresponding to cam i
        % likelihoods_all{cam}: all bodyparts and frames for cam i
        % trajectories_all{cam}: access 2D points by cam, frame, bp, and
        % x/y (1/2)
        for frame = 1:num_frames
            for cam = 1:numCams
                % TODO: Replace with projection_mat =
                % projection_mat_all{cam};
                % % Access basis vectors for current camera
                % basis_vectors = basis_vectors_all{cam};
    
                % Access likelihoods for current camera
                likelihoods = likelihoods_all{cam};
    
                x_point = trajectories_all{cam}(frame, bodypart, 1);
                y_point = trajectories_all{cam}(frame, bodypart, 2);
    
                likelihood = likelihoods(frame, bodypart);
    
                % TODO: X = blkdiag(X, projection_mat);
                % % Add basis vectors to X
                % X = [X; basis_vectors];
    
                % Add likelihoods to W
                W = blkdiag(W, likelihood * eye(2));
    
                % Add observations to y
                y = [y; x_point; y_point];
            end
            
            index_in_chunk = index_in_chunk + 1;
            
            % Check if we have reached the chunk size
            if index_in_chunk > chunk_size
                % Solve for the 3D point using weighted least squares for the chunk
                b_chunk = (X' * W * X) \ (X' * W * y);
                
                % Store the 3D coordinates
                b = [b; b_chunk];
                
                % Reset the matrices for the next chunk
                X = [];
                W = [];
                y = [];
                index_in_chunk = 1;
            end
        end
        
        % Solve for the remaining points if any
        if ~isempty(X)
            b_chunk = (X' * W * X) \ (X' * W * y);
            b = [b; b_chunk];
        end
    end

    disp(b);

    % TODO: store b in points
    
    % Display the results
    disp('3D Points:');
    disp(points);
end