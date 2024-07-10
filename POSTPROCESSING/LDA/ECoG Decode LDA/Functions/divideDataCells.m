function [dividedData,dividedTimeLine,originalBlock,originalTimeLine] = divideDataCells(data,noOfParts,timeLine,verbose)

if (nargin < 4)
    verbose = false;
end

if (~iscell(data))
    data = {data};
    
    if (~iscell(timeLine))
        timeLine = {timeLine};
    end
end

noOfCells = length(data);

if (nargin<3 || isempty(timeLine))
    timeLine = cell(size(data));
    for cl = 1:noOfCells
        timeLine{cl} = 1:size(data{cl},1);
    end
end

if (noOfParts <= 1)
    dividedData = data;
    dividedTimeLine = timeLine;
    originalBlock = nan(noOfCells * noOfParts,1);
    originalTimeLine = cell(noOfCells * noOfParts,1);
    for cut = 1:noOfCells
        originalBlock(cut) = cut;
        originalTimeLine{cut} = timeLine{cut};
    end
    
    return;
end

breakPoints = cell(size(data));
for cl = 1:noOfCells
    tmpInd = find(diff(timeLine{cl}) > 1);
    breakPoints{cl} = round((timeLine{cl}(tmpInd+1) + timeLine{cl}(tmpInd)) / 2);
    
    if (isempty(breakPoints{cl}) || length(breakPoints{cl})<noOfParts-1)
        if (verbose)
            warning('divideDataCells: Number of breaking points is smaller than the number of parts. Will cut the data in equal parts');
        end
        tmpPoints = round(linspace(1,length(timeLine{cl}),noOfParts+1));
        breakPoints{cl} = timeLine{cl}(tmpPoints(2:end-1));
    end 
end

dividedData = cell(noOfCells*noOfParts,1);
dividedTimeLine = cell(noOfCells*noOfParts,1);
originalBlock = nan(noOfCells*noOfParts,1);
originalTimeLine = cell(noOfCells*noOfParts,1);
counter = 0;
for cl = 1:noOfCells
    tmpPoints = round(linspace(0,length(breakPoints{cl})+1,noOfParts+1));
    tmpBreakPoints = breakPoints{cl}(tmpPoints(2:end-1));
    cutStart = [1; tmpBreakPoints(:)+1];
    cutEnd = [tmpBreakPoints(:); size(data{cl},1)];
    for ct = 1:noOfParts
        counter = counter+1;
        dividedData{counter} = data{cl}(cutStart(ct):cutEnd(ct),:);
        dividedTimeLine{counter} = timeLine{cl}(timeLine{cl}>=cutStart(ct) & timeLine{cl}<=cutEnd(ct)) - cutStart(ct) + 1;
        originalBlock(counter) = cl;
        originalTimeLine{counter} = timeLine{cl}(timeLine{cl}>=cutStart(ct) & timeLine{cl}<=cutEnd(ct));
    end
end
