function [histEdges,hitBins,negLen] = calcHeteroHistEdgesMulticlass(triggers,vectLength,tolWin)

if ~iscell(triggers)
    triggers = {triggers};
end

noOfTrig = length(triggers);
allTriggers = [];
allLabels = [];
hitBins = cell(noOfTrig,1);
for trg = 1:length(triggers)
    hitBins{trg} = nan(length(tolWin),length(triggers{trg}));
    allTriggers = [allTriggers; triggers{trg}];
    allLabels = [allLabels; trg * ones(length(triggers{trg}),1)];
end
[allTriggers,sortInd] = sort(allTriggers);
allLabels = allLabels(sortInd);

histEdges = cell(length(tolWin),1);
negLen = zeros(length(tolWin),1);

for tlw = 1:length(tolWin)
    halfWin = floor(tolWin(tlw) / 2);
    if ~isempty(allTriggers)
        extTrig = [1 - halfWin; allTriggers; vectLength + halfWin];
%         negLen(tlw) = negLen(tlw) + max(0,allTriggers(1) - halfWin - 1);
    else
        extTrig = [1 - halfWin; vectLength + halfWin];
        negLen(tlw) = negLen(tlw) + vectLength;
    end

    histEdges{tlw} = zeros(floor(vectLength / tolWin(tlw)),1);
    edgeCount = 0;
    trigCount = zeros(noOfTrig,1);
    for trig = 2:length(extTrig)
        spaceSize = extTrig(trig) - extTrig(trig - 1) - 2 * halfWin;
        if (spaceSize <= 0)
			histEdges{tlw}(edgeCount + 1) = round(mean(extTrig(trig-1:trig)));
			edgeCount = edgeCount + 1;
        else
            histEdges{tlw}(edgeCount + 1) = extTrig(trig - 1) + halfWin;
            histEdges{tlw}(edgeCount + 2) = extTrig(trig) - halfWin;
			edgeCount = edgeCount + 2;
            negLen(tlw) = negLen(tlw) + spaceSize;
        end
        
        if trig < length(extTrig)
            trigCount(allLabels(trig - 1)) = trigCount(allLabels(trig - 1)) + 1;
            hitBins{allLabels(trig - 1)}(tlw,trigCount(allLabels(trig - 1))) = edgeCount;
        end
    end
    histEdges{tlw}(edgeCount + 1:end) = [];
    histEdges{tlw}(1) = -halfWin;
    histEdges{tlw}(end) =  vectLength + halfWin;
    
%     if ~isempty(allTriggers)
%         negLen(tlw) = negLen(tlw) + max(0, vectLength - allTriggers(end) - halfWin + 1);
%     end
    negLen(tlw) = negLen(tlw) / tolWin(tlw);
end

