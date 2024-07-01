function dlc_to_simi_mat()
    % Select the CSV file using a file dialog
    [filename, pathname] = uigetfile("*.csv", "Select a CSV file to parse");

    % Check if the user selected a file or canceled the dialog
    if isequal(filename, 0) || isequal(pathname, 0)
        disp('User canceled the file selection');
        return;
    end

    % Read the entire CSV file without skipping any rows
    fileID = fopen(fullfile(pathname, filename));
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
        
        for j = 1:numLines
            lineData = strsplit(dataLines{j}, ',');
            xCoords(j) = str2double(lineData{(i-1)*3 + 2});
            yCoords(j) = str2double(lineData{(i-1)*3 + 3});
        end
        
        % Create z coordinates as zeros
        zCoords = zeros(size(xCoords));
        
        % Assign to the struct
        dataStruct.(partName) = struct('x', xCoords, 'y', yCoords, 'z', zCoords);
    end

    % Prompt the user to select the destination folder
    destinationPath = uigetdir('', 'Select the destination folder');

    % Check if the user selected a folder or canceled the dialog
    if isequal(destinationPath, 0)
        disp('User canceled the folder selection');
        return;
    end

    % Generate the .mat filename from the CSV filename
    [~, name, ~] = fileparts(filename);
    matFilename = fullfile(destinationPath, [name, '.mat']);

    % Save the struct to a .mat file
    save(matFilename, '-struct', 'dataStruct');
    
    % Display the structure
    disp(['The structure has been created and saved to ', matFilename, ':']);
    disp(dataStruct);
end