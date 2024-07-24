function dlc_csv_to_struct()
    % Prompt the user to select a folder
    folderPath = uigetdir('.', 'Select a Folder Containing CSV Files');

    % Check if the user selected a folder or canceled the dialog
    if isequal(folderPath, 0)
        disp('User canceled the folder selection');
        return;
    end

    % Get a list of all .csv files in the selected folder
    csvFiles = dir(fullfile(folderPath, '*.csv'));

    % Check if there are any .csv files in the folder
    if isempty(csvFiles)
        disp('No CSV files found in the selected folder.');
        return;
    end

    % Prompt the user to select the destination folder
    destinationPath = uigetdir('', 'Select the destination folder');

    % Check if the user selected a folder or canceled the dialog
    if isequal(destinationPath, 0)
        disp('User canceled the folder selection');
        return;
    end

    % Iterate over each .csv file in the selected folder
    for k = 1:length(csvFiles)
        % Get the full path of the .csv file
        csvFile = fullfile(folderPath, csvFiles(k).name);

        % Read the entire CSV file without skipping any rows
        fileID = fopen(csvFile);
        rawData = textscan(fileID, '%s', 'Delimiter', '\n');
        fclose(fileID);
        rawData = rawData{1};

        % Extract the body part names from the second row
        bodyParts = strsplit(rawData{2}, ',');
        bodyParts = matlab.lang.makeValidName(bodyParts);

        % Read the data starting from the fourth line
        dataStartLine = 4;
        dataLines = rawData(dataStartLine:end);

        % Initialize an empty struct
        dataStruct = struct();

        % Loop through each data line to extract x and y coordinates
        numLines = length(dataLines);
        for i = 1:length(bodyParts)/3
            partName = bodyParts{(i-1)*3 + 2};  % Get part name (skip scorer and coord columns)
            
            xCoords = zeros(numLines, 1);
            yCoords = zeros(numLines, 1);
            likelihoods = zeros(numLines, 1);
            
            for j = 1:numLines
                lineData = strsplit(dataLines{j}, ',');
                xCoords(j) = str2double(lineData{(i-1)*3 + 2});
                yCoords(j) = str2double(lineData{(i-1)*3 + 3});
                likelihoods(j) = str2double(lineData{(i-1)*3 + 4});
            end
            
            % Assign to the struct
            dataStruct.(partName) = struct('x', xCoords, 'y', yCoords, 'likelihood', likelihoods);
        end

        % Generate the .mat filename from the CSV filename
        [~, name, ~] = fileparts(csvFiles(k).name);
        matFilename = fullfile(destinationPath, [name, '_reencoded.mat']);

        % Save the struct to a .mat file
        save(matFilename, '-struct', 'dataStruct');
        
        % Display the structure
        disp(['The structure has been created and saved to ', matFilename, ':']);
        disp(dataStruct);
    end

    disp('Re-encoding completed for all CSV files.');
end