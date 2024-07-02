% Prompt user to select an Excel file
[file, path] = uigetfile('*.xlsx', 'Select an Excel file');
if isequal(file, 0)
    disp('User selected Cancel');
    return;
end

% Read the Excel file
fullFileName = fullfile(path, file);
data = readtable(fullFileName);

% Initialize summary data
columnNames = data.Properties.VariableNames;
numColumns = width(data);
uniqueCounts = zeros(1, numColumns);
sums = zeros(1, numColumns);

% Compute unique counts and sums
for i = 1:numColumns
    columnData = data{:, i};
    uniqueCounts(i) = numel(unique(columnData));
    
    if isnumeric(columnData)
        sums(i) = sum(columnData, 'omitnan');
    end
end

% Create a table for summary data
summaryTable = array2table([uniqueCounts; sums], 'VariableNames', columnNames, ...
    'RowNames', {'UniqueCounts', 'Sums'});

% Generate output file name
[~, baseFileName, ~] = fileparts(file);
outputFileName = fullfile(path, [baseFileName, '_summarized.csv']);

% Write the summary data to a CSV file
writetable(summaryTable, outputFileName, 'WriteRowNames', true);

disp(['Summary CSV file created: ', outputFileName]);