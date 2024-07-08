function [output, avg_likelihoods] = moving_average(trialDir)
   % PROCESS_KEYPOINT_MARKERS   Function to process tracked keypoints in a trial directory
    % trialDir: Directory containing folders for each camera angle during a
    % single trial. Typically 8 Camera Angles

    % Store the trialName
    [~, trialName, ~] = fileparts(trialDir);
    folderPath = trialDir; % Set the folder path to the trial directory
    camFolders = dir(fullfile(folderPath, '*')); % List all items in the directory
    % Filter out non-directory items and the '.' and '..' entries
    camFolders = camFolders([camFolders.isdir] & ~ismember({camFolders.name}, {'.', '..'}));
    % Number of camera folders [checked]
    numCams = length(camFolders);

    ouptut = struct();
    avg_likelihoods = struct();

    % Iterate over each camera directory
    for cam = 1:numCams
        % Store Camera Folder
        camFolder = camFolders(cam);

        % Define the path for the current camera folder and list files
        camFolderPath = fullfile(trialDir, camFolder.name);
        camFiles = {dir(camFolderPath).name};

        % Extract the camera number from the camera folder name
        camNum = regexp(camFolder.name, '\d+', 'match', 'once');

        % Construct the expected pose CSV filename pattern
        poseFilePattern = sprintf('^%s-%s.*\\.csv$', trialName, camNum);

        % Filter files in camera folder by regexp
        csvFile = camFiles(~cellfun('isempty', regexp(camFiles, poseFilePattern)));

        % Check if the corresponding pose CSV file was found
        if isempty(csvFile)
            error('No corresponding pose CSV file found for %s', camFolders(cam).name);
        end

        % Load the pose CSV file as text
        filePath = fullfile(camFolderPath, csvFile{1});
        fileContent = fileread(filePath);
        fileLines = strsplit(fileContent, '\n');
        
        % Extract headers and data lines
        headerLines = fileLines(1:3); % Adjust this if you have more or fewer header lines
        dataLines = fileLines(4:end);
        dataLines = dataLines(~cellfun('isempty', dataLines)); % Remove empty lines

        % Split the headers and data into separate columns
        % headers = strsplit(headerLines{1}, ','); % REDUNDANT, UNUSED VAR
        bodyparts = strsplit(headerLines{2}, ',');
        coords = strsplit(headerLines{3}, ',');

        % Combine headers into final variable names
        variableNames = strcat(bodyparts, '_', coords);
        variableNames = regexprep(variableNames, '^bodyparts_coords$', 'frame'); % Rename the first column to 'frame'

        % Convert data lines into a numeric array
        data = cellfun(@(x) str2double(strsplit(x, ',')), dataLines, 'UniformOutput', false);
        data = vertcat(data{:});

        % Convert numeric array to table
        % poseData = array2table(data, 'VariableNames', variableNames); % CONVERTS TABLE TO STRING TYPE FOR ALL CELLS, REMOVE

        % Identify columns corresponding to bodyparts named "keypoint%d"
        keypointCols = contains(variableNames, 'keypoint');
        keypointData = data(:, keypointCols);
        
        % Now that keypointData is extracted, modify variableNames to only
        % contain names of keypoints
        keypointNames = variableNames(keypointCols);

        % Perform moving average on each column with configurable window size set by variable indicating number of frames
        windowSize = 5; % Example window size, modify as needed
        for col = 1:width(keypointData)
            keypointData(:, col) = windowmean(keypointData(:, col), windowSize);
        end

        % 3D plot the averaged data, making one plot per bodypart
        uniqueBodyparts = unique(erase(string(keypointNames), {'_x', '_y', '_likelihood'}));
        for bp = 1:length(uniqueBodyparts)
            % Extract x and y coordinates
            xData = keypointData(:, contains(keypointNames, [uniqueBodyparts{bp}, '_x']));
            yData = keypointData(:, contains(keypointNames, [uniqueBodyparts{bp}, '_y']));

            % Create 3D plot
            figure;
            plot3(1:length(xData), xData, yData);
            title(['3D plot for ', uniqueBodyparts{bp}]);
            xlabel('Frame');
            ylabel('X Coordinate');
            zlabel('Y Coordinate');
            grid on;
        end

        % Export as projections.csv to the camera folder with one line of headers indicating the bodypart name followed by x or y, excluding likelihoods
        output.(['CAM',cam]) = keypointData(:, ~contains(keypointNames, 'likelihood'));
        avg_likelihoods.([['CAM',cam]]) = keypointData(:, contains(keypointNames, 'likelihood'));
    end

end

function output = windowmean(array, window)
    % Initialize output to the same size as array
    output = zeros(size(array));
    
    % Iterate over the array in steps of 'window'
    for i = 1:window:length(array)
        % Determine the end index for the current window
        endIndex = min(i + window - 1, length(array));
        
        % Calculate the mean of the current window
        windowMean = mean(array(i:endIndex));
        
        % Assign the mean value to the corresponding elements in output
        output(i:endIndex) = windowMean;
    end
end