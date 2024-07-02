% Neurorestore's palette
palette.color.ir = [249,82,91]/255;
palette.color.ird = [134,46,56]/255;
palette.color.bd = [25,211,197]/255;
palette.color.bl = [138,210,211]/255;
palette.color.yd = [252,176,33]/255;
palette.color.yl = [254,197,87]/255;
palette.color.vy = [240,223,0]/255;
palette.color.db = [49,51,53]/255;
palette.color.cg11 = [84,86,91]/255;
palette.color.cg9 = [117,118,121]/255;
palette.color.cg7 = [150,152,153]/255;
palette.color.cg4 = [187,186,186]/255;
palette.color.cg1 = [219,219,221]/255;

palette.default_color = [palette.color.ir;
    palette.color.bd;
    palette.color.yd;
    palette.color.db;
    palette.color.bl;
    palette.color.yl;];

% Prompt user to select an 'events' MAT file
[matFile, matPath] = uigetfile('*.mat', 'Select an events MAT file');
if isequal(matFile, 0)
    disp('User selected Cancel');
    return;
end

% Load the MAT file
matFullFileName = fullfile(matPath, matFile);
data = load(matFullFileName);
events = data.dataEvent; % The struct containing event data

% Extract field names and data
fieldNames = fieldnames(events);

% Initialize arrays to store frame indexes and labels
frameIndexes = [];
labels = [];

% Populate the frameIndexes and labels arrays
for i = 1:length(fieldNames)
    fieldData = events.(fieldNames{i});
    if ~isempty(fieldData)
        frameIndexes = [frameIndexes; fieldData(:)];
        labels = [labels; repmat({fieldNames{i}}, length(fieldData), 1)];
    end
end

% Sort the frame indexes and labels based on the frame indexes
[frameIndexes, sortedIdx] = sort(frameIndexes);
labels = labels(sortedIdx);

% Get unique labels and assign colors
uniqueLabels = unique(labels);
numLabels = length(uniqueLabels);
colors = repmat(palette.default_color, ceil(numLabels / size(palette.default_color, 1)), 1);
colors = colors(1:numLabels, :); % Ensure colors array has enough colors

% Create a figure
figure;
hold on;

% Plot each frame index with corresponding label color
for i = 1:numLabels
    label = uniqueLabels{i};
    framesWithLabel = frameIndexes(strcmp(labels, label));
    for j = 1:length(framesWithLabel)
        x = framesWithLabel(j);
        plot([x, x], [0, 1], 'Color', colors(i, :), 'LineWidth', 2);
    end
end

% Add legend with labels without underscores
legendCell = strrep(uniqueLabels, '_', ' ');
legend(legendCell, 'Location', 'northeast');

% Add labels and title
xlabel('Frame');
title('Event Labels by Frame');

% Turn off y-axis
set(gca, 'ytick', []);

hold off;