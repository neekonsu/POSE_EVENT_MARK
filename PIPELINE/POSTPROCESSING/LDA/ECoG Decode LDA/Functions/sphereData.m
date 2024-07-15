function [sphearedData,grandMean,grandStd] = sphereData(inputData,grandMean,grandStd)

if (~iscell(inputData))
    inputData = {inputData};
end

noOfSess = length(inputData);
sphearedData = cell(size(inputData));
counter = 1;
while (isempty(inputData{counter}))
    counter = counter + 1;
end
noOfChannels = size(inputData{counter},1);

if (nargin < 2)

    grandSum = zeros(noOfChannels,1);
    grandCount = 0;
    for ii = 1:noOfSess
        if (~isempty(inputData{ii}))
            inputData{ii}(isnan(inputData{ii})) = 0;
            grandSum = grandSum + sum(inputData{ii},2);
            grandCount = grandCount + size(inputData{ii},2);
        end
    end
    grandMean = grandSum./grandCount;

    grandVar = zeros(noOfChannels,1);
    for ii = 1:noOfSess
        if (~isempty(inputData{ii}))
            sphearedData{ii} = inputData{ii} - repmat(grandMean,[1 size(inputData{ii},2)]);
            grandVar = grandVar+sum(inputData{ii}.^2,2);
        end
    end
    grandStd = (grandVar./grandCount).^0.5;

    for ii = 1:noOfSess
        if (~isempty(inputData{ii}))
            sphearedData{ii} = (inputData{ii} - repmat(grandMean,[1 size(inputData{ii},2)]))./repmat(grandStd,[1 size(inputData{ii},2)]);
        end
    end
    
else 
    for ii = 1:noOfSess
        if (~isempty(inputData{ii}))
            sphearedData{ii} = (inputData{ii} - repmat(grandMean,[1 size(inputData{ii},2)]))./repmat(grandStd,[1 size(inputData{ii},2)]);
        end
    end
end
    
    