function plot3DAnd2DCoordinatesFromCSV()
    % Set the default renderer
    set(0, 'DefaultFigureRenderer', 'painters');
    
    % Define the color palette
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

    % Set the default color palette
    palette.default_color = [palette.color.ir;
        palette.color.bd;
        palette.color.yd;
        palette.color.db;
        palette.color.bl;
        palette.color.yl];

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

    % Prompt the user to select a body part from a dropdown menu
    [selectionIndex, ok] = listdlg('PromptString', 'Select a body part:', ...
                                   'SelectionMode', 'single', ...
                                   'ListString', bodyParts(2:3:end));
    
    if ~ok
        disp('User canceled the selection');
        return;
    end
    
    selectedBodyPart = bodyParts{(selectionIndex - 1) * 3 + 2};
    
    % Initialize arrays for coordinates and likelihood
    numLines = length(dataLines);
    xCoords = zeros(numLines, 1);
    yCoords = zeros(numLines, 1);
    likelihood = zeros(numLines, 1);
    
    % Loop through each data line to extract x, y coordinates and likelihood
    for i = 1:numLines
        lineData = strsplit(dataLines{i}, ',');
        xCoords(i) = str2double(lineData{(selectionIndex - 1) * 3 + 2});
        yCoords(i) = str2double(lineData{(selectionIndex - 1) * 3 + 3});
        likelihood(i) = str2double(lineData{(selectionIndex - 1) * 3 + 4});
    end
    
    % Generate frame numbers (t)
    t = (1:numLines)';

    % Normalize likelihood to [0, 1] for color mapping
    normalizedLikelihood = (likelihood - min(likelihood)) / (max(likelihood) - min(likelihood));
    
    % Generate colors from red to grey
    startColor = palette.color.ir;
    endColor = palette.color.cg1;
    colors = (1 - normalizedLikelihood) * startColor + normalizedLikelihood * endColor;
    
    % Create the 3D plot
    figure;
    scatter3(t, xCoords, yCoords, 10, colors, 'filled'); % Small dot size
    colorbar;
    colormap([linspace(startColor(1), endColor(1), 100)', linspace(startColor(2), endColor(2), 100)', linspace(startColor(3), endColor(3), 100)']);
    xlabel('Frame Number');
    ylabel('X Coordinate');
    zlabel('Y Coordinate');
    title(['3D Plot of ', strrep(selectedBodyPart, '_', ' '), ' (Time, X, Y) with Likelihood']);

    % Call the function to create 2D plots
    plot2DCoordinatesFromCSV(t, xCoords, yCoords, likelihood, startColor, endColor, selectedBodyPart);
end

function plot2DCoordinatesFromCSV(t, xCoords, yCoords, likelihood, startColor, endColor, selectedBodyPart)
    % Normalize likelihood to [0, 1] for color mapping
    normalizedLikelihood = (likelihood - min(likelihood)) / (max(likelihood) - min(likelihood));
    
    % Generate colors from red to grey
    colors = (1 - normalizedLikelihood) * startColor + normalizedLikelihood * endColor;

    % Create a 2D plot of x vs. t
    figure;
    scatter(t, xCoords, 10, colors, 'filled'); % Small dot size
    colorbar;
    colormap([linspace(startColor(1), endColor(1), 100)', linspace(startColor(2), endColor(2), 100)', linspace(startColor(3), endColor(3), 100)']);
    xlabel('Frame Number');
    ylabel('X Coordinate');
    title(['2D Plot of ', strrep(selectedBodyPart, '_', ' '), ' (Time, X)']);
    
    % Create a 2D plot of y vs. t
    figure;
    scatter(t, yCoords, 10, colors, 'filled'); % Small dot size
    colorbar;
    colormap([linspace(startColor(1), endColor(1), 100)', linspace(startColor(2), endColor(2), 100)', linspace(startColor(3), endColor(3), 100)']);
    xlabel('Frame Number');
    ylabel('Y Coordinate');
    title(['2D Plot of ', strrep(selectedBodyPart, '_', ' '), ' (Time, Y)']);
end

plot3DAnd2DCoordinatesFromCSV();