function [output, relProb] = calcMuscleTypeDetectionProbabilities(inputData, Model)
% Function classify muscle activation type 
% Input :  
% inputData: matrix m*n, m:feature dimension, n:number of samples
% Model: classifier for muscle activation type
% Output :
% output: n*1, class output by the model
noOfSample = size(inputData,2);
noOfClass = Model.noOfClass;

logProb = nan(noOfSample,noOfClass);
relProb = nan(noOfSample,noOfClass);

cholMat = cholcov(Model.covInvMatrix);

for cl = 1:noOfClass
    distVect = inputData' - repmat(Model.classMeans(:,cl),[1 noOfSample])';
    
    tmpMat = cholMat * distVect';
    logProb(:,cl) = -sum(tmpMat.^2,1) / 2;
% 
%     for tr = 1:cumSesLen
%         logProb(tr,cl) = -distVect(tr,:) * stepDetectionModel.covInvMatrix * distVect(tr,:)' / 2;
%     end
end

for cl = 1:noOfClass
    logProbCl = logProb - repmat(logProb(:,cl),[1 noOfClass]);
    relProb(:,cl) = 1./sum(exp(logProbCl),2);
end
[~,output] = max(relProb');
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

