function split_nsx_by_event_marks()
    % SPLIT_NSX_BY_EVENT_MARKS Splits an ns6 neural data file based on event marks
    % found in a corresponding events file, excluding junk data.
    %
    % This function:
    % 1. Prompts the user to select necessary directories and files.
    % 2. Identifies the corresponding ns6 and ns5 files based on the selected event file.
    % 3. Uses the ns5 file to locate camera triggers to align the event data.
    % 4. Maps event frames to sample points in the ns6 data.
    % 5. Trims the ns6 data based on the event marks, excluding specified junk data regions.
    % 6. Saves each trimmed data segment to a .mat file in a newly created output directory.
    % 7. Copies the original events file to the output directory for reference.

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
    
    % Load the ns5 file and find the camera trigger
    ns5Data = openNSxCervical(fullfile(ecogDataDir, ns5FileMatch));
    ns5SampleRate = ns5Data.MetaTags.SamplingFreq;
    cameraTrig = find(diff(ns5Data.Data(5, :)) > 50, 1) + 1;
    clear ns5Data
    
    % Parameters
    targetSampleRate = 2000;
    
    % Load events
    fs_simi = 100;
    tmpTriggers = load(fullfile(eventPath, eventFile));
    events = tmpTriggers.event;
    
    % Combine all event types into one array
    eventList = fieldnames(events);
    allEvents = [];
    for i = 1:length(eventList)
        allEvents = [allEvents, events.(eventList{i})];
    end
    
    % Map frame 0 (event data) to the sample in the ns6 data using camera trigger
    eventSamples = (allEvents + cameraTrig * targetSampleRate / ns5SampleRate) * targetSampleRate / fs_simi;
    
    % Sort the event samples and corresponding names
    [eventSamples, sortIdx] = sort(eventSamples);
    sortedEventNames = eventList(sortIdx);
    
    % Load the ECoG data and cut files at event locations
    fpath = fullfile(ecogDataDir, ns6FileMatch);
    ns6Data = openNSxCervical(fpath);
    disp(['Loading NS6 file ' ns6FileMatch])
    
    % Cut the file at event locations
    i = 1;
    while i <= length(eventSamples) - 1
        startSample = eventSamples(i);
        endSample = eventSamples(i + 1);
        
        % Skip junk data
        if strcmp(sortedEventNames{i}, 'ST_JNK') || strcmp(sortedEventNames{i + 1}, 'END_JNK')
            i = i + 2; % Skip the junk start and end events
            continue;
        end
        
        % Extract data segment
        dataSegment = ns6Data.Data(:, startSample:endSample);
        
        % Save data segment
        eventLabel = sprintf('%s%d_%s%d', sortedEventNames{i}, startSample, sortedEventNames{i + 1}, endSample);
        saveFileName = sprintf('%s_%s.mat', ns6FileMatch(1:end-4), eventLabel);
        save(fullfile(saveDir, saveFileName), 'dataSegment', '-v7.3');
        
        i = i + 1;
    end
    
    % Copy the event file to the save directory
    copyfile(fullfile(eventPath, eventFile), saveDir);
    
    clear ns6Data
    
    disp('Finished processing and cutting ns6 files.');
end