function [dividedInput,dividedOutput,dividedTimeLine] = divideTimeline(input,output,timeLine,noOfParts,verbose)

if (nargin<5)
    verbose = false;
end

if (~iscell(input))
    input = {input};
    
    if (~iscell(timeLine))
        timeLine = {timeLine};
    end
end

assert(length(input) == length(output))

noOfCells = length(input);

if (nargin<3 || isempty(timeLine))
    timeLine = cell(size(input));
    for cl = 1:noOfCells
        timeLine{cl} = 1:size(input{cl},1);
    end
end

if (noOfParts<=1)
    dividedInput = input;
    dividedOutput = output;
    dividedTimeLine = timeLine;
    return;
end

breakPoints = cell(size(input));
for cl = 1:noOfCells
    tmpInd = find(diff(timeLine{cl})>1);
    breakPoints{cl} = round((timeLine{cl}(tmpInd+1)+timeLine{cl}(tmpInd))/2);
    
    if (isempty(breakPoints{cl}) || length(breakPoints{cl})<noOfParts-1)
        if (verbose)
            warning('divideDataCells: Number of breaking points is smaller than the number of parts. Will cut the input in equal parts');
        end
        tmpPoints = round(linspace(1,length(timeLine{cl}),noOfParts+1));
        breakPoints{cl} = timeLine{cl}(tmpPoints(2:end-1));
    end 
end

dividedInput = cell(noOfCells*noOfParts,1);
dividedOutput = cell(noOfCells*noOfParts,1);
dividedTimeLine = cell(noOfCells*noOfParts,1);
counter = 0;
for cl = 1:noOfCells
    tmpPoints = round(linspace(0,length(breakPoints{cl})+1,noOfParts+1));
    tmpBreakPoints = breakPoints{cl}(tmpPoints(2:end-1));
    cutStart = [1; tmpBreakPoints(:)+1];
    cutEnd = [tmpBreakPoints(:); size(input{cl},1)];
    for ct = 1:noOfParts
        counter = counter+1;
        dividedInput{counter} = input{cl};
        dividedOutput{counter} = output{cl};
        dividedTimeLine{counter} = timeLine{cl}(timeLine{cl}>=cutStart(ct) & timeLine{cl}<=cutEnd(ct));
    end
end
