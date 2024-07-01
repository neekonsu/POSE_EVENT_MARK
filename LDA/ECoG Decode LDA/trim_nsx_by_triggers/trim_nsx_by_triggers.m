function trim_nsx_by_triggers()
    % TRIM_NSX_BY_TRIGGERS Trims an ns6 neural data file based on camera trigger events
    % found in a corresponding ns5 file.
    %
    % This function:
    % 1. Prompts the user to select necessary directories and files.
    % 2. Calculates the start and end sample points from the camera triggers.
    % 3. Trims the ns6 data to include only the relevant samples.
    % 4. Saves the trimmed data along with the event file to a new output directory.
    %
    % Steps:
    % 1. Prompt the user to select the directory containing supplemental functions
    %    and add this directory to the MATLAB path.
    % 2. Prompt the user to select the ECoG data directory and add it to the MATLAB path.
    % 3. Prompt the user to select a parent directory where the processed files 
    %    will be saved.
    % 4. Load the NatalyaElecMap and set the diagnostic plotting option.
    % 5. Prompt the user to select an event file and extract the subject, date,
    %    trial type, and trial number from the file name using a regular expression.
    % 6. Construct the output directory name from the extracted details and create 
    %    the new output directory within the selected parent directory.
    % 7. Construct patterns to find the corresponding ns6 and ns5 files based on 
    %    the extracted details, and search for these files in the ECoG data directory.
    % 8. Load the ns5 file and identify the starting and ending camera triggers.
    % 9. Load the ns6 data file and calculate the corresponding sample indices for 
    %    the camera triggers in the ns6 data using the sample rate conversion.
    % 10. Trim the ns6 data to the sample range defined by the camera triggers.
    % 11. Save the trimmed ns6 data to a .mat file in the new output directory.
    % 12. Copy the selected event file to the output directory for reference.
    % 13. Clear loaded data from memory and display a completion message.

    % Prompt user to select supplemental function dir to add to path
    functionPath = uigetdir(pwd, 'Select the directory containing the required functions');
    if functionPath == 0
        disp('User canceled the directory selection');
        return;
    end
    addpath(functionPath);

    % Prompt the user to select the ECoG data directory
    ecogDataDir = uigetdir(pwd, 'Select the ECoG data directory');
    if ecogDataDir == 0
        disp('User canceled the directory selection');
        return;
    end
    addpath(ecogDataDir);

    % Prompt the user to select the save directory
    saveDirParent = uigetdir(pwd, 'Select the parent directory to save the processed files');
    if saveDirParent == 0
        disp('User canceled the directory selection');
        return;
    end

    % Prompt the user to select the event file
    [eventFile, eventPath] = uigetfile(fullfile(pwd, '*.mat'), 'Select the event file');
    if isequal(eventFile, 0)
        disp('User canceled the event file selection');
        return;
    end

    % Extract the subject, date, trial type, and trial number from the event file name
    eventPattern = '(\w+)_(\d+)_(\w+)_(\d+)-.*_events.mat';
    tokens = regexp(eventFile, eventPattern, 'tokens');
    if isempty(tokens)
        error('Event file name does not match the expected pattern');
    end
    subject = tokens{1}{1};
    date = tokens{1}{2};
    trialType = tokens{1}{3};
    trialNumber = tokens{1}{4};

    % Construct the output directory name from the extracted tokens
    outputDir = sprintf("%s_%s_%s_%s_dataset", subject, date, trialType, trialNumber);

    % Create the new save directory in the parent directory
    saveDir = fullfile(saveDirParent, outputDir);
    if ~exist(saveDir, 'dir')
        mkdir(saveDir);
    end

    % Construct the corresponding ns6 file name pattern
    ns6Pattern = sprintf('%s_%s_%s_%s.ns6', subject, date, trialType, trialNumber);

    % Find the corresponding ns6 file
    ns6Files = dir(fullfile(ecogDataDir, '*.ns6'));
    ns6FileMatch = '';
    for i = 1:length(ns6Files)
        if contains(ns6Files(i).name, ns6Pattern)
            ns6FileMatch = ns6Files(i).name;
            break;
        end
    end

    if isempty(ns6FileMatch)
        error('No corresponding ns6 file found');
    end

    % Find and load the corresponding ns5 file for camera trigger
    ns5Pattern = sprintf('%s_%s_%s_%s.ns5', subject, date, trialType, trialNumber);
    ns5Files = dir(fullfile(ecogDataDir, '*.ns5'));
    ns5FileMatch = '';
    for i = 1:length(ns5Files)
        if contains(ns5Files(i).name, ns5Pattern)
            ns5FileMatch = ns5Files(i).name;
            break;
        end
    end

    if isempty(ns5FileMatch)
        error('No corresponding ns5 file found');
    end

    % Load the ns5 file and find the camera triggers
    ns5Data = openNSxCervical(fullfile(ecogDataDir, ns5FileMatch));
    H.ns5SampleRate = ns5Data.MetaTags.SamplingFreq;
    cameraTrigStart = find(diff(ns5Data.Data(H.ns5VideoCh, :)) > H.ns5VideoThres, 1) + 1;
    cameraTrigEnd = find(diff(ns5Data.Data(H.ns5VideoCh, :)) > H.ns5VideoThres, 1, 'last') + 1;
    clear ns5Data

    % Load the ns6 data
    fpath = fullfile(ecogDataDir, ns6FileMatch);
    ns6Data = openNSxCervical(fpath);
    disp(['Loading NS6 file ' ns6FileMatch])

    % Calculate the sample indices for the camera triggers in the ns6 data
    ns6SampleRate = ns6Data.MetaTags.SamplingFreq;
    startSample = cameraTrigStart * ns6SampleRate / H.ns5SampleRate;
    endSample = cameraTrigEnd * ns6SampleRate / H.ns5SampleRate;

    % Trim the ns6 data to the sample range
    trimmedData = ns6Data.Data(:, startSample:endSample);

    % Save the trimmed ns6 data
    saveFileName = sprintf('%s_trimmed_%d_%d.mat', ns6FileMatch(1:end-4), startSample, endSample);
    save(fullfile(saveDir, saveFileName), 'trimmedData', '-v7.3');

    % Copy the event file to the save directory
    copyfile(fullfile(eventPath, eventFile), saveDir);

    clear ns6Data

    disp('Finished processing and trimming ns6 files.')
end