function extract_initial_keypoints(trialDir)
    % EXTRACT_INITIAL_KEYPOINTS   Function to label keypoints on frames in a given trial directory
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

        % Initialize the data structure
        data = struct();
        data.transition_frame = 1;
        
        % Prompt the user to select the origin
        title('Select the origin');
        [x_origin, y_origin] = ginput(1); % Get the (x, y) coordinates of the origin
        if ~isempty(x_origin)
            plot(x_origin, y_origin, 'ro'); % Plot the selected origin on the image
            data.origin = [x_origin, y_origin, 0]; % Store the origin coordinates (distance is 0)
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
                
                % Prompt the user to enter the distance to the origin in meters
                distance_m = inputdlg(sprintf('Enter the distance between origin and %s (in meters):', keypoints{k}));
                if ~isempty(distance_m)
                    distance = str2double(distance_m{1}); % Store the distance in meters
                    data.(keypoints{k}) = [x, y, distance]; % Store the coordinates and distance
                else
                    errMsg = 'Distance must be entered to continue';
                    disp(errMsg);
                    errordlg(errMsg, 'Error');
                    close(hFig); % Close the figure
                    return;
                end
            else
                data.(keypoints{k}) = [NaN, NaN, NaN]; % Store NaN for skipped points
            end
        end

        % Convert the struct to a table
        dataTable = struct2table(data);

        % Save data to a MAT file
        matPath = fullfile(folderPath, camFolders(i).name, 'keypoints.mat');
        save(matPath, 'dataTable');

        close(hFig); % Close the figure
    end
end