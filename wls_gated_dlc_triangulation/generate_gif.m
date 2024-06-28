function generate_gif(trialDir)
    % Construct the path to the optimized trajectory CSV file
    optimizedTrajectoryFile = fullfile(trialDir, sprintf('%s_optimized_trajectory.csv', trialDir));

    % Read the CSV file
    data = readtable(optimizedTrajectoryFile);

    % Extract the unique body parts
    bodyParts = unique(data.bodypart);

    % Initialize a 3D array to store the body parts data
    numFrames = max(data.frame);
    numBodyParts = length(bodyParts);
    bodyParts3D = zeros(numFrames, numBodyParts, 3);

    % Populate the 3D array with data from the CSV file
    for i = 1:height(data)
        frameIndex = data.frame(i);
        bodyPartIndex = strcmp(bodyParts, data.bodypart{i});
        bodyParts3D(frameIndex, bodyPartIndex, :) = [data.x(i), data.y(i), data.z(i)];
    end

    % Generate the GIF
    filename = fullfile(trialDir, '3D_trajectory.gif');
    for frameIndex = 1:numFrames
        scatter3(bodyParts3D(frameIndex, :, 1), bodyParts3D(frameIndex, :, 2), bodyParts3D(frameIndex, :, 3), 'filled');
        axis equal;
        drawnow;
        frame = getframe(gcf);
        im = frame2im(frame);
        [imind, cm] = rgb2ind(im, 256);
        if frameIndex == 1
            imwrite(imind, cm, filename, 'gif', 'Loopcount', inf, 'DelayTime', 0.1);
        else
            imwrite(imind, cm, filename, 'gif', 'WriteMode', 'append', 'DelayTime', 0.1);
        end
    end
end
