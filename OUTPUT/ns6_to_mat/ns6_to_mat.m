function ns6_to_mat()
    % NS6_TO_MAT Processes NS6 files by loading them and saving them to .mat files
    % This function:
    % 1. Prompts the user to select processing mode: interactive or automatic.
    % 2. Prompts the user to select the ECoG data directory containing the NS6 files.
    % 3. In interactive mode, prompts the user to confirm each NS6 file before processing.
    % 4. In automatic mode, processes all NS6 files without user confirmation.
    % 5. Loads each NS6 file.
    % 6. Saves the loaded data to a .mat file in a newly created output directory.

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

    % Get list of NS6 files
    ns6Files = dir(fullfile(ecogDataDir, '*.ns6'));

    if interactiveMode
        % Interactive mode: process files with user confirmation
        for i = 1:length(ns6Files)
            ns6File = ns6Files(i).name;
            
            % Confirm with user
            response = questdlg(sprintf('NS6 file: %s', ns6File), ...
                'Confirm File', ...
                'OK', 'Skip', 'OK');
            if strcmp(response, 'Skip')
                continue;
            end
            
            % Process the file
            process_ns6_file(ns6File, ecogDataDir);
        end
    else
        % Automatic mode: process all files without confirmation
        processedCount = 0;
        skippedFiles = {};
        tic; % Start timer
        
        for i = 1:length(ns6Files)
            ns6File = ns6Files(i).name;
            
            % Process the file
            try
                process_ns6_file(ns6File, ecogDataDir);
                processedCount = processedCount + 1;
            catch
                skippedFiles{end+1} = ns6File; %#ok<AGROW>
            end
        end
        
        % Display summary
        elapsedTime = toc;
        msgbox(sprintf('Processed: %d\nSkipped: %d\nElapsed Time: %.2f seconds', ...
            processedCount, length(skippedFiles), elapsedTime), ...
            'Summary');
    end
end

function process_ns6_file(ns6File, ecogDataDir)
    % PROCESS_NS6_FILE Loads an NS6 file and saves it to a .mat file
    %
    % Parameters:
    % - ns6File: Name of the NS6 file to be processed.
    % - ecogDataDir: Directory containing the ECoG data files.
    %
    % This function:
    % 1. Loads the NS6 file.
    % 2. Saves the loaded data to a .mat file in a newly created output directory.

    % Load the NS6 file
    ns6Data = openNSxCervical(fullfile(ecogDataDir, ns6File));
    
    % Create the save directory
    [~, name, ~] = fileparts(ns6File);
    saveDir = fullfile(ecogDataDir, 'Processed', name);
    if ~exist(saveDir, 'dir')
        mkdir(saveDir);
    end
    
    % Split the file name by underscores
    parts = strsplit(name, '_');
    
    % Construct the new file name
    if length(parts) >= 4
        newFileName = sprintf('%s_%s_%s_ECoG.mat', parts{1}, parts{2}, parts{end});
    else
        error('Unexpected file name format: %s', name);
    end
    
    % Save the loaded data
    saveFileName = fullfile(saveDir, newFileName);
    save(saveFileName, 'ns6Data', '-v7.3');
    
    disp(['Saved data to ', saveFileName]);
end