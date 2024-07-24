% Define frame and time ranges
startFrame = 685;
endFrame = 721;

startTimeRow = 687;
endTimeRow = 723;

% Load trajectory data
dlc_traj = load("Natalya_20200723_ARM_001_TRJ.mat");
simi_traj = load("simi_trajectory.mat");

% Extract wrist coordinates from simi_traj
simi_wrist_x = simi_traj.trajectory.wrist.x(startTimeRow:endTimeRow);
simi_wrist_y = simi_traj.trajectory.wrist.y(startTimeRow:endTimeRow);
simi_wrist_z = simi_traj.trajectory.wrist.z(startTimeRow:endTimeRow);

% Extract wrist coordinates from dlc_traj
dlc_wrist_x = dlc_traj.points.index_tip(startFrame:endFrame, 1);
dlc_wrist_y = dlc_traj.points.index_tip(startFrame:endFrame, 2);
dlc_wrist_z = dlc_traj.points.index_tip(startFrame:endFrame, 3);

% Create time vectors
simi_time = (startTimeRow:endTimeRow)'; % Assuming each frame corresponds to a time point
dlc_time = (startFrame:endFrame)';

% Create a figure for x, y, z subplots
figure('Position', [100, 100, 1200, 800]);

% X coordinate subplots
subplot(3, 2, 1);
plot(simi_time, simi_wrist_x, '-o');
title('Simi Wrist Trajectory - X');
xlabel('Frame');
ylabel('X Coordinate');
grid on;

subplot(3, 2, 2);
plot(dlc_time, dlc_wrist_x, '-o');
title('DLC Wrist Trajectory - X');
xlabel('Frame');
ylabel('X Coordinate');
grid on;

% Y coordinate subplots
subplot(3, 2, 3);
plot(simi_time, simi_wrist_y, '-o');
title('Simi Wrist Trajectory - Y');
xlabel('Frame');
ylabel('Y Coordinate');
grid on;

subplot(3, 2, 4);
plot(dlc_time, dlc_wrist_y, '-o');
title('DLC Wrist Trajectory - Y');
xlabel('Frame');
ylabel('Y Coordinate');
grid on;

% Z coordinate subplots
subplot(3, 2, 5);
plot(simi_time, simi_wrist_z, '-o');
title('Simi Wrist Trajectory - Z');
xlabel('Frame');
ylabel('Z Coordinate');
grid on;

subplot(3, 2, 6);
plot(dlc_time, dlc_wrist_z, '-o');
title('DLC Wrist Trajectory - Z');
xlabel('Frame');
ylabel('Z Coordinate');
grid on;

% Adjust the layout
sgtitle('Comparison of Simi and DLC Wrist Trajectories');