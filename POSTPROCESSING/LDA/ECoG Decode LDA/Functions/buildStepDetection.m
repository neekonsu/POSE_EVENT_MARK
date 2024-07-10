function model = buildStepDetection(data,triggerTrain,param)

if (~isfield(param,'regCoeff') || isempty(param.regCoeff))
    param.regCoeff = 0;
end

if (~isfield(param,'blocksToUse') || isempty(param.blocksToUse))
    param.blocksToUse = 1:length(data);
end

%% Making sure that the input cells have the proper size
assert(iscell(data));
assert(iscell(triggerTrain));
assert(length(data) == size(triggerTrain,1));

%% Cheking the size of parameters
assert(length(param.featureDim) == 1);
assert(length(param.featureLen) == 1);
assert(length(param.indStarts) == 1);
assert(length(param.regCoeff) == 1);

%% Running the building algorithm

if param.featureDim == 1
	template = param.indStarts;
else
    if (param.featureLen == 0)
        error('Feature envelope length cannot be 0 for models using multiple taps!');
    else
%         % Non-causal arrangement
%         template = param.indStarts + round(linspace(0, param.featureLen - 1, param.featureDim));

        % Causal arrangement
        template = param.indStarts + round(linspace(0, -param.featureLen, param.featureDim));
    end
end

model = buildEventsMulticlassDetector(data(param.blocksToUse),...
                                      triggerTrain(param.blocksToUse,:),...
                                      template,...
                                      param.detectMethod,...
                                      param.deadTime,...
                                      param.noOfNegTrain,...
                                      param.regCoeff);

model.noOfTaps = length(template);
model.templateSec = template / param.sampleRate;
model.expectationThreshold = param.treshVal;
model.refractoryPeriodSec = param.refractorySec;
                

