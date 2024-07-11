function trajectories = format_trj_struct(oldStruct)
    % FORMAT_TRJ_STRUCT Provided a struct exported by the old format of weighted_least_squares_triangulation
    % (Pre-Commit e4921c93f1cf737af3a31fe998f58fa53844ec9f)
    % Reformat the struct to the production format
    % Steps:
    % 1. Load old struct locally √
    % 2. Prompt user to select corresponding trial folder used for running OUTPUT/weighted_least_squares_triangulation() and 2D trajectory folder (exported trajectories from INPUT/DLC_to_simi_mat.m) √
    % 3. Extract a. session name b. experiment type c. trial number d. camera numbers from trial folder structure √
    % 4. Populate MetaTags and CamInfo with descriptive information √
    % 5. Match .mat files from 2D trajectory folder by video name, load trajectories to corresponding CamInfo(i)
    % 6. Populate trajectories field with 3D trajectory by bodypart
    % 7. Populate trackingPointsInfo.bodyparts and trackingPointsInfo.keypoints from step 6
    % weighted_least_squares_triangulation will be updated to implement this structure moving forward.

    %% STEP 1
    % Initialize the new structure
    trajectories = struct;


    %% STEP 2
    % Prompt user for trial folder
    trialDir = uigetdir('', 'Select a trial directory');
    % Prompt use for 2D trajectories folder
    dlcDir = uigetdir('', 'Select the DLC mat directory');

    % Add trial folder to path
    addpath(trialDir);
    % Add dlc folder to path
    addpath(dlcDir);


    %% STEP 3
    % Store the trialName
    [~, trialName, ~] = fileparts(trialDir);

    % Split the file name by underscores
    nameParts = strsplit(trialName, '_');

    % Extract Name Parts
    subjectName = nameParts{1};
    sessionDate = nameParts{2};
    experimentType = strjoin(nameParts{3:end-1}, '_');
    trialNumber = nameParts{end};

    % Map abbreviated Experiment Types to Descriptions
    experimentTypes = {"ARM", "ARM_BC", "ARM_PN", "SS"};
    experimentDescriptions = {"Small Sphere", "Big Cylinder", "Triangle Pinching", "Small Sphere"};
    experimentMap = dictionary(experimentTypes, experimentDescriptions);
    % Extract experiment description
    if experimentMap.isKey(experimentType)
        experimentDescription = experimentMap(experimentType);
    else
        error('Could not find associated experiment type in dictionary: %s', experimentType);
    end

    
    %% STEP 4
    % Assign extracted values to corresponding fields in MetaTags
    trajectories.MetaTags.subjectName = subjectName;
    trajectories.MetaTags.sessionDate = sessionDate;
    trajectories.MetaTags.experimentType = experimentType;
    trajectories.MetaTags.trialNumber = trialNumber;
    trajectories.MetaTags.experimentDescription = experimentDescription;
    % Populate the MetaTags field
    % Populate bodyparts list
    trajectories.MetaTags.trackingPointsInfo.bodyparts = {"thumb_tip","index_tip","wrist","forearm","elbow","upper_arm","shoulder"};
    % List Keypoints
    % keypoint 0: Right Enclosure Rear-Bottom Corner (origin for right-hand views)
    % keypoint 1-3: Basis points for right-hand views
    % keypoint 4: Left Enclosure Rear-Bottom Corner (origin for left-hand views)
    % keypoint 5-7: Basis points for left-hand views
    trajectories.MetaTags.trackingPointsInfo.keypoints = {"keypoint0", "keypoint1", "keypoint2", "keypoint3", "keypoint4", "keypoint5", "keypoint6", "keypoint7"};


    % Get list of camera folders
    camFolders = dir(fullfile(trialDir, '*'));
    % Filter entries for files (not directories) & directory navigation entires
    camFolders = camFolders([camFolders.isdir] & ~ismember({camFolders.name}, {'.', '..'}));
    % Get number of cameras
    numCams = length(camFolders);

    % Get files in folder
    dlcFiles = dir(fullfile(dlcDir, '*'));

    for cam = 1:numCams
        % Get current camera folder
        camFolder = camFolders(cam);

        % Get path for current camera folder and list contents
        camFolderPath = fullfile(trialDir, camFolder.name);
        camFiles = dir(camFolderPath);
        
        % Extract the camera number from the camera folder name
        camNum = regexp(camFolder.name, '\d+', 'match', 'once');

        % Construct Video Name
        videoName = sprintf("%s_%s_%s_%s-%s.avi", subjectName, sessionDate, experimentType, trialNumber, camNum);

        % Assign extracted values to corresponding fields in MetaTags
        trajectories.CamInfo(cam).CameraName = camFolder.name;
        trajectories.CamInfo(cam).VideoName  = videoName;

        %% STEP 5
        % Match name of dlc_to_simi_mat file by beginning containing video name
        dlcMatPattern = sprintf('^%s.*\\.mat$', videoName);
        % Filter files in camera folder by regexp
        dlcmatFile = dlcFiles(~cellfun('isempty', regexp(dlcFiles, dlcMatPattern)));
        % Check that there was a corresponding file, skip camera if missing
        if isempty(dlcmatFile)
            fprintf('No corresponding dlc 2D trajectory struct for %s, skipping video', videoName);
            trajectories.CamInfo(cam).Trajectories = "EMPTY";
            continue;
        end
        % Load 2D trajectory for current camera and assign to corresponding field in CamInfo(i)
        camTrajectories = load(dlcmatFile);
        trajectories.CamInfo(cam).Trajectories = camTrajectories;
    end

    [trajectoryFile, path] = uigetfile("*_TRJ.mat", "Select 3D Trajectories File");
    addpath(path);

    % Load Trajectory struct from file
    trajectoryStruct = load(trajectoryFile);
    % Assign Trajectory struct to new struct
    trajectories.Trajectories = trajectoryStruct;

    % Prompt the user to select a save directory
    saveDir = uigetdir('', 'Select a directory to save the output');

    if safeDir ~= 0
        % Save 'trajectories' to file
        save(fullfile(saveDir, [trialName, '_TRJ.mat']), 'trajectories');
        % Add path for mat_struct_summary.m
        addpath("../../PREPROCESSING/mat_struct_summary");
        % Allow user option to preview the newly created struct
        mat_struct_summary();
    else
        disp('User cancelled the directory selection');
    end
end