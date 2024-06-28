close all
clear all
clc
addpath('/Volumes/Smile347/ECoG-Decoding/Code/Functions')
monkey_dir = 'Natalya';
task_dir = 'BC';
the_date = '20200723';
usedTrials = [11 12];

H.savedatasetName = [monkey_dir '_' the_date];
data_dir = '/Volumes/Smile347/ECoG-Decoding/Data';
save_dir = ['/Volumes/Smile347/ECoG-Decoding/Model' filesep monkey_dir filesep the_date];
mkdir(save_dir)

load NatalyaElecMap
plotDiagnostics = 'true';

input_Events_data = [fullfile(data_dir, the_date, 'Events') filesep];
input_NS_data = [fullfile(data_dir, the_date, 'Blackrock') filesep];
% input_SIMI_data = [fullfile(data_dir, the_date, 'SIMI') filesep];
%% check file number
list_ns = dir(fullfile(input_NS_data,'*.ns6'));
list_event=dir(fullfile(input_Events_data,'*.mat'));

NS_Files = {list_ns.name}';
for ii = 1:size(NS_Files,1)
    iNs = NS_Files{ii,1};
    matchStr = (regexp(iNs,'\d{3}.ns6','match'));
    NS_Files{ii,1} = matchStr{1,end}(2:end-4);
end
nsTrials = str2num(cell2mat(NS_Files));

Evt_Files = {list_event.name}';
for ii = 1:size(Evt_Files,1)
    iEvt = Evt_Files{ii,1};
    matchStr = (regexp(iEvt,'\d{3}_arm_events','match'));
    Evt_Files{ii,1} = matchStr{1,end}(2:3);
end
evtTrials = str2num(cell2mat(Evt_Files));

cmTrials = intersect(usedTrials,intersect(nsTrials,evtTrials));
if length(cmTrials) ~= length(usedTrials)
    disp('Actual used Trials:')
    usedTrials = cmTrials;
    disp(cmTrials')
end

[~,inEVENTidx] = setdiff(evtTrials,cmTrials);
list_event(inEVENTidx) = [];
[~,inNSidx] = setdiff(nsTrials,cmTrials);
list_ns(inNSidx) = [];

%% Parameters
H.ns5VideoThres = 50;
H.ns5VideoCh = 5;
H.targetSampleRate = 2000;
H.useBlocks = usedTrials;

H.noOfCh = 64;  
H.ch2rm = [];
H.neuroThreshold = 1000;
H.neuroChThreshold = 60;
H.junkOffset = 0.05 * H.targetSampleRate;
H.binSizeSec = 0.15;

%% Loading events
fs_simi = 100;
for blk = 1:length(H.useBlocks)
    tmpTriggers = load([list_event(blk).folder filesep list_event(blk).name]);
    RFS = tmpTriggers.event.RFS;
    RFO = tmpTriggers.event.RFO;
    LFS = tmpTriggers.event.LFS;
    LFO = tmpTriggers.event.LFO;
    
    triggers.Grasping{blk} = [];
    triggers.Reaching{blk} = [];   
    triggers.GraspingFood{blk} = [];
    triggers.ReachingFood{blk} = []; 
    % Keep events that forms a normal trial RFO(reach Obj)->RFS(grasp Obj)->LFO(Reach Food)->LFS(Grasp Food) 
    for ii = 1:length(RFO)
        cntRFO = RFO(ii);
        
        indRFS = find(RFS>cntRFO,1);
        cntRFS = RFS(indRFS);
        indLFO = find(LFO>cntRFS,1);
        cntLFO = LFO(indLFO);
        indLFS = find(LFS>cntLFO,1);
        cntLFS = LFS(indLFS);
        
        if cntLFS-cntRFO < 4*fs_simi
            triggers.Grasping{blk} = [triggers.Grasping{blk} cntRFS];
            triggers.Reaching{blk} = [triggers.Reaching{blk} cntRFO];
            triggers.GraspingFood{blk} = [triggers.GraspingFood{blk} cntLFS];
            triggers.ReachingFood{blk} = [triggers.ReachingFood{blk} cntLFO];
        end
        
    end
    
    
    if isfield(tmpTriggers.event,'SR')
        triggers.StartOfRest{blk} = tmpTriggers.event.SR;
    end
    if isfield(tmpTriggers.event,'ER')
        triggers.EndOfRest{blk} = tmpTriggers.event.ER;
    end
    
    if plotDiagnostics
        figure
        hold on

        for i=1:length(triggers.Grasping{blk})
            plot(triggers.Grasping{blk}(i)*[1 1], [0 1], 'r')
        end

        for i=1:length(triggers.Reaching{blk})
            plot(triggers.Reaching{blk}(i)*[1 1], [0 1], 'b')
        end
        
        for i=1:length(triggers.GraspingFood{blk})
            plot(triggers.GraspingFood{blk}(i)*[1 1], [0 -1], 'r')
        end

        for i=1:length(triggers.ReachingFood{blk})
            plot(triggers.ReachingFood{blk}(i)*[1 1], [0 -1], 'b')
        end

        for i=1:length(tmpTriggers.event.SR)
            plot(tmpTriggers.event.SR(i)*[1 1], [-1 1], 'g')
        end

        for i=1:length(tmpTriggers.event.ER)
            plot(tmpTriggers.event.ER(i)*[1 1], [-1 1], 'k')
        end
    end
end
%% Loading raw neural data
neuralDSData = []; 
triggersCuts = [];
simiSyncCuts = [];
counter = 0;
for blk = 1:length(H.useBlocks)   
    cnt_trial = str2num(list_ns(blk).name(end-6:end-4));
    disp(['======= Processing ' monkey_dir ', ' task_dir ' , trial' num2str(cnt_trial) ' ========'])
    
    % Find the trigger and correct the events
    triggerFile = [list_ns(blk).folder filesep list_ns(blk).name(1:end-3) 'ns5'];
    ns5Data = openNSxCervical(triggerFile);
    H.ns5SampleRate = ns5Data.MetaTags.SamplingFreq;
    disp(['loading NS5 file ' list_ns(blk).name(1:end-3) 'ns5'])

    cameraTrig = find(diff(ns5Data.Data(H.ns5VideoCh,:))>H.ns5VideoThres,1)+1; % if no trigger found, check the threshold 20000
%     for ch = 1:16
%         figure
%         plot(ns5Data.Data(ch,:))
%         title(num2str(ch))
%     end
    if plotDiagnostics
        figure
        plot(abs(ns5Data.Data(H.ns5VideoCh,:)))
        hold on
        plot([cameraTrig cameraTrig],[-1 1]*H.ns5VideoThres,'-g','linewidth',2)
        title('Camera Trigger')
    end
    clear ns5Data
    
    triggers.corrGrasping{blk} = cameraTrig * H.targetSampleRate/H.ns5SampleRate + triggers.Grasping{blk} * H.targetSampleRate / 100;
    triggers.corrReaching{blk} = cameraTrig * H.targetSampleRate/H.ns5SampleRate + triggers.Reaching{blk} * H.targetSampleRate / 100;
    triggers.corrGraspingFood{blk} = cameraTrig * H.targetSampleRate/H.ns5SampleRate + triggers.GraspingFood{blk} * H.targetSampleRate / 100;
    triggers.corrReachingFood{blk} = cameraTrig * H.targetSampleRate/H.ns5SampleRate + triggers.ReachingFood{blk} * H.targetSampleRate / 100;
    triggers.corrStartOfRest{blk} = cameraTrig * H.targetSampleRate/H.ns5SampleRate + triggers.StartOfRest{blk} * H.targetSampleRate / 100;
    triggers.corrEndOfRest{blk} = cameraTrig * H.targetSampleRate/H.ns5SampleRate + triggers.EndOfRest{blk} * H.targetSampleRate / 100;
    
    % load the ECoG data
    fpath = fullfile(list_ns(blk).folder,list_ns(blk).name);  
    ns6Data = openNSxCervical(fpath);
    disp(['loading NS6 file ' list_ns(blk).name])
    
    if blk == 1
        H.ns6SampleRate = ns6Data.MetaTags.SamplingFreq;
        H.ns6dsRate = H.ns6SampleRate / H.targetSampleRate;  
    end
    
    % remap the ns6.Data, make the electrode label corresponding to the map
    
    tmpData = ns6Data.Data;
    for ch = 1:H.noOfCh
        ns6Data.Data(map(ch,2), :) = tmpData(map(ch,1),:);
    end
    clear tmpData
    
    % Neuronal junk identification algorithm
    for ch = 1:H.noOfCh
        tmpNuInd = ns6Data.Data(ch, :) > H.neuroThreshold | ns6Data.Data(ch, :) < -H.neuroThreshold;
        tmpNuIndN = histc(find(tmpNuInd),1:H.ns6dsRate:size(ns6Data.Data,2));
        if ch == 1
            goodNuIndSum = zeros(1,length(tmpNuIndN));
        end
        goodNuIndSum = goodNuIndSum + (tmpNuIndN == 0);
    end
    goodNuInd = goodNuIndSum > H.neuroChThreshold;
    
    goodNuStart = find(goodNuInd(1:end-1) == 0 & goodNuInd(2:end) == 1) + 1;
    if (goodNuInd(1) == 1)
        goodNuStart = [1 goodNuStart];
    end
    
    goodNuEnd = find(goodNuInd(1:end-1) == 1 & goodNuInd(2:end) == 0);
    if (goodNuInd(end) == 1)
        goodNuEnd = [goodNuEnd length(goodNuInd)];
    end    
    goodNuLen = goodNuEnd - goodNuStart + 1;
    goodNuEpoch = find(goodNuLen >= H.targetSampleRate);
    
    tmpNs6Data = nan(H.noOfCh,length(goodNuInd));
    
    % Joint junk algorithm (if there is other kind of signal to consider)
    goodKinInd = zeros(size(goodNuInd));
    for ii = 1:length(triggers.corrReaching{blk})
        indStart = max(1,triggers.corrReaching{blk}(ii) - H.targetSampleRate*1);
        indEnd = min(triggers.corrGraspingFood{blk}(ii) + H.targetSampleRate*1,length(goodKinInd));
        goodKinInd(indStart:indEnd) = 1;
    end
    for ii = 1:length(triggers.corrStartOfRest{blk})
        indStart = max(1,triggers.corrStartOfRest{blk}(ii) - H.targetSampleRate*0.05);
        indEnd = min(triggers.corrEndOfRest{blk}(ii) + H.targetSampleRate*0.05,length(goodKinInd));
        goodKinInd(indStart:indEnd) = 1;
    end
    
    % Joint junk algorithm (if there is other kind of signal to consider)
    goodInd = goodNuInd & goodKinInd;
    goodStart = find(goodInd(1:end-1) == 0 & goodInd(2:end) == 1) + 1;
    if (goodInd(1) == 1)
        goodStart = [1 goodStart];
    end
    
    goodEnd = find(goodInd(1:end-1) == 1 & goodInd(2:end) == 0);
    if (goodInd(end) == 1)
        goodEnd = [goodEnd length(goodInd)];
    end    
    goodLen = goodEnd - goodStart + 1;
    goodEpoch = find(goodLen >= 2 * H.targetSampleRate);
    
    disp(length(goodEpoch))
    for ge = 1:length(goodEpoch)
        counter = counter + 1;
        takeInd = (goodStart(goodEpoch(ge)) + H.junkOffset):(goodEnd(goodEpoch(ge)) - H.junkOffset);
        takeInd(takeInd > length(goodNuInd)) = [];
        
        % downsampled ECoG data
        noOfTimePts = goodEnd(goodEpoch(ge)) - goodStart(goodEpoch(ge)) ...
                                             - 2 * H.junkOffset + 1;
        neuroStart = (goodStart(goodEpoch(ge)) + H.junkOffset) * H.ns6dsRate;
        neuroEnd = (goodEnd(goodEpoch(ge)) - H.junkOffset + 1) * H.ns6dsRate - 1;
        neuralRawData = ns6Data.Data(:,neuroStart:neuroEnd);
        neuralDSData{counter} = nan(noOfTimePts,H.noOfCh);
        
        for ch = 1:H.noOfCh
            neuralDSData{counter}(:,ch) = decimate(double(neuralRawData(ch,:)),H.ns6dsRate);
        end
        
%         assert(ceil(size(neuralRawData{counter},2) / H.ns6dsRate) == noOfTimePts);
        tmpNs6Data(:,takeInd) = neuralDSData{counter}'; 
        
        goodInd = (triggers.corrGrasping{blk} > takeInd(1) & triggers.corrGrasping{blk} < takeInd(end));
        triggersCuts.corrGrasping{counter} = triggers.corrGrasping{blk}(goodInd) - takeInd(1) + 1;
        triggersCuts.Grasping{counter} = triggers.Grasping{blk}(goodInd);
        
        goodInd = (triggers.corrReaching{blk} > takeInd(1) & triggers.corrReaching{blk} < takeInd(end));
        triggersCuts.corrReaching{counter} = triggers.corrReaching{blk}(goodInd) - takeInd(1) + 1;
        triggersCuts.Reaching{counter} = triggers.Reaching{blk}(goodInd);
        
        goodInd = (triggers.corrGraspingFood{blk} > takeInd(1) & triggers.corrGraspingFood{blk} < takeInd(end));
        triggersCuts.corrGraspingFood{counter} = triggers.corrGraspingFood{blk}(goodInd) - takeInd(1) + 1;
        triggersCuts.GraspingFood{counter} = triggers.GraspingFood{blk}(goodInd);
        
        goodInd = (triggers.corrReachingFood{blk} > takeInd(1) & triggers.corrReachingFood{blk} < takeInd(end));
        triggersCuts.corrReachingFood{counter} = triggers.corrReachingFood{blk}(goodInd) - takeInd(1) + 1;
        triggersCuts.ReachingFood{counter} = triggers.ReachingFood{blk}(goodInd);

        goodInd = (triggers.corrStartOfRest{blk} > takeInd(1) & triggers.corrStartOfRest{blk} < takeInd(end));
        triggersCuts.corrStartOfRest{counter} = triggers.corrStartOfRest{blk}(goodInd) - takeInd(1) + 1;
        
        goodInd = (triggers.corrEndOfRest{blk} > takeInd(1) & triggers.corrEndOfRest{blk} < takeInd(end));
        triggersCuts.corrEndOfRest{counter} = triggers.corrEndOfRest{blk}(goodInd) - takeInd(1) + 1;
        simiSyncCuts{counter} = [H.useBlocks(blk) counter cameraTrig * H.targetSampleRate/H.ns5SampleRate (takeInd(1)/H.targetSampleRate-cameraTrig/H.ns5SampleRate)*100];
        
        
    end

    if plotDiagnostics
        figure
        plot(tmpNs6Data')
        title('Downsampled Neural Cuts')
    end
    clear ns6Data tmpNs6Data
end
H.sampleRate = H.targetSampleRate;
H.noOfCuts = counter;
disp(H.noOfCuts)

%%
save([save_dir filesep 'ModelBuildData_2k_' H.savedatasetName '_' task_dir '.mat'],'neuralDSData','H','triggers','triggersCuts','simiSyncCuts')
