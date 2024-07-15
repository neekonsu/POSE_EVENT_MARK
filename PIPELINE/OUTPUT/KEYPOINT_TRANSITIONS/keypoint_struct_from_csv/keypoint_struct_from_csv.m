function keypoint_struct_from_csv()
    % Keypoint Processing Script
    
    % Prompt user to select a CSV file
    [file, path] = uigetfile('*.csv', 'Select the CSV file');
    if isequal(file, 0)
        disp('User selected Cancel');
        return;
    end
    fullPath = fullfile(path, file);

    % Read the CSV file headers
    fid = fopen(fullPath, 'r');
    header1 = fgetl(fid);
    header2 = fgetl(fid);
    header3 = fgetl(fid);
    fclose(fid);

    % Read the CSV file data, skipping the header rows
    opts = detectImportOptions(fullPath);
    opts.DataLines = [4, Inf]; % Start reading from the fourth row
    data = readtable(fullPath, opts);

    % Parse the header to get keypoint names
    keypoints = strsplit(header2, ',');
    keypoint0_index = find(strcmpi(keypoints, 'keypoint0'), 1);
    if isempty(keypoint0_index)
        error('Could not find "keypoint0" in the CSV header');
    end
    keypoints = keypoints(keypoint0_index:end); % Start from 'keypoint0'
    keypoints = unique(keypoints); % Remove duplicates
    numKeypoints = length(keypoints);

    % Find columns for each keypoint
    keypointData = [];
    for i = 1:numKeypoints
        x_col = keypoint0_index + (i-1)*3;
        y_col = keypoint0_index + (i-1)*3 + 1;
        likelihood_col = keypoint0_index + (i-1)*3 + 2;
        
        xCol = data{:, x_col};
        yCol = data{:, y_col};
        likelihoodCol = data{:, likelihood_col};
        
        keypointData = [keypointData, xCol, yCol, likelihoodCol];
    end

    % Extract x coordinates for each keypoint
    xSignals = keypointData(:, 1:3:end);

    % Run split_shifting_keypoints_1D on each x-signal
    threshold = input('Enter the threshold for split_shifting_keypoints_1D: ');
    window = input('Enter the window size for split_shifting_keypoints_1D: ');
    allTransitions = cell(1, numKeypoints);
    for i = 1:numKeypoints
        [~, transitions] = split_shifting_keypoints_1D(xSignals(:, i), threshold, window);
        allTransitions{i} = transitions;
    end

    % Combine keypoint transitions
    combinedTransitions = combine_keypoint_transitions(allTransitions{:});

    % Create the output struct
    output = struct('keypoints', struct());
    for i = 1:length(combinedTransitions) + 1
        phaseName = ['phase' num2str(i)];
        
        if i == 1
            startFrame = 1;
        else
            startFrame = combinedTransitions(i-1);
        end
        
        if i > length(combinedTransitions)
            endFrame = height(data);
        else
            endFrame = combinedTransitions(i) - 1;
        end
        
        output.keypoints.(phaseName).frames = [startFrame, endFrame];
        
        keypoint_positions = zeros(1, 2 * numKeypoints);
        for j = 1:numKeypoints
            xMean = mean(xSignals(startFrame:endFrame, j));
            yMean = mean(keypointData(startFrame:endFrame, 3*j-1));
            keypoint_positions(2*j-1:2*j) = [xMean, yMean];
        end
        output.keypoints.(phaseName).keypoint_positions = keypoint_positions;
    end

    % Prompt user for save location
    [saveFile, savePath] = uiputfile('*.mat', 'Save the output struct');
    if isequal(saveFile, 0)
        disp('User selected Cancel');
    else
        save(fullfile(savePath, saveFile), 'output');
        disp(['Output struct saved to ' fullfile(savePath, saveFile)]);
    end
end