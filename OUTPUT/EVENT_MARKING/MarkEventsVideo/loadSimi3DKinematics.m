function [first_frame,num_frame,mrk,single_side] = loadSimi3DKinematics(filename, kinVar, outVar, startRow, endRow)

%% Initialize variables.
mrk = [];
delimiter = '\t';
if (nargin <= 5 || isempty(endRow))
    endRow = inf;
end

if (nargin <= 4 || isempty(startRow))
    startRow = 2;
end

%% Format string for each line of text:
% For more information, see the TEXTSCAN documentation.
headerSpec = '%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%[^\n\r]';
formatSpec = '%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%f%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to format string.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
kinHeader = textscan(fileID, headerSpec, 1, 'Delimiter', delimiter, 'ReturnOnError', false);
dataArray = textscan(fileID, formatSpec, endRow(1) - startRow(1) + 1, 'Delimiter', delimiter, 'HeaderLines', startRow(1) - 1, 'ReturnOnError', false);
for block = 2:length(startRow)
    frewind(fileID);
    dataArrayBlock = textscan(fileID, formatSpec, endRow(block) - startRow(block) + 1, 'Delimiter', delimiter, 'HeaderLines', startRow(block)-1, 'ReturnOnError', false);
    for col = 1:length(dataArray)
        dataArray{col} = [dataArray{col};dataArrayBlock{col}];
    end
end

first_frame = startRow - 1;
num_frame = length(dataArray{1});
single_side = 0;

%% Close the text file.
fclose(fileID);

%% Post processing for unimportable data.
% No unimportable data rules were applied during the import, so no post
% processing code is included. To generate code which works for
% unimportable data, select unimportable cells in a file and regenerate the
% script.

%% Allocate imported array to column variable names

dimVar = {'X','Y','Z'};
for ki = 1:length(kinVar)
    if strcmp(kinVar{ki},'Time')
        for ii = 1:length(kinHeader)
            if (strcmp(kinHeader{ii}{1},kinVar{ki}))
                mrk.time = dataArray{ii};
                break;
            end
        end
        
    else  
        for di = 1:length(dimVar)
            for ii = 1:length(kinHeader)
                if (strcmp(kinHeader{ii}{1},[kinVar{ki} ' ' dimVar{di}]))
                    mrk.(outVar{ki}).(lower(dimVar{di})) = dataArray{ii};
                    break;
                end
            end
        end
    end
end

