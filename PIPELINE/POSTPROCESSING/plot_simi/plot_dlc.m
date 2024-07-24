% Define frame range
startFrame = 1;
endFrame = 10000;

% Load DLC trajectory data
dlc_traj = load("Natalya_20200723_ARM_001_TRJ.mat");
dlc2D = load("Natalya_20200723_ARM_001-2DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000_reencoded.mat");

% Define body parts to plot
body_parts = {'index_tip', 'thumb_tip', 'wrist'};

% Create time vector
time = (startFrame:endFrame)';

% Create a figure for the 3D DLC plots
figure('Position', [100, 100, 1200, 800]);

for i = 1:length(body_parts)
    body_part = body_parts{i};
    
    % Extract coordinates for the current body part
    x = dlc_traj.points.(body_part)(startFrame:endFrame, 1);
    y = dlc_traj.points.(body_part)(startFrame:endFrame, 2);
    z = dlc_traj.points.(body_part)(startFrame:endFrame, 3);
    
    % Create subplot for the current body part
    subplot(3, 1, i);
    
    % Plot x, y, and z coordinates
    plot(time, x, '-r', 'DisplayName', 'X');
    hold on;
    plot(time, y, '-g', 'DisplayName', 'Y');
    plot(time, z, '-b', 'DisplayName', 'Z');
    hold off;
    
    % Set title and labels
    title(['3D DLC Trajectory - ' strrep(body_part, '_', ' ')]);
    xlabel('Frame');
    ylabel('Coordinate Value');
    
    % Add legend and grid
    legend('Location', 'best');
    grid on;
end

% Adjust the layout
sgtitle('3D DLC Trajectories for Index Tip, Thumb Tip, and Wrist');

% Create a new figure for the 2D DLC plots
figure('Position', [100, 100, 1200, 800]);

for i = 1:length(body_parts)
    body_part = body_parts{i};
    
    % Extract coordinates for the current body part from dlc2D
    x = dlc2D.(body_part).x(startFrame:endFrame);
    y = dlc2D.(body_part).y(startFrame:endFrame);
    
    % Create subplot for the current body part
    subplot(3, 1, i);
    
    % Plot x and y coordinates
    yyaxis left
    plot(time, x, '-r', 'DisplayName', 'X');
    hold on;
    plot(time, y, '-g', 'DisplayName', 'Y');
    ylabel('Coordinate Value');
    
    hold off;
    
    % Set title and labels
    title(['2D DLC Trajectory - ' strrep(body_part, '_', ' ')]);
    xlabel('Frame');
    
    % Add legend and grid
    legend('Location', 'best');
    grid on;
end

% Adjust the layout
sgtitle('2D DLC Trajectories for Index Tip, Thumb Tip, and Wrist');