function model = readNeurostimModelFile(modelFilename)

fileID = fopen(modelFilename,'r');

model.noOfClass = fscanf(fileID,'%16e\n',1);
model.noOfFeature = fscanf(fileID,'%16e\n',1);
model.expectationThreshold = fscanf(fileID,'%16e\n',1);
model.refractoryPeriodSec = fscanf(fileID,'%16e\n',1);
model.noOfTaps = fscanf(fileID,'%16e\n',1);
model.modelType = fscanf(fileID,'%16e\n',1);
model.templateSec = fscanf(fileID,'%16e\n',model.noOfTaps);
model.classMeans = nan(model.noOfFeature,model.noOfClass);
if model.noOfClass == 3
    classOrder = [3 1 2];
elseif model.noOfClass == 5
    classOrder = [5 1 2 3 4];
else
    assert(false);
end

for cl = 1:model.noOfClass
    model.classMeans(:,classOrder(cl)) = fscanf(fileID,'%16e\n',model.noOfFeature);
end
model.covInvMatrix = nan(model.noOfFeature,model.noOfFeature);
for fi = 1:model.noOfFeature
    model.covInvMatrix(:,fi) = fscanf(fileID,'%16e\n',model.noOfFeature);
end

model.extentionShift = fscanf(fileID,'%16e\n',1);
model.flexionShift = fscanf(fileID,'%16e\n',1);

fclose(fileID);