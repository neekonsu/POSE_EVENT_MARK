function [relProb,testInd,testCut,testTrials] = calcLFPStepDetectionProbabilities(inputData, ...
                                                                               stepDetectionModel, ...
                                                                               sampleRate)
% Shiqi Sun
% 24.11.2017

% Function calculating probabilities for a step detection model
if (~iscell(inputData))
    inputData = {inputData};
end

% Set the number of sessions used for training and testing 
noOfTestSess = length(inputData);
noOfCh = size(inputData{1},2);
noOfClass = stepDetectionModel.noOfClass;
template = round(stepDetectionModel.templateSec * sampleRate);

fftWinSize = stepDetectionModel.fftWinSize;
fftWinFunction = stepDetectionModel.fftWinFunction;
freqIndBottom = stepDetectionModel.freqIndBottom;
freqIndTop = stepDetectionModel.freqIndTop;
norma = stepDetectionModel.norma;

sgfLength = stepDetectionModel.neuralLpfSgLength;
sgfTemplate = stepDetectionModel.sgfTemplate;

noAllTest = 0;
for sess = 1:noOfTestSess
    noAllTest = noAllTest + size(inputData{sess},1);
end

% Define the template for the detection
template_detection = template - max(template);

% Extracting testing trials
testTrials = zeros(noAllTest, 2*length(template_detection) * noOfCh);
testInd = zeros(noAllTest, 1);
testCut = zeros(noAllTest, 1);
cumSesLen = 0;
for sess = 1:noOfTestSess
    startSes = max(fftWinSize, sgfLength) - min([template_detection(:); 0]);
    endSess = size(inputData{sess},1) - max([template_detection(:); 1]) + 1;
    sesSize = endSess - startSes + 1;
    
    if (sesSize <= 0)
        continue;
    end
    
    testInd(cumSesLen + 1:cumSesLen + sesSize) = (startSes:endSess) + max([template_detection(:); 1]) - 1;
    testCut(cumSesLen + 1:cumSesLen + sesSize) = sess;
    
    for ii = startSes:endSess
        for ch = 1:noOfCh
            tmpLfcFea = nan(1,length(template_detection));
            tmpHfcFea = nan(1,length(template_detection));
            for dim = 1:length(template_detection)
                % LFC
                currentInd = ii + template_detection(dim);
                tmpLfcFea(dim)  = sgfTemplate * inputData{sess}(currentInd - sgfLength + 1:currentInd,ch);
                % HFC
                tmptrailData  = inputData{sess}(currentInd - fftWinSize + 1:currentInd,ch);
                tmptrailData = fftWinFunction .* tmptrailData;
                FFTrez=fft(tmptrailData);
                normFFTrez = abs(FFTrez((1:ceil(fftWinSize/2+1))))./sqrt(sampleRate)./norma(:, ch);
                tmpHfcFea(dim) = sqrt(mean(normFFTrez(freqIndBottom:freqIndTop)));
            end
            testTrials(cumSesLen +ii-startSes+1, (ch-1) * 2*length(template_detection) + 1:ch * 2*length(template_detection)) = [tmpLfcFea tmpHfcFea];
        end
    end

    cumSesLen = cumSesLen + sesSize;
end
testTrials(cumSesLen+1:end,:) = [];
testInd(cumSesLen+1:end) = [];
testCut(cumSesLen+1:end) = [];

logProb = nan(cumSesLen,noOfClass);
relProb = nan(cumSesLen,noOfClass);

for cl = 1:noOfClass
    distVect = testTrials - repmat(stepDetectionModel.classMeans(:,cl),[1 cumSesLen])';
    for tr = 1:cumSesLen
        logProb(tr,cl) = -distVect(tr,:) * stepDetectionModel.covInvMatrix * distVect(tr,:)' / 2;
    end
end

for cl = 1:noOfClass
    logProbCl = logProb - repmat(logProb(:,cl),[1 noOfClass]);
    relProb(:,cl) = 1./sum(exp(logProbCl),2);
end