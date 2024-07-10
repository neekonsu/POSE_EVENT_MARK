function [MI, MI_Train, ParamOpt,str] = evaluateRLDA_NestCV(output,input, param, shiftParam,save_dir)
%EVALUATERLDA_NESTCV Summary of this function goes here
% Evaluate the decoder on an offline set of data. This is done by splitting
% the data into multiple parts, some used for callibration and some for
% testing. Callibration parts are used firstly for opimizating the shift,
% then for selection of parameters through
% the process of cross-validation. Once the parameter values are selected,
% the model is built from all callibration parts of the data. Model is then
% tested on the test data parts.
% Use in conjuction with functions:
%       searchRegularizedLDA
%       validateRegularizedLDA
%       buildStepDetection
%       calcStepDetectionProbabilities

%   output      - cell of data containing predictions
%   input       - cell of data containing variables
%   param       - structure containing parameters

% Shiqi Sun
% 30.07.2020

%%
noOfFeatDims = length(param.featureDim);
noOfTmplLen = length(param.featureLen);
noOfRegCoeff = length(param.regCoeff);
noOfindStarts = length(param.indStarts);

noOfDiv = param.testDivision;
noOfCV = param.noOfCV;
noOfTrigger = size(output,2);
sessToUse = 1:length(input);

plotDiagnostics = param.plotDiagnostics;

fout = fopen([save_dir filesep 'nestCVouput.txt'],'w');
%% Select and Divide Data to fit the division
cutNoOfTriggers = zeros(length(output),1);
for cut = sessToUse
    for tr =1:noOfTrigger
        cutNoOfTriggers(cut) = cutNoOfTriggers(cut) + length(output{cut,tr});
    end
end

idx2remove = find(cutNoOfTriggers == 0);
input(idx2remove) = [];
output(idx2remove,:) = [];
cutNoOfTriggers(idx2remove) = [];

noOfTriggers = sum(cutNoOfTriggers);
noOfParts = noOfDiv * noOfCV;
trigPerPart = floor(noOfTriggers/noOfParts);
[decInput,decOutput,~] = divideTriggerData( input,output,cutNoOfTriggers,trigPerPart);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   maybe plot the figure to test
cut2plot = randperm(length(decInput),1);
if plotDiagnostics
    figure
    hold on
%     plot(mean(decInput{cut2plot},2))
    plot(decInput{cut2plot}(:,end))
    for ii = 1:length(decOutput{cut2plot,1})
        plot(decOutput{cut2plot,1}(ii)*[1 1],[0 1],'r')
    end
%     set(gca,'ylim',[-10 size(decInput{cut2plot},2)],'xlim',[1 size(decInput{cut2plot},1)])
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Partition the cuts for tests
cutLen = zeros(length(decInput),1);
for cut = 1:length(decInput)
    cutLen(cut) = size(decInput{cut},1);
end
[sortLen, sortInd] = sort(cutLen,'descend');

targetLen = sum(cutLen) / noOfDiv;
testingScheme = cell(noOfDiv,1);
trainingScheme = cell(noOfDiv,1);
goPos = true;
currentInd = 0;
currentCutInd = 1;
while (~isempty(sortLen))
    if goPos
        if currentInd == noOfDiv
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
for i = 1:noOfDiv
    trainingScheme{i} = setdiff(1:length(decInput),testingScheme{i});
end
%% Allocating the output
MI = zeros(noOfDiv,1);
ParamOpt = cell(noOfDiv,1);
MI_Train = zeros(noOfDiv,noOfFeatDims,noOfTmplLen,noOfindStarts,noOfRegCoeff);

%% Doing the search through the parameter values

decParam = param;
decParam.noOfSchemes = param.noOfCV;
   

for scheme = 1:noOfDiv
    fprintf(fout,'==============  Start scheme %d ===============\r\n',scheme);
    % do shift optimization
    flag_shift = true;
    iniShift = shiftParam.iniShift;  
    while flag_shift
        str = getString();
        if strcmp(str,'y')==1
            newEventAnticipation = searchShiftOptLDA(decOutput(trainingScheme{scheme},:),...
                                                       decInput(trainingScheme{scheme}), ...
                                                       shiftParam, ...
                                                       iniShift);
%             iniShift = round(newEventAnticipation);
            iniShift = getNumber();
        else
            flag_shift = false;
        end
    end
    close all
    disp('Shift optimization is finished')
    disp(['Opt shift: ' num2str(iniShift)])
    fprintf(fout,'Shift optimization is finished \r\n');
    fprintf(fout,'Opt shift: %d %d \r\n', iniShift(1),iniShift(2));
    % do CV crossvalidation
    % modify the trigger
    modOutput = cell(size(decOutput));
    noOfCuts = length(decInput);
    for ii = 1:noOfTrigger
        for cut = 1:noOfCuts
            modOutput{cut,ii} = decOutput{cut,ii} + iniShift(ii);
            modOutput{cut,ii}(modOutput{cut,ii} <= 0 | modOutput{cut,ii} > size(decInput{cut},1)) = [];
        end
    end
    
    
    [MI_S] = searchRegularizedLDA(modOutput(trainingScheme{scheme},:), ...
                                  decInput(trainingScheme{scheme}), ...
                                  decParam, ...
                                  decParam.verbose);
                                                           
    [~,maxInd] = max(MI_S(:));
    [bestDim,bestLen,bestIndStarts,bestRegC] = ind2sub(size(MI_S),maxInd);

    MI_Train(scheme,:,:,:,:,:) = MI_S;

    validParam = param;
    validParam.featureDim = param.featureDim(bestDim);
    validParam.featureLen = param.featureLen(bestLen);
    validParam.regCoeff = param.regCoeff(bestRegC);
    validParam.indStarts = param.indStarts(bestIndStarts);
    
    disp('Cross validation for parameter selection is finished')
    disp(['Opt feature dim: ' num2str(validParam.featureDim)])
    disp(['Opt feature len: ' num2str(validParam.featureLen)])
    disp(['Opt feature regC: ' num2str(validParam.regCoeff)])
    disp(['Opt indStarts: ' num2str(validParam.indStarts)])
    
    fprintf(fout,'Parameter selection is finished \r\n');
    fprintf(fout,'Opt feature (dim, len, regC): %d %d %.2f \r\n', validParam.featureDim, validParam.featureLen, validParam.regCoeff);
    
    ParamOpt{scheme} = validParam;
    saveDir = [save_dir filesep 'scheme' num2str(scheme) filesep];
    mkdir(saveDir)
    [MI(scheme)] = validateRegularizedLDA(decOutput(trainingScheme{scheme},:), ...
                                          decInput(trainingScheme{scheme}), ...
                                          decOutput(testingScheme{scheme},:), ...
                                          decInput(testingScheme{scheme}), ...
                                          validParam,...
                                          saveDir);
    disp(['validation is finished, MI = ' num2str(MI(scheme))])
    
    fprintf(fout,'validation is finished, MI = %.4f \r\n', MI(scheme));
    
    if param.verbose
        disp([])
        disp(['%%%%%%%%%%%%%%%%   Scheme ' num2str(scheme) ' is calculated    %%%%%%%%%%%%%%%%%%%%%'])
        disp([])
    end
end

fclose(fout);
end

