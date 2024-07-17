function blackrock_to_struct(trialDir)

    % Include helper functions for loading ns6
    addpath('../../POSTPROCESSING/LDA/ECoG Decode LDA/Functions/');

    % Construct filepath for Blackrock ECoG Files
    [~, trialName, ~] = fileparts(trialDir);
    ns6File = fullfile(trialDir, sprintf("%s.ns6", trialName));
    ns5File = fullfile(trialDir, sprintf("%s.ns5", trialName));

    % Load the NS6 file
    ns6Data = openNSxCervical(ns6File);

    % Load the ns5 file and find the camera triggers
    ns5Data = openNSxCervical(ns5File);
    cameraTrigs = find(diff(ns5Data.Data(5, :)) > trigger_threshold) + 1;
    if isempty(cameraTrigs)
        disp(['No camera triggers found in ', ns5File]);
        return;
    end
    
    % Determine the start and end triggers
    startTrigger = cameraTrigs(1);
    endTrigger = cameraTrigs(end);
    clear ns5Data
    
    % Load the ns6 file and determine the trimming range
    ns6SampleRate = ns6Data.MetaTags.SamplingFreq;
    ns5SampleRate = ns5Data.MetaTags.SamplingFreq;
    
    % Return values
    start_sample = startTrigger * ns6SampleRate / ns5SampleRate;
    end_sample = endTrigger * ns6SampleRate / ns5SampleRate;

    ns6Data.MetaTags.syncInfo.startSample = start_sample;
    ns6Data.MetaTags.syncInfo.endSample = end_sample;

    save(fullfile(trialDir, sprintf("%s_ecog", trialName), "ns6Data"));
    clear ns6Data
end