function prune_unlikely_points()
    % Prompt the user to select a CSV file
    [csvFilename, csvPathname] = uigetfile("*.csv", "Select a CSV file to parse");
    if isequal(csvFilename, 0) || isequal(csvPathname, 0)
        disp('User canceled the CSV file selection');
        return;
    end
    addpath(csvPathname);
    
    % Read the entire CSV file without skipping any rows
    fileID = fopen(fullfile(csvPathname, csvFilename));
    rawData = textscan(fileID, '%s', 'Delimiter', '\n');
    fclose(fileID);
    rawData = rawData{1};

    % Extract the body part names from the second row
    bodyParts = strsplit(rawData{2}, ',');
    coords = strsplit(rawData{3}, ',');

    % Ensure body parts and coordinates are valid MATLAB variable names
    bodyParts = matlab.lang.makeValidName(bodyParts);
    coords = matlab.lang.makeValidName(coords);

    % Extract unique body parts by skipping every 3rd element
    uniqueBodyParts = bodyParts(2:3:end);

    % Prompt the user to select a body part
    [indx, tf] = listdlg('PromptString', {'Select a body part to process:'}, ...
                         'SelectionMode', 'single', 'ListString', uniqueBodyParts);
    if tf == 0
        disp('User canceled the body part selection');
        return;
    end
    selected_bodypart = uniqueBodyParts{indx};
    selectedIdx = find(strcmp(bodyParts, selected_bodypart));

    % Read the data starting from the fourth line
    dataStartLine = 4;
    dataLines = rawData(dataStartLine:end);

    % Prompt the user to enter a likelihood threshold
    prompt = {'Enter the likelihood threshold:'};
    dlgtitle = 'Input';
    dims = [1 35];
    definput = {'0.5'};
    answer = inputdlg(prompt, dlgtitle, dims, definput);
    if isempty(answer)
        disp('User canceled the threshold input');
        return;
    end
    likelihoodThreshold = str2double(answer{1});

    % Convert dataLines to numeric array for processing
    dataMatrix = cellfun(@(x) str2double(strsplit(x, ',')), dataLines, 'UniformOutput', false);
    dataMatrix = vertcat(dataMatrix{:});

    % Get the indices for x, y, and likelihood
    xIdx = selectedIdx;
    yIdx = selectedIdx + 1;
    likelihoodIdx = selectedIdx + 2;

    % Loop through each data line to extract x, y coordinates and likelihood
    % Replace unlikely points with -1 based on user-prompted threshold
    for i = 1:size(dataMatrix, 1)
        likelihood = dataMatrix(i, likelihoodIdx);

        if likelihood < likelihoodThreshold
            dataMatrix(i, xIdx) = -1;
            dataMatrix(i, yIdx) = -1;
        end
    end

    % Take first derivative of signals x and y
    x_derivative = diff(dataMatrix(:, xIdx));
    y_derivative = diff(dataMatrix(:, yIdx));

    % Plot histogram of derivatives
    figure;
    histogram(abs(x_derivative(:)), 50);
    hold on;
    histogram(abs(y_derivative(:)), 50);
    legend('x-derivative', 'y-derivative');
    title('Histogram of x and y derivatives');
    hold off;

    % Determine the threshold for top 10% of derivatives
    all_derivatives = [abs(x_derivative(:)); abs(y_derivative(:))];
    top10_threshold = prctile(all_derivatives, 90);

    % Set all frames with top 10% of derivatives to (-1,-1)
    high_der_idx = find(abs(x_derivative) > top10_threshold | abs(y_derivative) > top10_threshold);
    dataMatrix(high_der_idx + 1, xIdx) = -1;  % +1 to correct the index after diff
    dataMatrix(high_der_idx + 1, yIdx) = -1;

    % Linearly interpolate all (-1,-1) points to replace these points
    x = dataMatrix(:, xIdx);
    y = dataMatrix(:, yIdx);
    x(x == -1) = NaN;
    y(y == -1) = NaN;
    x = fillmissing(x, 'linear');
    y = fillmissing(y, 'linear');
    dataMatrix(:, xIdx) = x;
    dataMatrix(:, yIdx) = y;

    % Create a new struct to save the pruned data
    prunedData = struct();
    prunedData.(selected_bodypart).x = dataMatrix(:, xIdx);
    prunedData.(selected_bodypart).y = dataMatrix(:, yIdx);

    % Save the pruned data to a .mat file
    [~, name, ~] = fileparts(csvFilename);
    saveFilename = fullfile(csvPathname, [name '_' selected_bodypart '_pruned.mat']);
    save(saveFilename, 'prunedData');

    disp(['Modified data saved to: ', saveFilename]);
end