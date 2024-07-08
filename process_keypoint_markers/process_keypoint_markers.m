% %{ EXAMPLE POSE DATA
% scorer,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000
% bodyparts,thumb_tip,thumb_tip,thumb_tip,index_tip,index_tip,index_tip,wrist,wrist,wrist,forearm,forearm,forearm,elbow,elbow,elbow,keypoint1,keypoint1,keypoint1,keypoint2,keypoint2,keypoint2
% coords,x,y,likelihood,x,y,likelihood,x,y,likelihood,x,y,likelihood,x,y,likelihood,x,y,likelihood,x,y,likelihood
% 0,713.8554077148438,158.6163787841797,0.4786283075809479,719.4327392578125,157.8507843017578,0.9917176961898804,700.311767578125,170.4683074951172,0.9995953440666199,669.9605712890625,179.5712890625,0.9993858337402344,641.9354858398438,191.74136352539062,0.8703688383102417,623.88037109375,182.67300415039062,0.3274724781513214,607.2002563476562,174.89031982421875,0.20065924525260925
% 1,713.4447021484375,159.03353881835938,0.47246891260147095,719.332275390625,158.02999877929688,0.9902263879776001,700.046630859375,170.7549591064453,0.9994301199913025,669.8108520507812,179.77008056640625,0.9992573857307434,641.5614624023438,192.0361328125,0.8451208472251892,622.854736328125,181.7891082763672,0.28540652990341187,607.3789672851562,175.2157745361328,0.21796545386314392
% %}


function process_keypoint_markers(trialDir)
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
        projectionsTable = keypointData(:, ~contains(keypointNames, 'likelihood'));
        writetable(projectionsTable, fullfile(camFolderPath, 'projections.csv'));
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