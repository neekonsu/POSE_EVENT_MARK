function points = weighted_least_squares_triangulation(dlc_struct_cam1, dlc_struct_cam2, struct_keypoints_cam1, struct_keypoints_cam2)
    % WEIGHTED_LEAST_SQUARES_TRIANGULATION
    % This function performs weighted least squares triangulation on at least two camera angles of pose estimation data.
    % The current version of this function defaults to using two camera angles.

    % Store number of camera angles
    numCams = 2;

    % Initialize storage for basis vectors, projections, trajectories, and likelihoods
    projections_all = cell(numCams, 1);

    % Combine keypoints structs into array for indexing by camera
    keypoints_structs = [struct_keypoints_cam1, struct_keypoints_cam2];

    % Get bodypart names from dlc_structs
    % CONTRACT: all camera angles must be processed with the same set of bodyparts (DLC analyze videos)
    bodyparts = fieldnames(dlc_struct_cam1);

    % Get number of bodyparts
    numBodyparts = size(bodyparts);

    % Get number of frames
    % CONTRACT: all camera angles must capture the same number of frames
    numFrames = size(dlc_struct_cam1.(bodyparts{1}).x, 1);

    % Join dlc structs into cell array for indexable access
    dlc_structs_all = cell(2,1);
    dlc_structs_all{1} = dlc_struct_cam1;
    dlc_structs_all{2} = dlc_struct_cam2;
    
    % Generate projection matrices for each camera
    for cam = 1:numCams

        % Get keypoints struct for current camera
        keypointStruct = keypoints_structs(cam);

        % Get keypoints coordinates table and size from struct for current camera
        keypointCoordinates = keypointStruct.Coordinates;
        keypointCoordinatesRows = size(keypointCoordinates, 1);

        % Initialize table for storing projection matrices corresponding to transition frames
        projectionTable = cell(keypointCoordinatesRows, 2);

        % Get keypoint names and number of names from struct for current camera (origin included, matches columns of keypointsCoordinates table)
        % CONTRACT: there must only be three basis keypoints
        keypointNames = fieldnames(keypointStruct.OriginDistance);
        keypointNamesLength = 3; % 3 by CONTRACT

        % Initialize array for storing keypoint distances from origin (redundant, remove later, preemptive inclusion for stepping)
        keypointOriginDistance = zeros(keypointNamesLength);

        % Initialize D matrix storing two copies of each origin distance along its diagonal, for solving the projection matrices
        keypointOriginDistanceMatrix = zeros(keypointNamesLength, keypointNamesLength);

        % Construct array of distances in order of keypointNames 
        for i = 1:keypointNamesLength
            % Get ith keypointName's corresponding origin distance (reference order to keypointNames for ensuring consistency)
            ithKeypointOriginDistance = keypointStruct.OriginDistance.(keypointNames(i));

            % Set ith keypointOriginDistance to ith keypointName's corresponding origin distance
            keypointOriginDistance(i) = ithKeypointOriginDistance;

            % Set 2ith and 2ith+1 index of diagonal of D matrix to distance for current keypoint
            diagonalIndex1 = 2*i-1;
            diagonalIndex2 = 2*i;
            keypointOriginDistanceMatrix(diagonalIndex1, diagonalIndex1) = ithKeypointOriginDistance;
            keypointOriginDistanceMatrix(diagonalIndex2, diagonalIndex2) = ithKeypointOriginDistance;
        end

        % Iterate rows of Coordinates table to produce projections table for current camera, with original transition frames now corresponding to a projection matrix
        for i = 1:keypointCoordinatesRows
            % Get current row coordinates (keypoint columns only):
            currRowCoordinates = keypointCoordinates(i, 2:end);
            
            % Get transition frame number for current row
            transitionFrame = keypointCoordinates{i, 1}; % ERROR CHECK: Could just index by {i}

            % Initialize P column vector for storing 2D points (observed, treated as projection of basis vectors constructed from distances)
            P = zeros(6);

            % Iterate coordinates of keypoints in current row, corresponding to period of constant positions, to populate P
            for keypointIndex = 1:keypointNamesLength
                % Get coordinate <1x2 Double/Cell>
                point2D = currRowCoordinates{keypointIndex};

                % Get x and y coordinates separately from point
                point2D_x = point2D(1);
                point2D_y = point2D(2);

                % Populate P with x and y in column
                P(keypointIndex*2-1) = point2D_x;
                P(keypointIndex*2) = point2D_y;
            end % ERROR CHECK: Are columns in the same order as keypointNames? If not, access coordinates in order of keypointNames

            % Solve for parameters of M projection matrix as vector
            D = keypointOriginDistanceMatrix;
            m_vec = D \ P;

            % Reshape parameters of M projection matrix from column vector to <2x3 Cell> matrix form
            M = reshape(m_vec, [2,3]);

            % Add entry for this transition frame (this projeciton matrix) to projectionTable
            projectionTable{i, 1} = transitionFrame;
            projectionTable{i, 2} = M;
        end

        % Add current projection table to corresponding cell in projections_all
        projections_all{cam} = projectionTable;
    end

    % Initialize the points matrix
    points = struct();

    % Initialize the progress bar
    total_steps = numBodyparts * numFrames;
    completed_steps = 0;
    waitbar_handle = waitbar(0, 'Processing...', 'Name', 'Weighted Least Squares Triangulation');
    tic; % Start timer
    
    for bodypart = 1:numBodyparts
        % Initialize b array for the current body part
        b = zeros(numFrames, 3);

        % Get name of current bodypart
        bodypartName = bodyparts(bodypart);
        
        for frame = 1:numFrames
            % Initialize matrices for WLS equation for current frame
            X = [];
            W = [];
            y = [];
            
            for cam = 1:numCams
                % Get DLC struct for current camera
                dlc_struct = dlc_structs_all{cam};

                % Get projection table for current camera
                projectionTable = projections_all{cam};

                % Default, projection matrix is the last matrix
                M = projectionTable{end, 2};

                % If frame is less than the last transition
                if frame < projectionTable{end, 1}
                    % Find corresponding matrix to current frame
                    for row = size(projectionTable, 1):-1:1
                        % Get the transition frame
                        transitionFrame = projectionTable{row, 1};
                        % Check if the frame is less than
                        if frame >= transitionFrame
                            M = projectionTable{row,2};
                            break;
                        end
                    end
                end
    
                % Add projection matrix for current camera to X
                X = [X; M]; %#ok<AGROW>

                % Access x and y coordinates for current frame, cam, bp
                x_point = dlc_struct.(bodypartName).x(frame);
                y_point = dlc_struct.(bodypartName).y(frame);
    
                % Access likelihood for current frame, cam, bodypart
                likelihood = dlc_struct.(bodypartName).likelihood(frame);
    
                % Add likelihood twice to W
                W = blkdiag(W, likelihood * eye(2));
    
                % Add current point column-wise to y
                y = [y; x_point; y_point]; %#ok<AGROW>
            end
            
            % Solve for the 3D point using weighted least squares
            b(frame, :) = (X' * W * X) \ (X' * W * y);
            
            % Update progress bar
            completed_steps = completed_steps + 1;
            waitbar(completed_steps / total_steps, waitbar_handle, ...
                sprintf('Processing... %3.1f%% complete', completed_steps / total_steps * 100));
        end
        
        % Store the 3D coordinates for the current body part in the struct
        bodypartList = {"thumb_tip","index_tip","wrist","forearm","elbow","upper_arm","shoulder"};
        bodypart_name = bodypartList(bodypart);
        points.(bodypart_name) = b;
    end
    
    close(waitbar_handle); % Close the progress bar
    
    % Prompt the user to select a save directory
    saveDir = uigetdir('', 'Select a directory to save the output');

    addpath("../../PREPROCESSING/mat_struct_summary");

    if saveDir ~= 0
        % Save the struct as '{trialName}_TRJ.mat'
        save(fullfile(saveDir, [trialName, '_TRJ.mat']), 'points');
        
        % Call the external function to print the struct summary
        mat_struct_summary(fullfile(saveDir, [trialName, '_TRJ.mat']));
    else
        disp('User canceled the directory selection');
    end
end