function extract_initial_keypoints(trialDir)
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
        frame = imread(fullfile(folderPath, camFolders(i).name, 'frame00001.png'));
        
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