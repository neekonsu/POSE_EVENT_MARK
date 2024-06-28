function [ mutualInfo] = searchRegularizedLDA( triggersCuts, dataCuts, param, verbose)
% Search for optimal set of meta-parameters for the rLDA decoding
% Use in conjuction with functions:
%       buildStepDetection
%       calcStepDetectionProbabilities
%       calcHeteroHistEdgesMulticlass
%       calcHeteroKardinalityMulticlass
%       calcMutInfoMulticlass_PriorNorm
% INPUT:
%   triggersCuts   - cell of data containing gait events in each cuts
%   dataCuts       - cell of data containing variables in each cuts
%   param          - structure containing parameters
% OUTPUT:
%   mutualInfo     - matrix of data containing mutual information of each
%                    set of meta-parameters

% Shiqi Sun
% 19.10.2017

if (nargin < 4)
    verbose = false;
end

if (~iscell(triggersCuts))
    triggersCuts = {triggersCuts};
end

if (~iscell(dataCuts))
    dataCuts = {dataCuts};
end

%% Making sure that the input cells have the proper size

assert(iscell(triggersCuts));
assert(iscell(dataCuts));
assert(length(triggersCuts) == length(dataCuts));

%% Setting up the sizes of loops
noOfFeatDims = length(param.featureDim);
noOfTmplLen = length(param.featureLen);
noOfRegCoeff = length(param.regCoeff);
noOfindStarts = length(param.indStarts);

noOfChannels = length(param.chUsed);
noOfTrig = size(triggersCuts{1},2);
noOfSchemes = param.noOfSchemes;
noOfCuts = length(dataCuts);

%% Setting up the training and testing schemes

trainingScheme = cell(noOfSchemes,1);
testingScheme = cell(noOfSchemes,1);

cutLen = zeros(length(dataCuts),1);
for cut = 1:length(dataCuts)
    cutLen(cut) = size(dataCuts{cut},1);
end
[sortLen, sortInd] = sort(cutLen,'descend');

targetLen = sum(cutLen) / noOfSchemes;
goPos = true;
currentInd = 0;
currentCutInd = 1;
while (~isempty(sortLen))
    if goPos
        if currentInd == noOfSchemes
            currentInd = currentInd - 1;
            goPos = false;
        else
            currentInd = currentInd + 1;
        end
    else
        if currentInd == 1
            currentInd = currentInd + 1;
            goPos = true;
        else
            currentInd = currentInd - 1;
        end
    end
    
    if sum(cutLen(testingScheme{currentInd})) > targetLen
        continue;
    end
    
    for currentCutInd = 1:length(sortLen)
    	if (sum(cutLen(testingScheme{currentInd})) + sortLen(currentCutInd) < targetLen)
            testingScheme{currentInd} = union(testingScheme{currentInd},sortInd(currentCutInd));
            sortInd(currentCutInd) = [];
            sortLen(currentCutInd) = [];
            break;
        end
        
        if currentCutInd == length(sortLen)
            testingScheme{currentInd} = union(testingScheme{currentInd},sortInd(currentCutInd));
            sortInd(currentCutInd) = [];
            sortLen(currentCutInd) = [];
        end
    end
end
for i = 1:noOfSchemes
    trainingScheme{i} = setdiff(1:noOfCuts,testingScheme{i});
end

%% Allocating the output

mutualInfo = nan(noOfFeatDims,noOfTmplLen,noOfindStarts,noOfRegCoeff);

%% Running the algorithm
allModels = cell(noOfFeatDims,noOfTmplLen,noOfindStarts,noOfRegCoeff,noOfSchemes);

for dim = 1:noOfFeatDims
    for len = 1:noOfTmplLen
        for indS =1:noOfindStarts
            for regC = 1:noOfRegCoeff
                
                if verbose
                    disp(['Testing parameters set: Finished with:  ' ...
                          'Dim ' num2str(dim) '/' num2str(noOfFeatDims) ', ' ...
                          'Len ' num2str(len) '/' num2str(noOfTmplLen) ', ' ...
                          'IndS ' num2str(indS) '/' num2str(noOfindStarts) ', ' ...
                          'RegC ' num2str(regC) '/' num2str(noOfRegCoeff)]);
                end
                
                % set parameters of detectors
                tmpparam = param;
                tmpparam.featureDim = param.featureDim(dim);
                tmpparam.featureLen = param.featureLen(len);
                tmpparam.indStarts = param.indStarts(indS);
                tmpparam.regCoeff = param.regCoeff(regC);
                for cvI = 1:noOfSchemes
                    trainCuts = trainingScheme{cvI};

                    % build detector
                    allModels{dim, len, indS, regC, cvI} = buildStepDetection(dataCuts(trainCuts),triggersCuts(trainCuts,:),tmpparam);
                    
                    if verbose
                        disp(['Model trainning: Finished with:  ' ...
                              'Fold ' num2str(cvI) '/' num2str(noOfSchemes)]);
                    end
                end
                
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
                kardNo_hetero = zeros(3,3);

                detFootStrike = cell(noOfCuts,1);
                detFootOff = cell(noOfCuts,1);

                for cvI = 1:noOfSchemes
                    testCuts = testingScheme{cvI};
                    
                    for cut = testCuts
                        [classProb,testInd] = calcStepDetectionProbabilities(dataCuts(cut),allModels{dim, len, indS, regC, cvI},param.sampleRate);

                        detThreshold = param.treshVal;
                        rightFootStrikeInd = classProb(:,1) >= detThreshold;
                        detFootStrike{cut} = testInd(find(diff(rightFootStrikeInd) == 1) + 1);
                        closeDet = find(diff(detFootStrike{cut}) < param.sampleRate * param.refractorySec) + 1;
                        detFootStrike{cut}(closeDet) = [];

                        rightFootOffInd = classProb(:,2) >= detThreshold;
                        detFootOff{cut} = testInd(find(diff(rightFootOffInd) == 1) + 1); 
                        closeDet = find(diff(detFootOff{cut}) < param.sampleRate * param.refractorySec) + 1;
                        detFootOff{cut}(closeDet) = [];

                    end
                    if verbose
                        disp(['Model testing: Finished with:  ' ...
                              'Fold ' num2str(cvI) '/' num2str(noOfSchemes)]);
                    end
                end
                
                % calculate mutual information 
                for cvI = 1:noOfSchemes
                    testCuts = testingScheme{cvI};
                    for cut = testCuts                
                        FS_kin = triggersCuts{cut,1};
                        FO_kin = triggersCuts{cut,2};
                        
                        if size(FS_kin,1) == 1
                            FS_kin = FS_kin';
                        end
                        if size(FO_kin,1) == 1
                            FO_kin = FO_kin';
                        end

                        ExtendStimEvent = detFootStrike{cut} + rfsAnticipation_pts + stimDelay_pts;
                        FlexStimEvent = detFootOff{cut} + rfoAnticipation_pts + stimDelay_pts;

                        [histEdges,hitBins,negLen] = calcHeteroHistEdgesMulticlass({FO_kin, FS_kin}, ...
                                                                                    size(dataCuts{cut},1), ...
                                                                                    tolWin);

                        tmp = calcHeteroKardinalityMulticlass({FO_kin, FS_kin}, ...
                                                              {FlexStimEvent, ExtendStimEvent}, ....
                                                              tolWin, ...
                                                              histEdges, ...
                                                              hitBins, ...
                                                              negLen);

                        kardNo_hetero = kardNo_hetero + squeeze(tmp);

                    end
                end
                mutualInfo(dim,len,indS,regC) = calcMutInfoMulticlass_PriorNorm(kardNo_hetero);
                if verbose
                    disp(['Mutual information is calculated'])
                end
            
                
            end
        end
    end
end
    
    
    

end

