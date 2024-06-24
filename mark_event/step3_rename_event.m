close all
clear all
clc

event_dir = '/Users/ssq/Documents/EPFL/Device/SIMI/kinematics (Ggait)/Demo2/gaitevents';

all_files = dir([event_dir filesep '*.mat']);

numFiles = length(all_files);

for ii = 1:numFiles
    disp(['check ' all_files(ii).name])
    try
        load([event_dir filesep all_files(ii).name],'dataEvent')
        event = dataEvent;
        save([event_dir filesep all_files(ii).name],'event')
        disp('change dataEvent to event')
    catch
        load([event_dir filesep all_files(ii).name],'event')
        disp('gait event name is in correct format now')
    end
end