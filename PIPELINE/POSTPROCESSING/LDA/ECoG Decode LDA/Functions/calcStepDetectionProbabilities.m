function [relProb,testInd,testCut,testTrials] = calcStepDetectionProbabilities(inputData, ...
                                                                               stepDetectionModel, ...
                                                                               sampleRate)
% Function calculating probabilities for a step detection model
if (~iscell(inputData))
    inputData = {inputData};
end

% Set the number of sessions used for training and testing 
noOfTestSess = length(inputData);
noOfCh = size(inputData{1},2);
noOfClass = stepDetectionModel.noOfClass;
template = round(stepDetectionModel.templateSec * sampleRate);

noAllTest = 0;
for sess = 1:noOfTestSess
    noAllTest = noAllTest + size(inputData{sess},1);
end

% Define the template for the detection
template_detection = template - max(template);

% Extracting testing trials
testTrials = zeros(noAllTest, length(template_detection) * noOfCh);
testInd = zeros(noAllTest, 1);
testCut = zeros(noAllTest, 1);
cumSesLen = 0;
for sess = 1:noOfTestSess
    startSes = 1 - min([template_detection(:); 0]);
    endSess = size(inputData{sess},1) - max([template_detection(:); 1]) + 1;
    sesSize = endSess - startSes + 1;
    
    if (sesSize <= 0)
        continue;
    end
    
    testInd(cumSesLen + 1:cumSesLen + sesSize) = (startSes:endSess) + max([template_detection(:); 1]) - 1;
    testCut(cumSesLen + 1:cumSesLen + sesSize) = sess;
    for ch = 1:noOfCh
        for ii = 1:length(template_detection)
            testTrials(cumSesLen + 1:cumSesLen + sesSize,(ch-1) * length(template_detection) + ii) = inputData{sess}((startSes:endSess) + template_detection(ii),ch);
        end
    end

    cumSesLen = cumSesLen + sesSize;
end
testTrials(cumSesLen+1:end,:) = [];
testInd(cumSesLen+1:end) = [];
testCut(cumSesLen+1:end) = [];

logProb = nan(cumSesLen,noOfClass);
relProb = nan(cumSesLen,noOfClass);

% cholMat = cholcov(stepDetectionModel.covInvMatrix);

for cl = 1:noOfClass
    distVect = testTrials - repmat(stepDetectionModel.classMeans(:,cl),[1 cumSesLen])';
    
%     tmpMat = cholMat * distVect';
%     logProb(:,cl) = -sum(tmpMat.^2,1) / 2;
% 
    for tr = 1:cumSesLen
        logProb(tr,cl) = -distVect(tr,:) * stepDetectionModel.covInvMatrix * distVect(tr,:)' / 2;
    end
end

for cl = 1:noOfClass
    logProbCl = logProb - repmat(logProb(:,cl),[1 noOfClass]);
    relProb(:,cl) = 1./sum(exp(logProbCl),2);
end

% tic
% for tr = 1:cumSesLen
%     tmp1(tr) = -distVect(tr,:) * stepDetectionModel.covInvMatrix * distVect(tr,:)' / 2;
% end
% toc
% 
% tic
% tmpMat = cholMat * distVect';
% tmp2 = -sum(tmpMat.^2,1) / 2;
% toc
% 
% cholMat = cholcov(stepDetectionModel.covInvMatrix);
% tic
% for tr = 1:cumSesLen
%     tmp2(tr) = -norm(cholMat * distVect(tr,:)') / 2;
% end
% toc

