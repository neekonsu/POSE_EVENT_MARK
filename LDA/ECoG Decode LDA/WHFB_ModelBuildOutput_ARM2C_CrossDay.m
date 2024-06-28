close all
clear all
clc

addpath('/Volumes/Smile347/ECoG-Decoding/Code/Functions')
monkey_dir = 'Natalya';
task_dir = 'SS';
train_date ='20200723';
test_date = '20200730';

model_dir = ['/Volumes/Smile347/ECoG-Decoding/Model' filesep monkey_dir filesep train_date filesep];
load([model_dir filesep monkey_dir '_' train_date '_' task_dir '_model.mat'])

data_dir = ['/Volumes/Smile347/ECoG-Decoding/Model' filesep monkey_dir filesep test_date filesep];
load([data_dir filesep 'ModelBuildData_2k_' monkey_dir '_' test_date '_' task_dir '.mat'])

save_dir = [data_dir 'Train_' train_date filesep];
mkdir(save_dir);

neuralDataDS = neuralDSData;

load([data_dir filesep 'trft_normMean_' task_dir '.mat'],'trft_normMean')


chUsed = param.chUsed;

testCuts = 1:H.noOfCuts;

isSaveFigure = true;
isSaveModel = false;
isLoadDecData = false;


%% Conver hand triggers into an appropriate structure

hand_triggers = cell(H.noOfCuts,4);
for cut = 1:H.noOfCuts
    hand_triggers{cut,1} = triggersCuts.corrGrasping{cut};
    hand_triggers{cut,3} = triggersCuts.corrReaching{cut};
    hand_triggers{cut,2} = triggersCuts.corrGraspingFood{cut};
    hand_triggers{cut,4} = triggersCuts.corrReachingFood{cut};
end
%% Correct the triggers

extentionShift = Model.extentionShift;    % pts
flexionShift = Model.flexionShift;     % pts

for cut = 1:H.noOfCuts
    for stInd = [1 3]
        mod_triggers{cut,stInd} = hand_triggers{cut,stInd} + extentionShift;
        mod_triggers{cut,stInd}(mod_triggers{cut,stInd} <= 0 | mod_triggers{cut,stInd} > size(neuralDSData{cut},1)) = [];
    end

    for stInd = [2 4]
        mod_triggers{cut,stInd} = hand_triggers{cut,stInd} + flexionShift;
        mod_triggers{cut,stInd}(mod_triggers{cut,stInd} <= 0 | mod_triggers{cut,stInd} > size(neuralDSData{cut},1)) = [];
    end
end
%%
if ~isLoadDecData

    %% Doing the STFT analysis
    DP.fftWinSize = floor(H.sampleRate/2);
    DP.fftWinFunction = hamming(DP.fftWinSize);
    DP.fftBaseStep = floor(DP.fftWinSize/10);
    DP.fftDecFR = 100;
    DP.fftDecStep = floor(H.sampleRate/DP.fftDecFR);
    DP.offsetBase = 0;
%     DP.decFreqBand = [8 12;12 30;80 200];
    DP.decFreqBand = [80 200];

    DP.fftBaseFR = round(1/(DP.fftBaseStep/H.sampleRate));


    


    [trft_all,DP.trft_frequencies,decInd,blkInd] = baselineAmplitude_SE(neuralDataDS, ...
                                                      trft_normMean, ...
                                                      [], ...
                                                      DP.offsetBase, ...
                                                      DP.fftWinSize, ...
                                                      DP.fftDecStep, ...
                                                      H.sampleRate, ...
                                                      DP.fftWinFunction);
    DP.freqIndBottom = zeros(size(DP.decFreqBand,1),1);
    DP.freqIndTop = zeros(size(DP.decFreqBand,1),1);
    DP.frequencyBottom = zeros(size(DP.decFreqBand,1),1);
    DP.frequencyTop = zeros(size(DP.decFreqBand,1),1);
    
    nrBand = size(DP.decFreqBand,1);
    trftBand = nan(nrBand,length(chUsed),size(trft_all,3));
    for i = 1:nrBand
        indBand = find(DP.trft_frequencies>=DP.decFreqBand(i,1) & DP.trft_frequencies<=DP.decFreqBand(i,2));
        DP.freqIndBottom(i) = indBand(1);
        DP.freqIndTop(i) = indBand(end);
        
        if DP.freqIndBottom(i) > 1
            DP.frequencyBottom(i) = mean(DP.trft_frequencies(DP.freqIndBottom(i)-1:DP.freqIndBottom(i)));
        else
            DP.frequencyBottom(i) = 0;
        end

        if DP.freqIndTop(i) < length(DP.trft_frequencies)
            DP.frequencyTop(i) = mean(DP.trft_frequencies(DP.freqIndTop(i):DP.freqIndTop(i) + 1));
        else
            DP.frequencyTop(i) = DP.trft_frequencies(end);
        end
    
        trftBand(i,:,:) = sqrt(squeeze(mean(trft_all(DP.freqIndBottom:DP.freqIndTop,chUsed,:),1)));
    end
    trftBand = reshape(trftBand, nrBand*length(chUsed), size(trft_all,3));
    DP.decInd = decInd;
    DP.blkInd = blkInd;
    DP.normMean = trft_normMean;

%     clear trft_all;

    disp('Completed calculating STFT');
    %% build neural DataDec
    neuralDataDec = cell(1,H.noOfCuts);
    for blk = 1:H.noOfCuts
        neuralDataDec{blk} = trftBand(:, blkInd == blk)';
    end
    disp('Completed building neuralDataDec');
    clear trftBand;
    
    %% Conver hand triggers into an dowmsampled structure
    % First class - foot strike
    % Second class - foot off
    H.DecSampleRate = floor(H.sampleRate/DP.fftDecStep);
    ds_triggers = cell(H.noOfCuts,4);

    for cut = 1:H.noOfCuts
        tmpInd = decInd(blkInd==cut);

        for ii = 1:length(hand_triggers{cut,1})
            [~,minInd] = min(abs(hand_triggers{cut,1}(ii) - tmpInd));
            if (~isempty(minInd))
                ds_triggers{cut,1}(ii) = minInd;
            end
        end

        for ii = 1:length(hand_triggers{cut,2})
            [~,minInd] = min(abs(hand_triggers{cut,2}(ii) - tmpInd));
            if (~isempty(minInd))
                ds_triggers{cut,2}(ii) = minInd;
            end
        end

        for ii = 1:length(hand_triggers{cut,3})
            [~,minInd] = min(abs(hand_triggers{cut,3}(ii) - tmpInd));
            if (~isempty(minInd))
                ds_triggers{cut,3}(ii) = minInd;
            end
        end

        for ii = 1:length(hand_triggers{cut,4})
            [~,minInd] = min(abs(hand_triggers{cut,4}(ii) - tmpInd));
            if (~isempty(minInd))
                ds_triggers{cut,4}(ii) = minInd;
            end
        end
    end

    dsmod_triggers = cell(H.noOfCuts,4);

    for cut = 1:H.noOfCuts
        tmpInd = decInd(blkInd==cut);

        for ii = 1:length(mod_triggers{cut,1})
            [~,minInd] = min(abs(mod_triggers{cut,1}(ii) - tmpInd));
            if (~isempty(minInd))
                dsmod_triggers{cut,1}(ii) = minInd;
            end
        end

        for ii = 1:length(mod_triggers{cut,2})
            [~,minInd] = min(abs(mod_triggers{cut,2}(ii) - tmpInd));
            if (~isempty(minInd))
                dsmod_triggers{cut,2}(ii) = minInd;
            end
        end

        for ii = 1:length(mod_triggers{cut,3})
            [~,minInd] = min(abs(mod_triggers{cut,3}(ii) - tmpInd));
            if (~isempty(minInd))
                dsmod_triggers{cut,3}(ii) = minInd;
            end
        end

        for ii = 1:length(mod_triggers{cut,4})
            [~,minInd] = min(abs(mod_triggers{cut,4}(ii) - tmpInd));
            if (~isempty(minInd))
                dsmod_triggers{cut,4}(ii) = minInd;
            end
        end
    end

    disp('Completed downsample triggers');
end

decInd = DP.decInd;
blkInd = DP.blkInd;

H.DecSampleRate = floor(H.sampleRate/DP.fftDecStep);

%% Writting model to text file
% 
% destDir = 'D:\shiqi model building\1-LFP_Decoding\Q33';
% % mkdir(destDir);
% modelFilename = 'WHFB_Q33_20171025_TRDM_4C_5taps_bilateral_anticipation_FO0_rc0_05.txt';
% 
% writeNeurostimModel2file_sgf(bilateralModel, [destDir filesep modelFilename]);


%% Test written values

% testModel = readNeurostimModelFile([destDir filesep modelFilename]);
testModel = Model;

%% Decoded probablities

detLeftFootStrike = cell(H.noOfCuts,1);
detLeftFootOff = cell(H.noOfCuts,1);
detRightFootStrike = cell(H.noOfCuts,1);
detRightFootOff = cell(H.noOfCuts,1);

for selCut = testCuts

    [classProb,testInd] = calcStepDetectionProbabilities(neuralDataDec(selCut),testModel,H.DecSampleRate);

    detThreshold = param.treshVal;
    
    rightFootStrikeInd = classProb(:,1) >= detThreshold;
    detRightFootStrike{selCut} = testInd(find(diff(rightFootStrikeInd) == 1) + 1);
    closeDet = find(diff(detRightFootStrike{selCut}) < param.refractorySec * H.DecSampleRate) + 1;
    detRightFootStrike{selCut}(closeDet) = [];

    rightFootOffInd = classProb(:,2) >= detThreshold;
    detRightFootOff{selCut} = testInd(find(diff(rightFootOffInd) == 1) + 1); 
    closeDet = find(diff(detRightFootOff{selCut}) < param.refractorySec * H.DecSampleRate) + 1;
    detRightFootOff{selCut}(closeDet) = [];
    
    trigDiff.RFS{selCut} = nan(1,length(detRightFootStrike{selCut}));
    for ii = 1:length(detRightFootStrike{selCut})
        [~,minInd] = min(abs(detRightFootStrike{selCut}(ii) - ds_triggers{selCut,1}));
        if (~isempty(minInd))
            trigDiff.RFS{selCut}(ii) = ds_triggers{selCut,1}(minInd) - detRightFootStrike{selCut}(ii);
        end
    end
    
    trigDiff.RFO{selCut} = nan(1,length(detRightFootOff{selCut}));
    for ii = 1:length(detRightFootOff{selCut})
        [~,minInd] = min(abs(detRightFootOff{selCut}(ii) - ds_triggers{selCut,2}));
        if (~isempty(minInd))
            trigDiff.RFO{selCut}(ii) = ds_triggers{selCut,2}(minInd) - detRightFootOff{selCut}(ii);
        end
    end
    


    figure
    hold on
    hLine1 = plot(testInd, classProb(:,1:2));
    plot(testInd([1 end]),detThreshold * [1 1],'c')
    plot(detRightFootStrike{selCut}, 1.2 * ones(size(detRightFootStrike{selCut})),'pb','MarkerFaceColor','none')
    plot(detRightFootOff{selCut}, 1.2 * ones(size(detRightFootOff{selCut})),'pr','MarkerFaceColor','none')
    plot(ds_triggers{selCut,1}, 1.3*ones(size(ds_triggers{selCut,1})),'vb','MarkerFaceColor','b')
    plot(ds_triggers{selCut,2}, 1.3*ones(size(ds_triggers{selCut,2})),'vr','MarkerFaceColor','r')
    set(gca,'xlim',testInd([1 end]),'ylim',[-0.01 1.4])
    set(hLine1(1),'color','b')
    set(hLine1(2),'color','r')
    title(['Cuts ' num2str(selCut)])
    if isSaveFigure
        saveas(gcf,[save_dir filesep task_dir '_DetCuts' num2str(selCut) '.fig'])
    end

end


%%
figure
trigDiff.RFS_all = cell2mat(trigDiff.RFS) / H.DecSampleRate*1000;    % ms
hist(trigDiff.RFS_all(trigDiff.RFS_all > -500 & trigDiff.RFS_all < 500),50)
title('Grasping Obj')
set(gca,'xlim',[-500 500])
xlabel('TrigDiff / ms')
saveas(gcf,[save_dir filesep task_dir '_TrigDiff_GraspObj.fig'])
figure
% trigDiff.RFO_all = cell2mat(trigDiff.RFO) / 2;    % ms
trigDiff.RFO_all = cell2mat(trigDiff.RFO) / H.DecSampleRate*1000;    % ms
hist(trigDiff.RFO_all(trigDiff.RFO_all > -500 & trigDiff.RFO_all < 500),50)
title('Grasping Food')
set(gca,'xlim',[-500 500])
xlabel('TrigDiff / ms')
saveas(gcf,[save_dir filesep task_dir '_TrigDiff_GraspFood.fig'])


estimatedStimDelay = 0;            % ms
estimatedRfoAnticipation = 0;      % ms
estimatedRfsAnticipation = 0;
newExtensionAnticipation = H.sampleRate * nanmedian(cell2mat(trigDiff.RFS))/H.DecSampleRate + extentionShift...
                           - H.sampleRate * (estimatedStimDelay + estimatedRfsAnticipation)/1000;
newFlexionAnticipation = H.sampleRate * nanmedian(cell2mat(trigDiff.RFO))/H.DecSampleRate + flexionShift ...
                           - H.sampleRate * (estimatedStimDelay + estimatedRfoAnticipation)/1000;

disp(['The proposed extension anticipation is ' num2str(newExtensionAnticipation) ...
      ', i.e. extension should be moved by ' num2str(newExtensionAnticipation - extentionShift) ' points']);

disp(['The proposed flexion anticipation is ' num2str(newFlexionAnticipation) ...
      ', i.e. flexion should be moved by ' num2str(newFlexionAnticipation - flexionShift) ' points']);


  
%% Calculating precission using heterogeneous bins


stimDelay_pts = estimatedStimDelay / 1000 * H.DecSampleRate;
rfsAnticipation_pts = estimatedRfsAnticipation / 1000 * H.DecSampleRate;
rfoAnticipation_pts = estimatedRfoAnticipation / 1000 * H.DecSampleRate;
testFigure = false;
tolWin = (0.05:0.025:0.4) * H.DecSampleRate;
kardNo_hetero = zeros(length(tolWin),3,3);
for tlw = 1:length(tolWin)
    for cut = testCuts
        RFS_kin = ds_triggers{cut,1};
        RFS_kin(RFS_kin < param.featureLen) = [];
        RFO_kin = ds_triggers{cut,2};
        RFO_kin(RFO_kin < param.featureLen) = [];
        
        if size(RFS_kin,1) == 1
            RFS_kin = RFS_kin';
        end
        if size(RFO_kin,1) == 1
            RFO_kin = RFO_kin';
        end

        rightExtendStimEvent = detRightFootStrike{cut} + rfsAnticipation_pts + stimDelay_pts;

        rightFlexStimEvent = detRightFootOff{cut} + rfoAnticipation_pts + stimDelay_pts;

        [histEdges,hitBins,negLen] = calcHeteroHistEdgesMulticlass({RFO_kin, RFS_kin}, ...
                                                                   size(neuralDataDec{cut},1), ...
                                                                   tolWin(tlw));

        tmp = calcHeteroKardinalityMulticlass({RFO_kin, RFS_kin}, ...
                                              {rightFlexStimEvent, rightExtendStimEvent}, ....
                                              tolWin(tlw), ...
                                              histEdges, ...
                                              hitBins, ...
                                              negLen);

        kardNo_hetero(tlw,:,:) = kardNo_hetero(tlw,:,:) + tmp;
    end
end

mutInfo_hetero = calcMutInfoMulticlass_PriorNorm(kardNo_hetero);

figure
hold on
plot(tolWin /2/ H.DecSampleRate * 1000,mutInfo_hetero,'-m')
xlabel('Tolerance (ms)')
ylabel('Normalized mutual information')
title('Detector precision as a function of tolerance')
if isSaveFigure
    saveas(gcf,[save_dir filesep task_dir '_DetMI.fig'])
end
fprintf('TolWin = %d ms, MI = %f\n', tolWin(end)/2/H.DecSampleRate * 1000,mutInfo_hetero(end))