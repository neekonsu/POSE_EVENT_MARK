function [quantized_keypoints, transition_phases] = quantize_levels_t(avg_keypoints, threshold_px)
    % Initialize output structures
    quantized_keypoints = struct();
    transition_phases = struct();

    % Get field names
    fields = fieldnames(avg_keypoints);

    for f = 1:length(fields)
        % Access table of [x,y * * *] averaged keypoints (i*j double matrix) for all keypoints for camera f 
        keypoints_for_camera = avg_keypoints.(fields{f});
        [numFrames, numCols] = size(keypoints_for_camera);
        
        % Initialize variables for storing results on single camera > keypoint 
        transition_frames = [];

        % Process each keypoint pair (x, y)
        for keypoint = 1:2:numCols
            % Extract x,y arrays for current keypoint
            x_data = keypoints_for_camera(:, keypoint);
            y_data = keypoints_for_camera(:, keypoint + 1);

            % Initialize segment data for the first frame
            % segment_start = 1;
            % avg_coords(segment_start, keypoint) = x_data(segment_start);
            % avg_coords(segment_start, keypoint + 1) = y_data(segment_start);

            for frame = 2:numFrames
                % Calculate Euclidean distance between consecutive points
                distance = sqrt((x_data(frame) - x_data(frame-1))^2 + (y_data(frame) - y_data(frame-1))^2);

                % Check if the distance exceeds the threshold
                if distance >= threshold_px
                    % Store transition frame
                    transition_frames(end+1) = frame;
                end
            end
            % Finalize the last segment
            % avg_coords(segment_start:numFrames, keypoint) = mean(x_data(segment_start:numFrames));
            % avg_coords(segment_start:numFrames, keypoint + 1) = mean(y_data(segment_start:numFrames));
        end

        transition_frames = sort(transition_frames);
        transition_phase_col = zeros(numFrames);
        transition_phase_col(1:transition_frames(1)) = 1;
        for i = 2:length(transition_frames)
            start = transition_frames(i-1);
            ending = transition_frames(i);
            % Set phase number from previous transition frame to current transition frame equal to index of transition frame
            transition_phase_col(start:ending) = ending;
        end
        % TODO: FINISH IMPLEMENTING FOR LOOP TO FILL OUPTUT STRUCT FOR ALL KEYPOINTS, TEST, AND DOCUMENT IN POWERPOINT
        % Set last phase number to one greater than the previous; handles backfilling logic of for-loop
        transition_phase_col(transition_frames(end):end) = length(transition_frames)+1;
        % Store results in the output struct
        % avg_coords(:, end + 1) = segments; % Add the segment indices as the last column
        % quantized_keypoints.(fields{f}) = array2table(avg_coords, 'VariableNames', [avg_keypoints.(fields{f}).Properties.VariableNames, 'Segment']);
        % transition_phases.(fields{f}) = segments;
    end
end

% Example input data
avg_keypoints.CAM1 = array2table(rand(100, 4), 'VariableNames', {'Keypoint1_x', 'Keypoint1_y', 'Keypoint2_x', 'Keypoint2_y'});
avg_keypoints.CAM2 = array2table(rand(100, 4), 'VariableNames', {'Keypoint1_x', 'Keypoint1_y', 'Keypoint2_x', 'Keypoint2_y'});

% Threshold for determining a new position
threshold_px = 0.5;

% Call the function
[quantized_keypoints, transition_phases] = quantize_levels_t(avg_keypoints, threshold_px);

% Display results for CAM1
disp(quantized_keypoints.CAM1(1:10, :));
disp(transition_phases.CAM1(1:10));