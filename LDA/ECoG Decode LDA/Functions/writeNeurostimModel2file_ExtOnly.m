function fileID = writeNeurostimModel2file_ExtOnly(model, modelFilename)

format long e

fileID = fopen(modelFilename,'w');

fprintf(fileID,'%16e\n',model.noOfClass);
fprintf(fileID,'%16e\n',model.noOfFeature);
fprintf(fileID,'%16e\n',model.expectationThreshold);
fprintf(fileID,'%16e\n',model.refractoryPeriodSec);
fprintf(fileID,'%16e\n',model.noOfTaps);
fprintf(fileID,'%16e\n',model.modelType);
noOfCh = model.noOfFeature / model.noOfTaps;
for ch = 1:noOfCh
    fprintf(fileID,'%16e\n',model.selCh(ch));
end

fprintf(fileID,'%16e\n',model.templateSec);
if model.noOfClass == 3
    classOrder = [3 1 2];
elseif model.noOfClass == 5
    classOrder = [5 1 2 3 4];
else
    assert(false);
end

for cl = 1:model.noOfClass
    fprintf(fileID,'%16e\n',model.classMeans(:,classOrder(cl)));
end
for fi = 1:model.noOfFeature
    fprintf(fileID,'%16e\n',model.covInvMatrix(:,fi));
end

fprintf(fileID,'%16e\n',model.rightExtentionShift);
fprintf(fileID,'%16e\n',model.leftExtentionShift);

fclose(fileID);