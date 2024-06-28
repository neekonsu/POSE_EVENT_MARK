function kardinality = calcHeteroKardinalityMulticlass(triggers, ...
                                                       finalDetPos, ...
                                                       tolWin, ...
                                                       histEdges, ...
                                                       hitBins, ...
                                                       negLen)

noOfClass = length(triggers) + 1;
kardinality = nan(length(tolWin),noOfClass,noOfClass);

for tlw = 1:length(tolWin)
    tmpHitBins = cell(noOfClass,1);
    tmpHitBins{noOfClass} = 1:length(histEdges{tlw});
    for trig = 1:noOfClass - 1
        tmpHitBins{trig} = hitBins{trig}(tlw,:);
        tmpHitBins{noOfClass} = setdiff(tmpHitBins{noOfClass},hitBins{trig}(tlw,:));
    end
    
    count = nan(length(histEdges{tlw}),noOfClass - 1);
    for trig = 1:noOfClass - 1
        if ~isempty(finalDetPos{trig})
            count(:,trig) = histc(finalDetPos{trig},histEdges{tlw}) > 0;
        else
            count(:,trig) = zeros(length(histEdges),1);
        end
    end
    totCount = sum(count,2);
    badInd = find(totCount > 1);
    
    for trig = 1:noOfClass - 1
        for clDec = 1:noOfClass
            kardinality(tlw,clDec,trig) = sum(count(tmpHitBins{clDec},trig));
            if trig == clDec
                badKard = length(intersect(badInd,tmpHitBins{clDec}));
                kardinality(tlw,clDec,trig) = kardinality(tlw,clDec,trig) - badKard;
            end
        end
    end
    
    for clDec = 1:noOfClass - 1
        kardinality(tlw,clDec,noOfClass) = length(tmpHitBins{clDec}) - sum(kardinality(tlw,clDec,1:noOfClass - 1));
    end
    kardinality(tlw,noOfClass,noOfClass) = negLen - sum(kardinality(tlw,end,1:noOfClass - 1));
end
