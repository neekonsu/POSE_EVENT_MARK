% %{ EXAMPLE POSE DATA
% scorer,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000,DLC_resnet50_UPPER_LIMB_PANCAMJun11shuffle1_1000000
% bodyparts,thumb_tip,thumb_tip,thumb_tip,index_tip,index_tip,index_tip,wrist,wrist,wrist,forearm,forearm,forearm,elbow,elbow,elbow,keypoint1,keypoint1,keypoint1,keypoint2,keypoint2,keypoint2
% coords,x,y,likelihood,x,y,likelihood,x,y,likelihood,x,y,likelihood,x,y,likelihood,x,y,likelihood,x,y,likelihood
% 0,713.8554077148438,158.6163787841797,0.4786283075809479,719.4327392578125,157.8507843017578,0.9917176961898804,700.311767578125,170.4683074951172,0.9995953440666199,669.9605712890625,179.5712890625,0.9993858337402344,641.9354858398438,191.74136352539062,0.8703688383102417,623.88037109375,182.67300415039062,0.3274724781513214,607.2002563476562,174.89031982421875,0.20065924525260925
% 1,713.4447021484375,159.03353881835938,0.47246891260147095,719.332275390625,158.02999877929688,0.9902263879776001,700.046630859375,170.7549591064453,0.9994301199913025,669.8108520507812,179.77008056640625,0.9992573857307434,641.5614624023438,192.0361328125,0.8451208472251892,622.854736328125,181.7891082763672,0.28540652990341187,607.3789672851562,175.2157745361328,0.21796545386314392
% %}

% Perform moving average on pose data from all cameras in trial folder:
trialDir = uigetdir("*", "Select Trial Folder To Process Keypoint Data")
[average_keypoints, ~] = moving_average(trialDir);

% Detect edges in average data and return data seaprated by quantized levels
[quantized_keypoints, transition_phases] = quantize_levels(average_keypoints, 10);

% Take processed data and write to files
for i:length(cols(transition_phases))
    writetable(quantized_keypoints, fullfile(trailDir, ['CAM', i], ['quantized_keypoints_', i, '.csv']));
    writetable(transition_phases, fullfile(trailDir, ['CAM', i], ['transition_phases_', i, '.csv']));
end