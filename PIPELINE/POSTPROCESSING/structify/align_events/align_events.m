function align_events()
    % align_events
    % 
    % This function aligns events from ECoG data with corresponding video data by
    % processing NS5 and NS6 files to extract sample information and updating an
    % event (EVT) structure with these sample timings. The user is prompted to 
    % select the ECoG data directory, the EVT file, and the NS6 file. The corresponding
    % NS5 file is located automatically. The function then processes these files
    % to calculate start and end samples and updates the EVT struct with new fields
    % and metadata before saving the updated struct to a user-specified location.
    %
    % The steps include:
    % 1. Prompt the user to select the ECoG data directory.
    % 2. Prompt the user to select the EVT file.
    % 3. Prompt the user to select the NS6 file and find the corresponding NS5 file.
    % 4. Call process_nsx_files to extract start and end sample information.
    % 5. Load the EVT struct and update its fields with aligned sample data.
    % 6. Add metadata to the EVT struct.
    % 7. Prompt the user to select a save location and save the updated struct.
    
    addpath('../../../POSTPROCESSING/LDA/ECoG Decode LDA/Functions');

    % Prompt the user to select the ECoG data directory
    ecogDataDir = uigetdir(pwd, 'Select the ECoG data directory');
    if ecogDataDir == 0
        disp('User canceled the directory selection');
        return;
    end

    % Prompt the user to select the EVT file
    [evtFile, evtPath] = uigetfile('*.mat', 'Select the EVT File');
    if isequal(evtFile, 0)
        disp('User canceled the file selection');
        return;
    end

    % Prompt the user to select the ns6 file
    [ns6File, ns6Path] = uigetfile('*.ns6', 'Select the NS6 File');
    if isequal(ns6File, 0)
        disp('User canceled the file selection');
        return;
    end

    % Find the corresponding ns5 file using the ns6 file's name
    ns5File = strrep(ns6File, '.ns6', '.ns5');
    ns5Path = fullfile(ns6Path, ns5File);
    if ~isfile(ns5Path)
        disp(['No corresponding ns5 file found for ', ns6File]);
        return;
    end

    % Call process_nsx_files to extract information from those files
    trigger_threshold = 50;  % Example threshold, adjust as needed
    [simi_start_sample, simi_end_sample, sample_rate] = process_nsx_files(ns6File, ns5File, ecogDataDir, trigger_threshold);

    % Load the struct stored in evtFile
    data = load(fullfile(evtPath, evtFile));
    evtStruct = data.('dataEvent');
    framerate = 100;  % Example framerate, adjust as needed

    % Process each field in the struct
    fields = fieldnames(evtStruct);
    for i = 1:numel(fields)
        fieldValue = evtStruct.(fields{i});
        if isnumeric(fieldValue) && isvector(fieldValue)
            % Turn each double array into an n x 2 matrix
            n = numel(fieldValue);
            newArray = zeros(n, 2);
            newArray(:, 1) = fieldValue;
            newArray(:, 2) = (fieldValue * (sample_rate / framerate)) + simi_start_sample;
            evtStruct.(fields{i}) = newArray;
        end
    end

    % Store a new field titled metadata
    evtStruct.metadata.triggers = [1, simi_start_sample; round((simi_end_sample - simi_start_sample) * framerate / sample_rate), simi_end_sample];
    evtStruct.metadata.samplingRate = sample_rate;
    evtStruct.metadata.frameRate = framerate;

    % Prompt the user to select a save directory
    saveDir = uigetdir('', 'Select a directory to save the updated struct');
    if saveDir ~= 0
        % Save the updated struct
        save(fullfile(saveDir, ['updated_' evtFile]), '-struct', 'evtStruct');
        disp('Updated struct saved successfully.');
    else
        disp('User canceled the directory selection');
    end
end

function [simi_start_sample, simi_end_sample, sample_rate] = process_nsx_files(ns6File, ns5File, ecogDataDir, trigger_threshold)
    % process_nsx_files
    %
    % This function processes NS5 and NS6 files to extract camera trigger information
    % and calculates the corresponding start and end samples in the NS6 file. This 
    % information is used to align ECoG data with video data.
    %
    % Parameters:
    % - ns6File: Name of the NS6 file to be processed.
    % - ns5File: Name of the NS5 file containing camera triggers.
    % - ecogDataDir: Directory containing the ECoG data files.
    % - trigger_threshold: Threshold value for detecting camera triggers in the NS5 file.
    %
    % Returns:
    % - simi_start_sample: Start sample in the NS6 file corresponding to the first camera trigger.
    % - simi_end_sample: End sample in the NS6 file corresponding to the last camera trigger.
    % - sample_rate: Sampling rate of the NS6 file.
    %
    % The function performs the following steps:
    % 1. Load the NS5 file and identify camera trigger points based on the specified threshold.
    % 2. Calculate the start and end trigger points in the NS5 file.
    % 3. Load the NS6 file and compute the corresponding start and end samples based on the NS5 trigger points.
    % 4. Return the calculated start sample, end sample, and sample rate of the NS6 file.


    % Load the ns5 file and find the camera triggers
    ns5Data = openNSxCervical(fullfile(ecogDataDir, ns5File));
    ns5SampleRate = ns5Data.MetaTags.SamplingFreq;
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
    ns6Data = openNSxCervical(fullfile(ecogDataDir, ns6File));
    ns6SampleRate = ns6Data.MetaTags.SamplingFreq;
    
    % Return values
    simi_start_sample = startTrigger * ns6SampleRate / ns5SampleRate;
    simi_end_sample = endTrigger * ns6SampleRate / ns5SampleRate;
    sample_rate = ns6SampleRate;
end