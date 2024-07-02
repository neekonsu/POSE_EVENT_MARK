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

    % Read the CSV file
    data = readtable(fullfile(pathname, filename));
    
    % Limit to the first 1000 frames
    data = data(1:1000, :);

    % Extract the body part names from the header row
    bodyParts = data.Properties.VariableNames;
    bodyParts = bodyParts(2:3:end); % Assuming X, Y, and likelihood columns for each part

    % Generate frame numbers (t)
    t = (1:1000)';

    % Create the 3D plot
    figure;
    hold on;
    numColors = size(palette.default_color, 1);
    numShades = 5; % Number of shades for each color
    plotHandles = gobjects(length(bodyParts), 1);
    for i = 1:length(bodyParts)
        xCoords = data{:, (i-1)*3+2};
        yCoords = data{:, (i-1)*3+3};
        zCoords = yCoords; % Use the y-axis values as the z-axis values
        
        % Determine color and shade
        colorIndex = mod(i-1, numColors) + 1;
        shadeFactor = floor((i-1) / numColors) / numShades;
        color = (1 - shadeFactor) * palette.default_color(colorIndex, :);
        
        plotHandles(i) = plot3(t, xCoords, zCoords, 'Color', color, 'LineWidth', 1.5);
    end
    hold off;
    xlabel('Frame Number');
    ylabel('X Coordinate');
    zlabel('Y Coordinate');
    title('3D Plot of Body Parts (Time, X, Y)');
    grid on;
    legend(plotHandles, strrep(bodyParts, '_', ' '), 'Location', 'northeast');

    % Create 2D plots
    figure;
    hold on;
    plotHandles = gobjects(length(bodyParts), 1);
    for i = 1:length(bodyParts)
        xCoords = data{:, (i-1)*3+2};
        
        % Determine color and shade
        colorIndex = mod(i-1, numColors) + 1;
        shadeFactor = floor((i-1) / numColors) / numShades;
        color = (1 - shadeFactor) * palette.default_color(colorIndex, :);
        
        plotHandles(i) = plot(t, xCoords, 'Color', color, 'LineWidth', 1.5);
    end
    hold off;
    xlabel('Frame Number');
    ylabel('X Coordinate');
    title('2D Plot of X Coordinates of Body Parts');
    grid on;
    legend(plotHandles, strrep(bodyParts, '_', ' '), 'Location', 'northeast');

    figure;
    hold on;
    plotHandles = gobjects(length(bodyParts), 1);
    for i = 1:length(bodyParts)
        yCoords = data{:, (i-1)*3+3};
        
        % Determine color and shade
        colorIndex = mod(i-1, numColors) + 1;
        shadeFactor = floor((i-1) / numColors) / numShades;
        color = (1 - shadeFactor) * palette.default_color(colorIndex, :);
        
        plotHandles(i) = plot(t, yCoords, 'Color', color, 'LineWidth', 1.5);
    end
    hold off;
    xlabel('Frame Number');
    ylabel('Y Coordinate');
    title('2D Plot of Y Coordinates of Body Parts');
    grid on;
    legend(plotHandles, strrep(bodyParts, '_', ' '), 'Location', 'northeast');
end

plot3DAnd2DCoordinatesFromCSV();