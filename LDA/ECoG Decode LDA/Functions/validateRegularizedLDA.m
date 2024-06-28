function [ mutualInfo] = validateRegularizedLDA( triggersCuts_train,...
                                                 dataCuts_train,...
                                                 triggersCuts_test,...
                                                 dataCuts_test,...
                                                 param,...
                                                 saveDir)
%Decode the test data on the basis of the model built on trainning
%triggersCuts, trainning dataCuts and the optimized meta-parameters
% Use in conjuction with functions:
%       buildStepDetection
%       calcStepDetectionProbabilities
%       calcHeteroHistEdgesMulticlass
%       calcHeteroKardinalityMulticlass
%       calcMutInfoMulticlass_PriorNorm
% INPUT:
%   triggersCuts_train   - cell of data containing gait events in trainning cuts
%   dataCuts_train       - cell of data containing variables in trainning cuts
%   triggersCuts_test    - cell of data containing gait events in testing cuts
%   dataCuts_test        - cell of data containing variables in testing cuts
%   param                - structure containing parameters
% OUTPUT:
%   mutualInfo           - mutual information
%
% Shiqi Sun
% 19.10.2017

%% Making sure that the input cells have the proper size

assert(iscell(triggersCuts_train));
assert(iscell(dataCuts_train));
assert(length(triggersCuts_train) == length(dataCuts_train));
assert(iscell(triggersCuts_test));
assert(iscell(dataCuts_test));
assert(length(triggersCuts_test) == length(dataCuts_test));

%% Building the test model
model = buildStepDetection(dataCuts_train,triggersCuts_train,param);

% Enter estimation constants
estimatedStimDelay = param.estimatedStimDelay;
estimatedRfoAnticipation = param.estimatedRfoAnticipation;
estimatedRfsAnticipation = param.estimatedRfsAnticipation;
estimatedLfoAnticipation = param.estimatedLfoAnticipation;
estimatedLfsAnticipation = param.estimatedLfsAnticipation;

stimDelay_pts = estimatedStimDelay / 1000 * param.sampleRate;
rfsAnticipation_pts = estimatedRfsAnticipation / 1000 * param.sampleRate;
rfoAnticipation_pts = estimatedRfoAnticipation / 1000 * param.sampleRate;
lfsAnticipation_pts = estimatedLfsAnticipation / 1000 * param.sampleRate;
lfoAnticipation_pts = estimatedLfoAnticipation / 1000 * param.sampleRate;

% Decode probabilities
tolWin = param.tolWin;
detFootStrike = cell(length(dataCuts_test),1);
detFootOff = cell(length(dataCuts_test),1);
for cut = 1:length(dataCuts_test)
    [classProb,testInd] = calcStepDetectionProbabilities(dataCuts_test(cut),model,param.sampleRate);

    detThreshold = param.treshVal;
    rightFootStrikeInd = classProb(:,1) >= detThreshold;
    detFootStrike{cut} = testInd(find(diff(rightFootStrikeInd) == 1) + 1);
    closeDet = find(diff(detFootStrike{cut}) < param.sampleRate * param.refractorySec) + 1;
    detFootStrike{cut}(closeDet) = [];

    rightFootOffInd = classProb(:,2) >= detThreshold;
    detFootOff{cut} = testInd(find(diff(rightFootOffInd) == 1) + 1); 
    closeDet = find(diff(detFootOff{cut}) < param.sampleRate * param.refractorySec) + 1;
    detFootOff{cut}(closeDet) = [];
    
    figure
    hold on
    hLine1 = plot(testInd, classProb(:,1:2));
    plot(testInd([1 end]),detThreshold * [1 1],'c')
    plot(detFootStrike{cut}, 1.2 * ones(size(detFootStrike{cut})),'pb','MarkerFaceColor','none')
    plot(detFootOff{cut}, 1.2 * ones(size(detFootOff{cut})),'pr','MarkerFaceColor','none')
    plot(triggersCuts_test{cut,1}, 1.3*ones(size(triggersCuts_test{cut,1})),'vb','MarkerFaceColor','b')
    plot(triggersCuts_test{cut,2}, 1.3*ones(size(triggersCuts_test{cut,2})),'vr','MarkerFaceColor','r')
    set(gca,'xlim',testInd([1 end]),'ylim',[-0.01 1.4])
    set(hLine1(1),'color','b')
    set(hLine1(2),'color','r')
    title(['Cuts ' num2str(cut)])
    saveas(gcf,[saveDir filesep 'DetCuts' num2str(cut) '.fig'])

end

% calculate mutual information 
kardNo_hetero = zeros(3,3);
for cut = 1:length(dataCuts_test)  
    FS_kin = triggersCuts_test{cut,1};
    FS_kin(FS_kin < param.featureLen) = [];
    FO_kin = triggersCuts_test{cut,2};
    FO_kin(FO_kin < param.featureLen) = [];
    if size(FS_kin,1) == 1
        FS_kin = FS_kin';
    end
    if size(FO_kin,1) == 1
        FO_kin = FO_kin';
    end

    if size(FS_kin,1) == 1
        FS_kin = FS_kin';
    end
    if size(FO_kin,1) == 1
        FO_kin = FO_kin';
    end

    ExtendStimEvent = detFootStrike{cut} + rfsAnticipation_pts + stimDelay_pts;
    FlexStimEvent = detFootOff{cut} + rfoAnticipation_pts + stimDelay_pts;

    [histEdges,hitBins,negLen] = calcHeteroHistEdgesMulticlass({FO_kin, FS_kin}, ...
                                                                size(dataCuts_test{cut},1), ...
                                                                tolWin);

    tmp = calcHeteroKardinalityMulticlass({FO_kin, FS_kin}, ...
                                          {FlexStimEvent, ExtendStimEvent}, ....
                                          tolWin, ...
                                          histEdges, ...
                                          hitBins, ...
                                          negLen);

    kardNo_hetero = kardNo_hetero + squeeze(tmp);

end
mutualInfo = calcMutInfoMulticlass_PriorNorm(kardNo_hetero);


end

