% Neurorestore's palette
palette.color.ir = [249,82,91]/255; % Red color from the palette

% Prompt user to select a CSV file
[csvFile, csvPath] = uigetfile('*.csv', 'Select a CSV file');
if isequal(csvFile, 0)
    disp('User selected Cancel');
    return;
end

% Read the CSV file
csvFullFileName = fullfile(csvPath, csvFile);
data = readtable(csvFullFileName);

% Extract the first and second columns
frames = data{:, 1};
xPosition = data{:, 2};

% Plot the data
figure;
plot(frames, xPosition, 'Color', palette.color.ir, 'LineWidth', 2);

% Set plot properties
xlabel('Frame');
ylabel('X Position');
title('X Position vs. Frame');
set(gca, 'Color', 'w'); % Set background color to white
set(gcf, 'Color', 'w'); % Set figure background color to white

% Adjust plot appearance
box on;
grid on;
