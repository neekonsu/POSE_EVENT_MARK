data = readtable("./test_reach_simi_export_20200723_001.txt", 'Delimiter', '\t');

% Extract the time and the data columns
time = data.Time;

right_wrist_X = data.rightWristX;
right_wrist_Y = data.rightWristY;
right_wrist_Z = data.rightWristZ;

origin_X = data.ORIGINX;
origin_Y = data.ORIGINY;
origin_Z = data.ORIGINZ;

keypoint1_X = data.KEYPOINT1X;
keypoint1_Y = data.KEYPOINT1Y;
keypoint1_Z = data.KEYPOINT1Z;

keypoint2_X = data.KEYPOINT2X;
keypoint2_Y = data.KEYPOINT2Y;
keypoint2_Z = data.KEYPOINT2Z;

keypoint3_X = data.KEYPOINT3X;
keypoint3_Y = data.KEYPOINT3Y;
keypoint3_Z = data.KEYPOINT3Z;

% Create a figure and plot the 3D data
figure;

subplot(3,2,1);
plot3(right_wrist_X, right_wrist_Y, right_wrist_Z, '-o');
title('Right Wrist');
xlabel('X');
ylabel('Y');
zlabel('Z');
grid on;

subplot(3,2,2);
plot3(origin_X, origin_Y, origin_Z, '-o');
title('Origin');
xlabel('X');
ylabel('Y');
zlabel('Z');
grid on;

subplot(3,2,3);
plot3(keypoint1_X, keypoint1_Y, keypoint1_Z, '-o');
title('Keypoint 1');
xlabel('X');
ylabel('Y');
zlabel('Z');
grid on;

subplot(3,2,4);
plot3(keypoint2_X, keypoint2_Y, keypoint2_Z, '-o');
title('Keypoint 2');
xlabel('X');
ylabel('Y');
zlabel('Z');
grid on;

subplot(3,2,5);
plot3(keypoint3_X, keypoint3_Y, keypoint3_Z, '-o');
title('Keypoint 3');
xlabel('X');
ylabel('Y');
zlabel('Z');
grid on;

trajectory = struct();
trajectory.wrist.x = right_wrist_X;
trajectory.wrist.y = right_wrist_Y;
trajectory.wrist.z = right_wrist_Z;
trajectory.origin.x = origin_X;
trajectory.origin.y = origin_Y;
trajectory.origin.z = origin_Z;
trajectory.keypoint1.x = keypoint1_X;
trajectory.keypoint1.y = keypoint1_Y;
trajectory.keypoint1.z = keypoint1_Z;
trajectory.keypoint2.x = keypoint2_X;
trajectory.keypoint2.y = keypoint2_Y;
trajectory.keypoint2.z = keypoint2_Z;
trajectory.keypoint3.x = keypoint3_X;
trajectory.keypoint3.y = keypoint3_Y;
trajectory.keypoint3.z = keypoint3_Z;

save("simi_trajectory.mat", "trajectory");