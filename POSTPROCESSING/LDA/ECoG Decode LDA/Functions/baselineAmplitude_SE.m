function [baselineAmp,frequencies,indices,blockIndices] = baselineAmplitude_SE(data, ...
                                                                               norma, ...
                                                                               triggers, ...
                                                                               offset, ...
                                                                               winSize, ...
                                                                               step, ...
                                                                               srate, ...
                                                                               windowFunc, ...
                                                                               chosenBlocks, ...
                                                                               useFreqwiseNorm)
% function baselineAmplitude - calculate amplitudes for sessioned
% multichanneled data and concatinating it into a matrix
%
% syntax:
% baselineAmp = baselineAmplitude(data,triggers,offset,offset,winSize,step,srate,windowFunc)
% [baselineAmp,frequencies] = baselineAmplitude(data,triggers,offset,offset,winSize,step,srate,windowFunc)
%
% data      - matrix or cell of matrices of data (channel-wise recordings)
% norma      - matrix or cell of normalization values
% trigers   - vector or cell of vectors containing triger possitions
% offset- distance of taken data to the next triger
% winSize   - size of the TRFFT window
% step      - step to move the window
% srate     - sampling rate
% windowFunc- kernel function used for the TRFFT
% chosenBlocks - choosen blockIndices to concatinate data from
%
% baselineAmp - output amplitudes; first dimension: frequencies, second
% dimension: channels, third dimension: trials, cell dimension: blockIndices
% frequencies - vector containing frequencies
% indices - locations of the center of the windows
%

% Tomislav Milekovic, 06/18/2008

if (~iscell(data) && isnumeric(data))
    data = {data};
    chosenBlocks = 1;
end

if (nargin < 9 || isempty(chosenBlocks))
    chosenBlocks = 1:length(data);
end

if (nargin < 10 || isempty(useFreqwiseNorm))
    useFreqwiseNorm = false;
end

if (~isempty(norma) && ~iscell(norma))
    tmpNorma = norma;
    norma = cell(size(data));
    for ii = 1:length(data)
        norma{ii} = tmpNorma;
    end
end

if (isempty(offset))
    offset = 0;
end

frequencies = [];

% Calculate number of channels and number of frequencies
noOfChannels = size(data{1},2);
noOfFrequncies = ceil(winSize / 2 + 1);

% Normalize the window function
windowFunc = windowFunc ./ norm(windowFunc);

if (isempty(triggers))
    for blk = chosenBlocks
        triggers{blk} = [1 size(data{blk},1)];
    end
end

% Counting the number of trials
trialCount = 0;
for blk = chosenBlocks
    for jj = 1:size(triggers{blk},1)
        newSize = ceil((triggers{blk}(jj,2) - triggers{blk}(jj,1) + 1 - offset - offset - winSize + 1) / step);
        if newSize > 0
            trialCount = trialCount + newSize;
        end
    end
end

% Allocating
baselineAmp = zeros([noOfFrequncies,noOfChannels,trialCount]);
indices = zeros(1,trialCount);
blockIndices = zeros(1,trialCount);

% Preforming the TRFFT amplitude calculation
for kk = 1:noOfChannels
    currentPos = 0;
    for blk = chosenBlocks
        for jj = 1:size(triggers{blk},1)
            if (triggers{blk}(jj,2) - offset - triggers{blk}(jj,1) - offset + 1 < 0)
                continue;
            end
            
            trailIndices = double(triggers{blk}(jj,1) + offset:triggers{blk}(jj,2) - offset);
            trailIndices = trailIndices(trailIndices > 0 & trailIndices <= size(data{blk},1));
            
            trailData = data{blk}(trailIndices,kk);
            if (length(trailData) >= winSize)
                chunkLen = ceil((length(trailData) - winSize + 1) / step);
                [trailFFT,frequencies,tmpIndices] = trFFT(trailData,winSize,step,srate,windowFunc);
                
                if (isempty(norma))
                    baselineAmp(:,kk,currentPos + 1:currentPos + chunkLen) = abs(trailFFT) ./ sqrt(srate);
                else
                    if (useFreqwiseNorm)
                        for fr = 1:length(frequencies)
                            baselineAmp(fr,kk,currentPos + 1:currentPos + chunkLen) = abs(trailFFT(fr,:)) ./ sqrt(srate) ./ norma{blk}(fr,kk);
                        end                
                    else
                        baselineAmp(:,kk,currentPos + 1:currentPos + chunkLen) = abs(trailFFT) ./ sqrt(srate) ./ repmat(norma{blk}(:,kk),1,chunkLen);
                    end
                end
                
                indices(currentPos + 1:currentPos + chunkLen) = trailIndices(1) + tmpIndices - 1;
                blockIndices(currentPos + 1:currentPos + chunkLen) = repmat(blk,[1 chunkLen]);
                
                currentPos = currentPos + chunkLen;
            end
        end
    end
end


if (currentPos < trialCount)
    baselineAmp(:,:,currentPos + 1:end) = [];
    indices(currentPos + 1:end) = [];
    blockIndices(currentPos + 1:end) = [];
end












