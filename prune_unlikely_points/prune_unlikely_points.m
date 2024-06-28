function prune_unlikely_points()
    % Prompt the user to select a CSV file
    [csvFilename, csvPathname] = uigetfile("*.csv", "Select a CSV file to parse");
    if isequal(csvFilename, 0) || isequal(csvPathname, 0)
        disp('User canceled the CSV file selection');
        return;
    end
    
    % Read the entire CSV file without skipping any rows
    fileID = fopen(fullfile(csvPathname, csvFilename));
    rawData = textscan(fileID, '%s', 'Delimiter', '\n');
    fclose(fileID);
    rawData = rawData{1};

    % Extract the body part names from the second row
    bodyParts = strsplit(rawData{2}, ',');
    bodyParts = matlab.lang.makeValidName(bodyParts);

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

    % Loop through each data line to extract x, y coordinates and likelihood
    for i = 1:length(dataLines)
        lineData = strsplit(dataLines{i}, ',');
        for j = 2:3:length(bodyParts)
            xIdx = j;
            yIdx = j + 1;
            likelihoodIdx = j + 2;

            likelihood = str2double(lineData{likelihoodIdx});
            
            if likelihood < likelihoodThreshold
                lineData{xIdx} = '-1';
                lineData{yIdx} = '-1';
            end
        end
        % Update the data line with modified coordinates
        dataLines{i} = strjoin(lineData, ',');
    end
    
    % Create a new CSV with updated coordinates
    newCsvData = [rawData(1:dataStartLine-1); dataLines];
    
    % Save the new CSV file
    [saveFilename, savePathname] = uiputfile("*.csv", "Save the modified CSV file");
    if isequal(saveFilename, 0) || isequal(savePathname, 0)
        disp('User canceled the file save');
        return;
    end
    
    fileID = fopen(fullfile(savePathname, saveFilename), 'w');
    for i = 1:length(newCsvData)
        fprintf(fileID, '%s\n', newCsvData{i});
    end
    fclose(fileID);

    disp(['Modified CSV file saved to: ', fullfile(savePathname, saveFilename)]);
end