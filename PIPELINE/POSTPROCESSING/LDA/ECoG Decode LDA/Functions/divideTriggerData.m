function [ divData, divTriggers, breakPoints] = divideTriggerData( data, triggers,cutNoOfTriggers, noPerPart )
%DIVIDETRIGGERDATA divide cuts with a lot triggers into smaller parts.  
%For the cuts whose number of triggers is more than noPerPart, divide them 
%into smaller pieces.
%   input             - cell of data containing continous variables
%   trigger           - cell of data containing trigger cuts
%   cutNoOfTriggers   - number of triggers in each data cut
%   noPerPart         - number of triggers calculated by noOfDiv and noOfCV

% Shiqi Sun
% 18.10.2017
%
breakPoints = cell(size(data));
divData = [];
divTriggers = [];
noOfTrig = size(triggers,2);

cutsTobreak = find(cutNoOfTriggers > noPerPart);
counter = 1;
for cut = 1:length(data)
    if ismember(cut,cutsTobreak)
        tmpTrigger = [];
        for tr = 1:noOfTrig
            if size(triggers{cut,tr},1) == 1
                tmpTrigger = [tmpTrigger triggers{cut,tr}];
            else
                 tmpTrigger = [tmpTrigger triggers{cut,tr}'];
            end
        end
        [sortTrig, ~]= sort(tmpTrigger,'ascend');

        cutsOfDiv = ceil(length(tmpTrigger)/noPerPart);
        breakTrig = floor(linspace(1,length(tmpTrigger),cutsOfDiv+1));
        breakPoints{cut} = round((sortTrig(breakTrig(2:end-1))+sortTrig(breakTrig(2:end-1)+1))/2);

        tmpInd = [1 breakPoints{cut} size(data{cut},1)];
        for i = 1:length(tmpInd)-1
            divData{counter} = data{cut}(tmpInd(i):tmpInd(i+1)-1,:);
            for tr = 1:noOfTrig
                tmpTrig = triggers{cut,tr}(find(triggers{cut,tr}>=tmpInd(i) & triggers{cut,tr}<tmpInd(i+1)));
                divTriggers{counter,tr} = tmpTrig - tmpInd(i) +1;
            end
            counter = counter +1;
        end
    else
        divData{counter} = data{cut};
        for tr = 1:noOfTrig
            divTriggers{counter,tr} = triggers{cut,tr};
        end
        counter = counter + 1;
    end
    
end


end

