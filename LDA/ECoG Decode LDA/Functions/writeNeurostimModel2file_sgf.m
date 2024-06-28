function fileID = writeNeurostimModel2file_sgf(model, modelFilename)

format long e

fileID = fopen(modelFilename,'w');

fprintf(fileID,'%16e\n',model.noOfClass);
fprintf(fileID,'%16e\n',model.noOfFeature);
fprintf(fileID,'%16e\n',model.expectationThreshold);
fprintf(fileID,'%16e\n',model.refractoryPeriodSec);
fprintf(fileID,'%16e\n',model.noOfTaps);
fprintf(fileID,'%16e\n',model.modelType);

fprintf(fileID,'%16e\n',model.neuralLpfSgLength);
fprintf(fileID,'%16e\n',model.sgfTemplate);
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

fprintf(fileID,'%16e\n',model.extentionShift);
fprintf(fileID,'%16e\n',model.flexionShift);

fclose(fileID);