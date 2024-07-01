function trim_nsx_by_triggers()
    % TRIM_NSX_BY_TRIGGERS Trims an ns6 neural data file based on camera triggers
    % found in a corresponding ns5 file, keeping only the data between the first and
    % last triggers.
    %
    % This function:
    % 1. Prompts the user to select processing mode: interactive or automatic.
    % 2. Prompts the user to select the ECoG data directory containing the ns5 and ns6 files.
    % 3. In interactive mode, prompts the user to confirm each ns6 file before processing.
    % 4. In automatic mode, processes all ns6 files without user confirmation.
    % 5. Identifies the corresponding ns5 file for each ns6 file.
    % 6. Uses the ns5 file to find the first and last camera triggers.
    % 7. Trims the ns6 data based on the first and last camera triggers.
    % 8. Saves the trimmed data segment to a .mat file in a newly created output directory.
    % 9. Displays a summary of processed and skipped files in automatic mode.

    % Prompt user for interactive or automatic mode
    choice = questdlg('Choose processing mode:', ...
        'Mode Selection', ...
        'Interactive', 'Automatic', 'Cancel', 'Interactive');
    if strcmp(choice, 'Cancel')
        return;
    end
    interactiveMode = strcmp(choice, 'Interactive');
    
    % Prompt the user to select the ECoG data directory
    ecogDataDir = uigetdir(pwd, 'Select the ECoG data directory');
    if ecogDataDir == 0
        disp('User canceled the directory selection');
        return;
    end

    % Get list of ns6 files
    ns6Files = dir(fullfile(ecogDataDir, '*.ns6'));

    if interactiveMode
        % Interactive mode: process files with user confirmation
        for i = 1:length(ns6Files)
            ns6File = ns6Files(i).name;
            % Find the corresponding ns5 file
            ns5Pattern = strrep(ns6File, '.ns6', '.ns5');
            ns5File = dir(fullfile(ecogDataDir, ns5Pattern));
            if isempty(ns5File)
                disp(['Skipping: No corresponding ns5 file found for ', ns6File]);
                continue;
            end

            % Confirm with user
            response = questdlg(sprintf('ns5: %s\nns6: %s', ns5File.name, ns6File), ...
                'Confirm File', ...
                'OK', 'Skip', 'OK');
            if strcmp(response, 'Skip')
                continue;
            end
            
            % Process the files
            process_nsx_files(ns6File, ns5File.name, ecogDataDir, outputDir);
        end
    else
        % Automatic mode: process all files without confirmation
        skippedFiles = {};
        processedCount = 0;
        tic; % Start timer
        
        for i = 1:length(ns6Files)
            ns6File = ns6Files(i).name;
            % Find the corresponding ns5 file
            ns5Pattern = strrep(ns6File, '.ns6', '.ns5');
            ns5File = dir(fullfile(ecogDataDir, ns5Pattern));
            if isempty(ns5File)
                skippedFiles{end+1} = ns6File; %#ok<AGROW>
                continue;
            end
            
            % Process the files
            process_nsx_files(ns6File, ns5File.name, ecogDataDir, outputDir);
            processedCount = processedCount + 1;
        end
        
        % Display summary
        elapsedTime = toc;
        msgbox(sprintf('Processed: %d\nSkipped: %d\nElapsed Time: %.2f seconds', ...
            processedCount, length(skippedFiles), elapsedTime), ...
            'Summary');
    end
end

function process_nsx_files(ns6File, ns5File, ecogDataDir, saveDirParent)
    % PROCESS_NSX_FILES Processes and trims the ns6 file based on camera triggers
    % found in the ns5 file.
    %
    % This function:
    % 1. Loads the ns5 file to find the first and last camera triggers.
    % 2. Uses these triggers to determine the trimming range for the ns6 file.
    % 3. Loads the ns6 file and trims it based on the determined range.
    % 4. Saves the trimmed data segment to a .mat file in a newly created output directory.
    
    % Load the ns5 file and find the camera triggers
    ns5Data = openNSxCervical(fullfile(ecogDataDir, ns5File));
    ns5SampleRate = ns5Data.MetaTags.SamplingFreq;
    cameraTrigs = find(diff(ns5Data.Data(5, :)) > 50) + 1;
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
    
    startSample = startTrigger * ns6SampleRate / ns5SampleRate;
    endSample = endTrigger * ns6SampleRate / ns5SampleRate;
    
    % Trim the ns6 data
    trimmedData = ns6Data.Data(:, startSample:endSample);
    
    % Create the save directory
    [~, name, ~] = fileparts(ns6File);
    saveDir = fullfile(saveDirParent, name);
    if ~exist(saveDir, 'dir')
        mkdir(saveDir);
    end
    
    % Save the trimmed data
    saveFileName = fullfile(saveDir, sprintf('%s_trimmed.mat', name));
    save(saveFileName, 'trimmedData', '-v7.3');
    
    disp(['Saved trimmed data to ', saveFileName]);
end