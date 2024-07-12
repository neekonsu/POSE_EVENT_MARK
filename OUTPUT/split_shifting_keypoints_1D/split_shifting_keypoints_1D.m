function [estimated_signal, transition_times] = split_shifting_keypoints_1D(noisy_signal, threshold)
    % Parameters
    signal_length = length(noisy_signal);
    transition_times = [];
    
    % Smooth the signal using a moving average filter
    window_size = 50; % Adjust the window size as needed
    smoothed_signal = movmean(noisy_signal, window_size);
    
    % Initialize the estimated signal
    estimated_signal = zeros(1, signal_length);
    
    % Detect transitions based on threshold
    current_level = smoothed_signal(1);
    estimated_signal(1) = current_level;
    for i = 2:signal_length
        if abs(smoothed_signal(i) - current_level) > threshold
            transition_times = [transition_times, i];
            current_level = smoothed_signal(i);
        end
        estimated_signal(i) = current_level;
    end
    
    % Calculate the average value for each phase
    for j = 1:length(transition_times)-1
        start_idx = transition_times(j);
        end_idx = transition_times(j+1) - 1;
        average_value = mean(noisy_signal(start_idx:end_idx));
        estimated_signal(start_idx:end_idx) = average_value;
    end
    
    % Handle the last segment
    if ~isempty(transition_times)
        last_start_idx = transition_times(end);
        average_value = mean(noisy_signal(last_start_idx:end));
        estimated_signal(last_start_idx:end) = average_value;
    end
    
    % Plot the signals
    figure;
    plot(noisy_signal, 'LineWidth', 1, 'DisplayName', 'Noisy Signal');
    hold on;
    plot(estimated_signal, 'LineWidth', 2, 'DisplayName', 'Estimated Signal');
    title('Noisy Signal and Estimated Original Signal');
    xlabel('Sample Index');
    ylabel('Amplitude');
    legend;
    grid on;
    ylim([0, max(noisy_signal) + 10]); % Ensure y-axis starts from zero
end