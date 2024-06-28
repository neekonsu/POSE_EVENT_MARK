function [neuralDataDec,hand_triggers,DP] = nestCV_extractDecData(neuralDataDS,trft_normMean,triggersCuts,DP,H)
%NESTCV_EXTRACTDECDATA Summary of this function goes here
%   Detailed explanation goes here
chUsed = DP.chUsed;
[trft_all,DP.trft_frequencies,decInd,blkInd] = baselineAmplitude_SE(neuralDataDS, ...
                                                  trft_normMean, ...
                                                  [], ...
                                                  DP.offsetBase, ...
                                                  DP.fftWinSize, ...
                                                  DP.fftDecStep, ...
                                                  H.sampleRate, ...
                                                  DP.fftWinFunction);
DP.freqIndBottom = zeros(size(DP.decFreqBand,1),1);
DP.freqIndTop = zeros(size(DP.decFreqBand,1),1);
DP.frequencyBottom = zeros(size(DP.decFreqBand,1),1);
DP.frequencyTop = zeros(size(DP.decFreqBand,1),1);

nrBand = size(DP.decFreqBand,1);
trftBand = nan(nrBand,length(chUsed),size(trft_all,3));
for i = 1:nrBand
    indBand = find(DP.trft_frequencies>=DP.decFreqBand(i,1) & DP.trft_frequencies<=DP.decFreqBand(i,2));
    DP.freqIndBottom(i) = indBand(1);
    DP.freqIndTop(i) = indBand(end);

    if DP.freqIndBottom(i) > 1
        DP.frequencyBottom(i) = mean(DP.trft_frequencies(DP.freqIndBottom(i)-1:DP.freqIndBottom(i)));
    else
        DP.frequencyBottom(i) = 0;
    end

    if DP.freqIndTop(i) < length(DP.trft_frequencies)
        DP.frequencyTop(i) = mean(DP.trft_frequencies(DP.freqIndTop(i):DP.freqIndTop(i) + 1));
    else
        DP.frequencyTop(i) = DP.trft_frequencies(end);
    end

    trftBand(i,:,:) = sqrt(squeeze(mean(trft_all(DP.freqIndBottom:DP.freqIndTop,chUsed,:),1)));
end
trftBand = reshape(trftBand, nrBand*length(chUsed), size(trft_all,3));
DP.decInd = decInd;
DP.blkInd = blkInd;
DP.normMean = trft_normMean;

clear trft_all;

neuralDataDec = cell(1,H.noOfCuts);
for blk = 1:H.noOfCuts
    neuralDataDec{blk} = trftBand(:, blkInd == blk)';
end

clear trftBand;

disp('Completed calculating STFT');

hand_triggers = cell(H.noOfCuts,4);

for cut = 1:H.noOfCuts
    tmpInd = decInd(blkInd==cut);
    
    for ii = 1:length(triggersCuts.corrFootStrikeRight{cut})
        [~,minInd] = min(abs(triggersCuts.corrFootStrikeRight{cut}(ii) - tmpInd));
        if (~isempty(minInd))
            hand_triggers{cut,1}(ii) = minInd;
        end
    end
    
    for ii = 1:length(triggersCuts.corrToeOffRight{cut})
        [~,minInd] = min(abs(triggersCuts.corrToeOffRight{cut}(ii) - tmpInd));
        if (~isempty(minInd))
            hand_triggers{cut,2}(ii) = minInd;
        end
    end
    
    for ii = 1:length(triggersCuts.corrFootStrikeLeft{cut})
        [~,minInd] = min(abs(triggersCuts.corrFootStrikeLeft{cut}(ii) - tmpInd));
        if (~isempty(minInd))
            hand_triggers{cut,3}(ii) = minInd;
        end
    end
    
    for ii = 1:length(triggersCuts.corrToeOffLeft{cut})
        [~,minInd] = min(abs(triggersCuts.corrToeOffLeft{cut}(ii) - tmpInd));
        if (~isempty(minInd))
            hand_triggers{cut,4}(ii) = minInd;
        end
    end
end

disp('Match the triggers');
end

