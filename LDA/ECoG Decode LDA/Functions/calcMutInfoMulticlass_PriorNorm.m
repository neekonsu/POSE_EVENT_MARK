function [grpMutInfo,mutInfo,priorEntropy] = calcMutInfoMulticlass_PriorNorm(allKard)

matDim = ndims(allKard);
noOfClass = size(allKard,matDim);
assert(size(allKard,matDim) == size(allKard,matDim-1));
priorDim = matDim-1;
posteriorDim = matDim;

repSize = ones(1,matDim);
repSize([priorDim posteriorDim]) = noOfClass;
totKard = repmat(nansum(nansum(allKard,priorDim),posteriorDim),repSize);
normKard = allKard./totKard;
prior = nansum(normKard,posteriorDim);
posterior = nansum(normKard,priorDim);
jointProb = normKard;

repSize1 = ones(1,matDim);
repSize1(posteriorDim) = noOfClass;
repSize2 = ones(1,matDim);
repSize2(priorDim) = noOfClass;
mutInfo = jointProb .* log2(jointProb ./ (repmat(prior,repSize1) .* repmat(posterior,repSize2)));
mutInfo = nansum(nansum(mutInfo,priorDim),posteriorDim);

priorEntropy = prior;
priorEntropy = priorEntropy.*log2(priorEntropy);
priorEntropy = -nansum(priorEntropy,priorDim);

grpMutInfo = zeros(size(mutInfo));
goodInd = find(priorEntropy ~= 0);
badInd = find(priorEntropy == 0);
if (~isempty(goodInd))
    grpMutInfo(goodInd) = mutInfo(goodInd) ./ priorEntropy(goodInd);
end

if (~isempty(badInd))
    mutInfo(badInd) = 0;
end
