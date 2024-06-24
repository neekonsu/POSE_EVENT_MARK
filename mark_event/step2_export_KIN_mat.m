clc;
clear all;
close all;

filenm = 'JJ08_20240130_CORR_DOPA_002_KIN';

% Directory that holds the data from the session
dataDir = ['/Users/ssq/Documents/EPFL/Device/SIMI/mark_event'];

readKinVar = {'Left Crest', 'Left Hip', 'Left Knee', 'Left Ankle', 'Left Foot',...
           'Right Crest', 'Right Hip', 'Right Knee', 'Right Ankle', 'Right Foot',...
           };
header = {'LCrest','LHip','LKnee','LAnkle','LMTP',...
         'RCrest','RHip','RKnee','RAnkle','RMTP',...
           };

kinVar = {'leftCrest','leftTrochanterMajorGT','leftKneeJointK','leftMalleolusM','leftFifthMetatarsalMT',...
         'rightCrest','rightTrochanterMajorGT','rightKneeJointK','rightMalleolusM','rightFifthMetatarsalMT',...
           };
%%
close all
[~,~,KIN_3D] = loadSimi3DKinematics([dataDir filesep filenm '.txt'], readKinVar, kinVar);
for kv = 5%1:length(kinVar)
    figure
    plot(KIN_3D.(kinVar{kv}).z)
    title([filenm ' - ' readKinVar{kv}])
end
save([filenm '.mat'],'KIN_3D')
