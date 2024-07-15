function [newEventAnticipation] = searchShiftOptLDA(triggersCuts,dataCuts, param, iniShift)
%SEARCHSHIFTOPTLDA Summary of this function goes here
% Search for optimal set of shift for the rLDA decoding
% Use in conjuction with functions:
%       buildStepDetection
%       calcStepDetectionProbabilities
% INPUT:
%   triggersCuts   - cell of data containing gait events in each cuts
%   dataCuts       - cell of data containing variables in each cuts
%   param          - structure containing parameters
% OUTPUT:
%   newShift     -  shift used for correction of triggers
% Shiqi Sun
% 30.07.2020
close all
if (~iscell(triggersCuts))
    triggersCuts = {triggersCuts};
end

if (~iscell(dataCuts))
    dataCuts = {dataCuts};
end

if (nargin < 4)
    iniShift = zeros(1,size(triggersCuts{1},2));
end
%% Making sure that the input cells have the proper size

assert(iscell(triggersCuts));
assert(iscell(dataCuts));
assert(length(triggersCuts) == length(dataCuts));

%%
noOfChannels = size(dataCuts{1},2);
noOfTrig = size(triggersCuts,2);
noOfCuts = length(dataCuts);

%% Conver hand triggers into an appropriate structure
hand_triggers = triggersCuts;
for ii = 1:noOfTrig
    for cut = 1:noOfCuts
        mod_triggers{cut,ii} = hand_triggers{cut,ii} + iniShift(ii);
        mod_triggers{cut,ii}(mod_triggers{cut,ii} <= 0 | mod_triggers{cut,ii} > size(dataCuts{cut},1)) = [];
    end
end

%% Build detector
testModel = buildStepDetection(dataCuts,mod_triggers,param);

%% Decoded probablities
detEvents = cell(noOfCuts,noOfTrig);
trigDiff = cell(noOfCuts,noOfTrig);
for cut = 1:noOfCuts
    [classProb,testInd] = calcStepDetectionProbabilities(dataCuts(cut),testModel,param.sampleRate);

    detThreshold = param.treshVal;
    
    for ii = 1:noOfTrig
        eventInd = classProb(:,ii) >= detThreshold;
        detEvents{cut,ii} = testInd(find(diff(eventInd) == 1) + 1);
        closeDet = find(diff(detEvents{cut,ii}) < param.refractorySec * param.sampleRate) + 1;
        detEvents{cut,ii}(closeDet) = [];
        
        trigDiff{cut,ii} = nan(1,length(detEvents{cut,ii}));
        for jj = 1:length(trigDiff{cut,ii})
            [~,minInd] = min(abs(detEvents{cut,ii}(jj) - hand_triggers{cut,ii}));
            if (~isempty(minInd))
                trigDiff{cut,ii}(jj) = hand_triggers{cut,ii}(minInd) - detEvents{cut,ii}(jj);
            end
        end
    end
    
    figure
    hold on
    hLine1 = plot(testInd, classProb(:,1:noOfTrig));
    plot(testInd([1 end]),detThreshold * [1 1],'c')
    for ii = 1:noOfTrig
        if ii == 1
            plot(detEvents{cut,ii}, 1.2 * ones(size(detEvents{cut,ii})),'pb','MarkerFaceColor','none')
            plot(hand_triggers{cut,ii}, 1.4 * ones(size(hand_triggers{cut,ii})),'vb','MarkerFaceColor','none')
        else
            plot(detEvents{cut,ii}, 1.2 * ones(size(detEvents{cut,ii})),'pr','MarkerFaceColor','none')
            plot(hand_triggers{cut,ii}, 1.4 * ones(size(hand_triggers{cut,ii})),'vr','MarkerFaceColor','none')
        end
        
    end
    set(gca,'xlim',testInd([1 end]),'ylim',[-0.01 1.4])
    set(hLine1(1),'color','b')
    set(hLine1(2),'color','r')
    title(['Cuts ' num2str(cut)])
end

newEventAnticipation = nan(1,noOfTrig);
for ii = 1:noOfTrig
    newEventAnticipation(ii) = nanmedian(cell2mat(trigDiff(:,ii)')) + iniShift(ii);
    disp(['The proposed event anticipation is ' num2str(newEventAnticipation(ii)) ...
      ', i.e. shift should be moved by ' num2str(newEventAnticipation(ii) - iniShift(ii)) ' points']);
end

end

