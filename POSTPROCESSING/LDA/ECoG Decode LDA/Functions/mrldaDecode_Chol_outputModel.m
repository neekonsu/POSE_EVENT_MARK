function model = mrldaDecode_Chol_outputModel(trainTrials,regParam)

% rldaDecode - decoder for reguralized linear discriminant analysis for any number of classes
%
% Input parameters:
%
% trainTrials - cell containing matrices of traing data for two classes
% testTrials - matrix of test trials
% regParam - regularization parameter
%
%
% Return parameters:
%
% decodedLabels - decoded labels
% logProb - log probabilities for each class
% prob - probability for each class
%

% Tomislav Milekovic, 09/03/2009

%% Validating input data
assert(iscell(trainTrials));

%% Building the training and validation data matrices for the cross-validation
model.noOfClass = length(trainTrials);
model.noOfFeature = size(trainTrials{1},1);
model.classMeans = nan(model.noOfFeature,model.noOfClass);
model.covInvMatrix = nan(model.noOfFeature);

noOfTrainTrials = 0;
for class = 1:model.noOfClass
    noOfTrainTrials = noOfTrainTrials + size(trainTrials{class},2);
end

%% Decoding

helpCovVect = nan(model.noOfFeature,noOfTrainTrials);
counter = 0;
for class = 1:model.noOfClass
    model.classMeans(:,class) = mean(trainTrials{class},2);
    tmpLen = size(trainTrials{class},2);
    helpCovVect(:,counter + 1:counter + tmpLen) = trainTrials{class} - repmat(model.classMeans(:,class),[1 tmpLen]);
    counter = counter + tmpLen;
end
classCov = cov(helpCovVect');

% Cholesky factorization will break down if the covariance matrix is
% singular and if no regularizetion is used
if (rank(classCov) < size(classCov,1)) && regParam == 0
	regParam = 1e-6;
	warning('rldaDecode_Chol:classCov',...
			'Covariance matrix singular! Using 1e-6 regularizetion instead of 0 to make it regular')
end

meanDiagClassCov = mean(diag(classCov));
classCovReg = (1 - regParam) * classCov + regParam * meanDiagClassCov * eye(model.noOfFeature);
model.covInvMatrix = inv(classCovReg);

