%{ EXAMPLE POSE DATA
scorer,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000
bodyparts,thumb_tip,thumb_tip,thumb_tip,index_tip,index_tip,index_tip,wrist,wrist,wrist,forearm,forearm,forearm,elbow,elbow,elbow,keypoint1,keypoint1,keypoint1,keypoint2,keypoint2,keypoint2
coords,x,y,likelihood,x,y,likelihood,x,y,likelihood,x,y,likelihood,x,y,likelihood,x,y,likelihood,x,y,likelihood
0,713.8554077148438,158.6163787841797,0.4786283075809479,719.4327392578125,157.8507843017578,0.9917176961898804,700.311767578125,170.4683074951172,0.9995953440666199,669.9605712890625,179.5712890625,0.9993858337402344,641.9354858398438,191.74136352539062,0.8703688383102417,623.88037109375,182.67300415039062,0.3274724781513214,607.2002563476562,174.89031982421875,0.20065924525260925
1,713.4447021484375,159.03353881835938,0.47246891260147095,719.332275390625,158.02999877929688,0.9902263879776001,700.046630859375,170.7549591064453,0.9994301199913025,669.8108520507812,179.77008056640625,0.9992573857307434,641.5614624023438,192.0361328125,0.8451208472251892,622.854736328125,181.7891082763672,0.28540652990341187,607.3789672851562,175.2157745361328,0.21796545386314392
%}


function process_keypoint_markers(trialDir)
    % PROCESS_KEYPOINT_MARKERS   Function to process tracked keypoints in a trial directory
    % trialDir: Directory containing folders for each camera angle during a
    % single trial. Typically 8 Camera Angles

    folderPath = trialDir; % Set the folder path to the trial directory
    camFolders = dir(fullfile(folderPath, '*.csv')); % List all items in the directory
    
    % Iterate over each camera folder
    for i = 1:length(camFolders)
        % Load the pose CSV file from camera folder
        poseData = readtable(fullfile(folderPath, camFolders(i).name));

        % Identify columns corresponding to bodyparts named "keypoint%d"
        keypointCols = contains(poseData.Properties.VariableNames, 'keypoint');
        keypointData = poseData(:, keypointCols);

        % Clear whole table from workspace to continue only working with keypoints columns
        clear poseData;

        % Perform moving average on each column with configurable window size set by variable indicating number of frames
        windowSize = 5; % Example window size, modify as needed
        for col = 1:width(keypointData)
            keypointData{:, col} = movmean(keypointData{:, col}, windowSize);
        end

        % 3D plot the averaged data, making one plot per bodypart
        bodyparts = unique(erase(keypointData.Properties.VariableNames, {'_x', '_y', '_likelihood'}));
        for bp = 1:length(bodyparts)
            % Extract x and y coordinates
            xData = keypointData{:, contains(keypointData.Properties.VariableNames, [bodyparts{bp}, '_x'])};
            yData = keypointData{:, contains(keypointData.Properties.VariableNames, [bodyparts{bp}, '_y'])};

            % Create 3D plot
            figure;
            plot3(1:length(xData), xData, yData);
            title(['3D plot for ', bodyparts{bp}]);
            xlabel('Frame');
            ylabel('X Coordinate');
            zlabel('Y Coordinate');
            grid on;
        end

        % Export as projections.csv to the camera folder with one line of headers indicating the bodypart name followed by x or y, excluding likelihoods
        projectionsTable = keypointData(:, ~contains(keypointData.Properties.VariableNames, 'likelihood'));
        % Adjust the headers to follow the desired format
        newHeaders = regexprep(projectionsTable.Properties.VariableNames, {'_x', '_y'}, {'_x', '_y'});
        projectionsTable.Properties.VariableNames = newHeaders;
        writetable(projectionsTable, fullfile(folderPath, camFolders(i).name, 'projections.csv'));
    end
end