function model = buildEventsMulticlassLFPDetector(trainData, ...
                                               trainTrig, ...
                                               template, ...
                                               decMethod, ...
                                               deadTime, ...
                                               noOfNegTrain, ...
                                               regCoeff, ...
                                               srate, ...
                                               fftWinFunction, ...
                                               fftWinSize, ...
                                               norma, ...
                                               freqIndBottom, ...
                                               freqIndTop, ...
                                               SgfLength, ...
                                               sgfTemplate)
% Function calculating detection measure.
% Shiqi Sun
% 24.11.2017

% Setting the default deadTime
if (nargin < 5 || isempty(deadTime))
    assert(false);
end

% Set the number of trials used for training the negative class
if (nargin < 6 || isempty(noOfNegTrain))
    noOfNegTrain = 100000;
end

% Set the number of trials used for training the negative class
if (nargin < 7 || isempty(regCoeff))
    regCoeff = 0;
end

% Set the number of sessions used for training and testing 
noOfTrainSess = length(trainData);
noOfCh = size(trainData{1},2);
noOfTrig = size(trainTrig,2);
noOfClass = noOfTrig + 1;

noPosTrain = zeros(1,noOfTrig);
noAllTrain = 0;
for sess = 1:noOfTrainSess
    for trgInd = 1:noOfTrig
        noPosTrain(trgInd) = noPosTrain(trgInd) + length(trainTrig{sess,trgInd});
    end
    noAllTrain = noAllTrain + size(trainData{sess},1);
end

% Find the possible negative trial template starts for training
negTrainStarts = zeros(2,noAllTrain);
counter = 0;
for sess = 1:noOfTrainSess
    badInd = [1:deadTime size(trainData{sess},1) - deadTime:size(trainData{sess},1)];
    for trgInd = 1:noOfTrig
        for tr = 1:length(trainTrig{sess,trgInd})
            badInd = [badInd trainTrig{sess,trgInd}(tr) - deadTime:trainTrig{sess,trgInd}(tr) + deadTime];
        end
    end
    tmpNegStarts = setdiff(1:size(trainData{sess},1),badInd);
    
    negTrainStarts(1,counter + 1:counter + length(tmpNegStarts)) = sess;
    negTrainStarts(2,counter + 1:counter + length(tmpNegStarts)) = tmpNegStarts;
    counter = counter + length(tmpNegStarts);
end
negTrainStarts(:,counter + 1:end) = [];

if (size(negTrainStarts,2) > noOfNegTrain)
    permInd = randperm(size(negTrainStarts,2));
    negTrainStarts = negTrainStarts(:,permInd(1:noOfNegTrain));
else
    noOfNegTrain = size(negTrainStarts,2);
end

% Extracting training trials
trainTrails = cell(noOfClass,1);
for trgInd = 1:noOfTrig
    trainTrails{trgInd} = zeros(noPosTrain(trgInd),length(template) * 2 * noOfCh);
end
trainTrails{noOfClass} = zeros(noOfNegTrain,length(template) * 2 * noOfCh);

trialCounter = ones(noOfClass,1);
for sess = 1:noOfTrainSess
    for trgInd = 1:noOfTrig
        for ii = 1:length(trainTrig{sess,trgInd})
            if (trainTrig{sess,trgInd}(ii) + min(template) - max(fftWinSize,SgfLength) + 1 <= 0 || trainTrig{sess,trgInd}(ii) + max(template) > size(trainData{sess},1))
                continue;
            end

            for ch = 1:noOfCh
                tmpLfcFea = nan(1,length(template));
                tmpHfcFea = nan(1,length(template));
                for dim = 1:length(template)
                    % LFC
                    currentInd = trainTrig{sess,trgInd}(ii) + template(dim);
                    tmpLfcFea(dim)  = sgfTemplate * trainData{sess}(currentInd - SgfLength + 1:currentInd,ch);
                    % HFC
                    tmptrailData  = trainData{sess}(currentInd - fftWinSize + 1:currentInd,ch);
                    tmptrailData = fftWinFunction .* tmptrailData;
                    FFTrez=fft(tmptrailData);
                    normFFTrez = abs(FFTrez((1:ceil(fftWinSize/2+1))))./sqrt(srate)./norma(:, ch);
                    tmpHfcFea(dim) = sqrt(mean(normFFTrez(freqIndBottom:freqIndTop)));
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % still need to check how to normalize lfc
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                trainTrails{trgInd}(trialCounter(trgInd),(ch - 1) * 2*length(template) + 1:ch * 2*length(template)) = [tmpLfcFea tmpHfcFea];
            end
            trialCounter(trgInd) = trialCounter(trgInd) + 1;
        end
    end

    negInd = find(negTrainStarts(1,:) == sess);
    for ii = 1:length(negInd)
        if (negTrainStarts(2,negInd(ii)) + min(template) - max(fftWinSize,SgfLength) + 1 <= 0 || negTrainStarts(2,negInd(ii)) + max(template) > size(trainData{sess},1))
            continue;
        end

        for ch = 1:noOfCh
            tmpLfcFea = nan(1,length(template));
            tmpHfcFea = nan(1,length(template));
            for dim = 1:length(template)
                % LFC
                currentInd = negTrainStarts(2,negInd(ii)) + template(dim);
                tmpLfcFea(dim)  = sgfTemplate * trainData{sess}((currentInd - SgfLength + 1):currentInd,ch);
                % HFC
                tmptrailData  = trainData{sess}((currentInd - fftWinSize + 1):currentInd,ch);
                tmptrailData = fftWinFunction.* tmptrailData;
                FFTrez=fft(tmptrailData);
                normFFTrez = abs(FFTrez((1:ceil(fftWinSize/2+1))))./sqrt(srate)./norma(:, ch);
                tmpHfcFea(dim) = sqrt(mean(normFFTrez(freqIndBottom:freqIndTop)));
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % still need to check how to normalize lfc
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            trainTrails{noOfClass}(trialCounter(noOfClass),(ch - 1) * 2*length(template) + 1:ch * 2*length(template)) = [tmpLfcFea tmpHfcFea];
        end
        trialCounter(noOfClass) = trialCounter(noOfClass) + 1;
    end
end

for cl = 1:noOfClass
    trainTrails{cl}(trialCounter(cl):end,:) = [];
end

for cl = 1:noOfClass
    trainTrails{cl} = trainTrails{cl}';
end

% Calculating classification probability on test trials
if (strcmp(decMethod,'LDA'))
    error('Method not implemented');
    
elseif (strcmp(decMethod,'rLDA'))
    model = mrldaDecode_Chol_outputModel(trainTrails,regCoeff);
    
elseif (strcmp(decMethod,'QDA'))
    error('Method not implemented');

elseif (strcmp(decMethod,'rQDA'))
    error('Method not implemented');
    
else
    disp('Decoding method not available');
    assert(false);
end