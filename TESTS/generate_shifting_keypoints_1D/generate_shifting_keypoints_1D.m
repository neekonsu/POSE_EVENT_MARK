function output_signal = generate_shifting_keypoints_1D()
    % GENERATE_SHIFTING_KEYPOINTS
    
    % Parameters
    signal_length = 1000; % Length of the signal
    num_levels = 5; % Number of discrete levels
    min_segment_length = round(0.2 * signal_length); % Minimum length of each level (20% of the signal length)
    max_segment_length = round(0.4 * signal_length); % Maximum length of each level
    baseline_offset = 100; % Baseline offset
    max_variation = 0.1; % Maximum variation of 10%
    max_transition_length = 10; % Maximum length of transitions
    noise_amplitude = 2; % Amplitude of the noise to be added
    
    % Generate initial random levels around the baseline
    levels = baseline_offset + randn(1, num_levels) * 10; % Random levels around the baseline
    
    % Ensure levels adhere to the max_variation constraint
    for i = 2:num_levels
        max_level_variation = levels(i-1) * max_variation;
        levels(i) = levels(i-1) + sign(randn) * min(max_level_variation, abs(randn * 10));
    end
    
    % Initialize the signal
    signal = zeros(1, signal_length);
    
    % Generate the signal with segments of random lengths
    current_position = 1;
    while current_position <= signal_length
        % Determine the length of the next segment
        segment_length = randi([min_segment_length, max_segment_length]);
        if current_position + segment_length > signal_length
            segment_length = signal_length - current_position + 1;
        end
        
        % Determine the level of the next segment
        level_index = randi([1, num_levels]);
        level_value = levels(level_index);
        
        % Determine the transition length
        transition_length = randi([1, max_transition_length]);
        
        % Set the segment in the signal with transition
        if current_position == 1
            signal(current_position:current_position + segment_length - 1) = level_value;
        else
            previous_level = signal(current_position - 1);
            for t = 1:transition_length
                if current_position + t - 1 > signal_length
                    break;
                end
                signal(current_position + t - 1) = previous_level + (level_value - previous_level) * (t / transition_length);
            end
            if current_position + transition_length <= signal_length
                signal(current_position + transition_length:current_position + segment_length - 1) = level_value;
            end
        end
        
        % Move to the next position
        current_position = current_position + segment_length;
    end
    
    % Ensure transitions adhere to max_variation constraint
    for i = 2:length(signal)
        max_level_variation = signal(i-1) * max_variation;
        signal(i) = signal(i-1) + sign(signal(i) - signal(i-1)) * min(max_level_variation, abs(signal(i) - signal(i-1)));
    end
    
    % Add small signal noise
    noise = noise_amplitude * randn(1, signal_length);
    signal_with_noise = signal + noise;
    
    % Plot the signal
    figure;
    plot(signal_with_noise, 'LineWidth', 2);
    title('Random Discrete Levels Signal with Baseline Offset, Limited Variation, Smooth Transitions, and Noise');
    xlabel('Sample Index');
    ylabel('Amplitude');
    grid on;
    ylim([0, max(signal_with_noise) + 10]); % Ensure y-axis starts from zero    
end