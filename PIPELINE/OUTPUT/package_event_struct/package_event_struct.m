function [packaged_event_struct_path, packaged_event_struct_name] = package_event_struct(trialDir)
    
    % Include helper functions for processing Blackrock Data
    addpath("../../POSTPROCESSING/LDA/ECoG Decode LDA/Functions/");

    % Load ns6 data from struct stored in trial folder
    [~, trialName, ~] = fileparts(trialDir);
    ns6Name = sprintf("%s_NSX.mat", trialName);
    ns6Data = load(ns6Name); % ns6 data from struct

    % Initialize the new structure
    events = struct;
    
    % Populate the MetaTags field
    events.MetaTags.syncInfo.start = oldStruct.metadata.triggers([1, 3]);
    events.MetaTags.syncInfo.end = oldStruct.metadata.triggers([2, 4]);
    events.MetaTags.videoFrameRate = oldStruct.metadata.frameRate;
    events.MetaTags.ecogSamplingRate = oldStruct.metadata.samplingRate;
    
    % Populate the EventsInfo field
    events.EventsInfo(1).Name = 'ST_RCH';
    events.EventsInfo(1).Description = 'Start of reaching';
    events.EventsInfo(2).Name = 'HND_AT_OBJ';
    events.EventsInfo(2).Description = 'Hand at object';    
    events.EventsInfo(3).Name = 'ST_PULL';
    events.EventsInfo(3).Description = 'Start of pulling';
    events.EventsInfo(4).Name = 'END_PULL';
    events.EventsInfo(4).Description = 'End of pulling';
    events.EventsInfo(5).Name = 'END_RLS';
    events.EventsInfo(5).Description = 'End of release';
    events.EventsInfo(6).Name = 'ST_HND_TO_MTH';
    events.EventsInfo(6).Description = 'Start of hand to mouth movement';
    events.EventsInfo(7).Name = 'END_HND_TO_MTH';
    events.EventsInfo(7).Description = 'End of hand to mouth movement';
    events.EventsInfo(8).Name = 'ST_JNK';
    events.EventsInfo(8).Description = 'Start of junk event';
    events.EventsInfo(9).Name = 'END_JNK';
    events.EventsInfo(9).Description = 'End of junk event';
    events.EventsInfo(10).Name = 'OTHER';
    events.EventsInfo(10).Description = 'Other events';
    
    % Transfer the event data
    eventFields = {'ST_RCH', 'ST_PULL', 'END_HND_TO_MTH', 'END_JNK', 'END_PULL', ...
                    'END_RLS', 'HND_AT_OBJ', 'OTHER', 'ST_HND_TO_MTH', 'ST_JNK'};
    
    for i = 1:length(eventFields)
        if isfield(oldStruct, eventFields{i})
            events.Marks.(eventFields{i}) = oldStruct.(eventFields{i});
        end
    end

end