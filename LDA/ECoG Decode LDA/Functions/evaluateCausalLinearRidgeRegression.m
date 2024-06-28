function [totCC,totR2,corrCoefs_Train,r2Coef_Train] = evaluateCausalLinearRidgeRegression(output, ...
                                                                                          input, ...
                                                                                          timeLine, ...
                                                                                          param)
% Evaluate the decoder on an offline set of data. This is done by splitting
% the data into multiple parts, some used for callibration and some for
% testing. Callibration parts are used for selection of parameters through
% the process of cross-validation. Once the parameter values are selected,
% the model is built from all callibration parts of the data. Model is then
% tested on the test data parts.
% Use in conjuction with functions:
%       searchCausalLinearRegression
%       validateCausalLinearRegression
%       decodeCausalLinearRegression

%   output      - cell of data containing predictions
%   input       - cell of data containing variables
%   timeLine    - cell of indices that one is trying to predict
%   param       - structure containing parameters

% Tomislav Milekovic
% 13.12.2011

if (~isfield(param,'permuteSessions') || isempty(param.permuteSessions))
    param.permuteSessions = false;
end

if (~isfield(param,'cutAlgorithm') || isempty(param.cutAlgorithm))
    param.cutAlgorithm = 'equalCuts';
end


%% Making sure that the input cells have the proper size
assert(iscell(output));
assert(iscell(input));
assert(length(output) == length(input));

%% Asserting that time line is present or building a default one

if (isempty(timeLine) || ~iscell(timeLine))
    timeLine = cell(size(input));
    for tr = 1:length(input)
        timeLine{tr} = 1:size(input{tr},1);
    end
else
    assert(length(timeLine) == length(input));
end


%% Divide sessions into parts suitable for cross-validation
        
if (strcmp(param.cutAlgorithm,'equalCuts'))
    noOfParts = lcm(length(output), param.testDivision*param.noOfCV)/length(output);
    [input,output,timeLine] = divideTimeline(input,output,timeLine,noOfParts);
    
elseif (strcmp(param.cutAlgorithm,'big2small'))
    while (lcm(length(output), param.testDivision * param.noOfCV) ~= length(output))
        noOfCuts = length(timeLine);
        timeLineLen = nan(noOfCuts,1);
        for cut = 1:noOfCuts
            timeLineLen(cut) = length(timeLine{cut});
        end
        
        [~,maxLen] = max(timeLineLen);
        inputTmp = input(maxLen);
        outputTmp = output(maxLen);
        timeLineTmp = timeLine(maxLen);
        
        [inputTmp,outputTmp,timeLineTmp] = divideTimeline(inputTmp,outputTmp,timeLineTmp,2);
        input(maxLen + 2:noOfCuts + 1) = input(maxLen + 1:noOfCuts);
        output(maxLen + 2:noOfCuts + 1) = output(maxLen + 1:noOfCuts);
        timeLine(maxLen + 2:noOfCuts + 1) = timeLine(maxLen + 1:noOfCuts);
        input(maxLen:maxLen + 1) = inputTmp;
        output(maxLen:maxLen + 1) = outputTmp;
        timeLine(maxLen:maxLen + 1) = timeLineTmp;
    end
end

noOfFeatDims = length(param.featureDim);
noOfTmplLen = length(param.templateLength);
noOfFeatOffset = length(param.featureOffset);
noOfFilt = length(param.halfWidth);
noOfRidge = length(param.ridgeCoeff);
noOfDiv = param.testDivision;
noOfReperm = param.noOfRepermutations;
noOfSchemes = noOfDiv * noOfReperm;
sessToUse = 1:length(input);


%% Setting up the training and testing schemes

trainingScheme = cell(noOfSchemes,1);
testingScheme = cell(noOfSchemes,1);

assert(noOfDiv <= length(sessToUse));
sessPerScheme = floor(length(sessToUse) / noOfDiv);
sessRes = mod(length(sessToUse),noOfDiv);

if (~param.permuteSessions)
    assert(noOfReperm == 1)
else
    assert(param.permuteSessions);
end

for prm = 1:noOfReperm
    sessOrder = 1:length(input);
    if (param.permuteSessions)
        rng('shuffle');
        sessOrder = sessOrder(randperm(length(sessOrder)));
    end

    counter = 0;
    for divInd = 1:noOfDiv
        if (divInd <= sessRes)
            testInd = counter + 1:counter+sessPerScheme + 1;
            trainInd = setdiff(1:length(sessOrder),testInd);
            testingScheme{divInd + noOfDiv * (prm - 1)} = sessOrder(testInd);
            trainingScheme{divInd + noOfDiv * (prm - 1)} = sessOrder(trainInd);
            counter = counter + sessPerScheme + 1;
        else
            testInd = counter + 1:counter + sessPerScheme;
            trainInd = setxor(1:length(sessOrder),testInd);
            testingScheme{divInd + noOfDiv * (prm - 1)} = sessOrder(testInd);
            trainingScheme{divInd + noOfDiv * (prm - 1)} = sessOrder(trainInd);
            counter = counter + sessPerScheme;
        end
    end
end


%% Allocating the output
corrCoefs = zeros(noOfSchemes,1);
r2Coef = zeros(noOfSchemes,1);

corrCoefs_Train = zeros(noOfSchemes,noOfFilt,noOfFeatDims,noOfTmplLen,noOfFeatOffset,noOfRidge);
r2Coef_Train = zeros(size(corrCoefs_Train));

%% Doing the search through the parameter values

decParam = param;
decParam.noOfSchemes = param.noOfCV;

for scheme = 1:noOfSchemes
    [corrCoefs_S,r2Coef_S] = searchCausalLinearRidgeRegression(output(trainingScheme{scheme}), ...
                                                               input(trainingScheme{scheme}), ...
                                                               timeLine(trainingScheme{scheme}), ...
                                                               decParam, ...
                                                               decParam.verbose);
    [~,maxInd] = max(r2Coef_S(:));
    [bestFilt,bestDim,bestLen,bestOffset,bestRidge] = ind2sub(size(r2Coef_S),maxInd);
    
    corrCoefs_Train(scheme,:,:,:,:,:) = corrCoefs_S;
    r2Coef_Train(scheme,:,:,:,:,:) = r2Coef_S;
    
    validParam = param;
    validParam.halfWidth = param.halfWidth(bestFilt);
    validParam.featureDim = param.featureDim(bestDim);
    validParam.templateLength = param.templateLength(bestLen);
    validParam.featureOffset = param.featureOffset(bestOffset);
    validParam.ridgeCoeff = param.ridgeCoeff(bestRidge);
    
    [corrCoefs(scheme),r2Coef(scheme)] = validateCausalLinearRidgeRegression(output(trainingScheme{scheme}), ...
                                                                             input(trainingScheme{scheme}), ...
                                                                             output(testingScheme{scheme}), ...
                                                                             input(testingScheme{scheme}), ...
                                                                             timeLine(trainingScheme{scheme}), ...
                                                                             timeLine(testingScheme{scheme}), ...
                                                                             validParam);
end

totCC = nanmean(corrCoefs);
totR2 = nanmean(r2Coef);

