% Example Usage

% Include generate_shifting_keypoints_1D
addpath("../../TESTS/generate_shifting_keypoints_1D");

% Generate the noisy signal using the provided function
[clean_signal, signal_with_noise] = generate_shifting_keypoints_1D();

% Use the function to approximate the original signal
threshold = 5; % Adjust the threshold as needed
[estimated_signal, transition_times] = split_shifting_keypoints_1D(signal_with_noise, threshold);

% Plot the stack of the original and estimated signals
figure;
subplot(3,1,1);
plot(clean_signal, 'LineWidth', 1);
title('Clean Signal');
xlabel('Sample Index');
ylabel('Amplitude');
grid on;
ylim([0, max(clean_signal) + 10]); % Ensure y-axis starts from zero

figure;
subplot(3,1,2);
plot(signal_with_noise, 'LineWidth', 1);
title('Noisy Signal');
xlabel('Sample Index');
ylabel('Amplitude');
grid on;
ylim([0, max(signal_with_noise) + 10]); % Ensure y-axis starts from zero

subplot(3,1,3);
plot(estimated_signal, 'LineWidth', 2);
title('Estimated Original Signal');
xlabel('Sample Index');
ylabel('Amplitude');
grid on;
ylim([0, max(signal_with_noise) + 10]); % Ensure y-axis starts from zero