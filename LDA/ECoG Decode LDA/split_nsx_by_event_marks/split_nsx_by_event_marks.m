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

% Prompt the user to select the Events data directory
eventsDataDir = uigetdir(pwd, 'Select the Events data directory');
if eventsDataDir == 0
    disp('User canceled the directory selection');
    return;
end
addpath(eventsDataDir);

% Construct the save directory
outputDir = fullfile(fileparts(ecogDataDir), 'outputDir');
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% Load the NatalyaElecMap
load NatalyaElecMap
plotDiagnostics = 'true';

% Prompt the user to select the event file
[eventFile, eventPath] = uigetfile(fullfile(eventsDataDir, '*.mat'), 'Select the event file');
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

% Construct the corresponding ns5 file name pattern
ns5Pattern = sprintf('%s_%s_%s_%s.ns5', subject, date, trialType, trialNumber);

% Find the corresponding ns5 file
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

% Load events
fs_simi = 100;
tmpTriggers = load(fullfile(eventPath, eventFile));
events = tmpTriggers.event;

% Combine all event types into one array with their names
eventNames = fieldnames(events);
allEvents = [];
eventList = [];
for i = 1:length(eventNames)
    eventFrames = events.(eventNames{i});
    allEvents = [allEvents, eventFrames];
    eventList = [eventList, repmat({eventNames{i}}, 1, length(eventFrames))];
end

% Load the ns5 data and find the camera trigger
triggerFile = fullfile(ecogDataDir, ns5FileMatch);
ns5Data = openNSxCervical(triggerFile);
H.ns5SampleRate = ns5Data.MetaTags.SamplingFreq;
disp(['Loading NS5 file ' ns5FileMatch])

cameraTrig = find(diff(ns5Data.Data(H.ns5VideoCh,:)) > H.ns5VideoThres, 1) + 1;
clear ns5Data

% Load the ECoG data and cut files at event locations
fpath = fullfile(ecogDataDir, ns6FileMatch);
ns6Data = openNSxCervical(fpath);
disp(['Loading NS6 file ' ns6FileMatch])

% Calculate sample rate conversion and adjust for camera trigger
ns6SampleRate = ns6Data.MetaTags.SamplingFreq;
cameraTrigSample = cameraTrig * ns6SampleRate / H.ns5SampleRate;

% Map event frames to ns6 samples
eventSamples = cameraTrigSample + (allEvents * ns6SampleRate / fs_simi);

% Sort the event samples and corresponding names
[eventSamples, sortIdx] = sort(eventSamples);
sortedEventNames = eventList(sortIdx);

% Cut the file at event locations and save segments
for i = 1:length(eventSamples) - 1
    startSample = eventSamples(i);
    endSample = eventSamples(i + 1);
    startEvent = sortedEventNames{i};
    endEvent = sortedEventNames{i + 1};

    % Skip junk events
    if strcmp(startEvent, 'ST_JNK') || strcmp(endEvent, 'END_JNK')
        continue;
    end

    % Extract data segment
    dataSegment = ns6Data.Data(:, startSample:endSample);

    % Save data segment
    saveFileName = sprintf('%s_%s_%d_%s_%d.mat', ns6FileMatch(1:end-4), startEvent, startSample, endEvent, endSample);
    save(fullfile(outputDir, saveFileName), 'dataSegment', '-v7.3');
end

% Copy the event file to the save directory
copyfile(fullfile(eventPath, eventFile), fullfile(outputDir, eventFile));

clear ns6Data

disp('Finished processing and cutting ns6 files.')