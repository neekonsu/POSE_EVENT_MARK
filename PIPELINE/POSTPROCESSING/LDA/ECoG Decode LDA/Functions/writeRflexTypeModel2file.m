function fileID = writeRflexTypeModel2file(model, modelFilename)

format long e

fileID = fopen(modelFilename,'w');

fprintf(fileID,'%16e\n',model.noOfClass);
fprintf(fileID,'%16e\n',model.noOfFeature);

fprintf(fileID,'%16e\n',model.noOfTaps);
noOfCh = model.noOfFeature / model.noOfTaps;

for ch = 1:noOfCh
    fprintf(fileID,'%16e\n',model.selCh(ch));
end

fprintf(fileID,'%16e\n',model.templateSec);

for cl = 1:model.noOfClass
    fprintf(fileID,'%16e\n',model.classMeans(:,cl));
end
for fi = 1:model.noOfFeature
    fprintf(fileID,'%16e\n',model.covInvMatrix(:,fi));
end


fclose(fileID);