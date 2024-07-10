function [FFTofData,frequencies,winCenter]=trFFT(data,windowSize,step,sampleRate,winFunction)
% function trFFT - time-resolved fourier-transformation
%
% parameter:
% data        - signal; first dimension: time; second dimension: trials
% windowSize  - length of time window
% step        - time steps in which time window is moved
% sampleRate  - sampling rate
% winFunction - window function
%
% return values:
% FFTofData   - fourie transformed signal, first dimension: frequency; second dimension: time; third dimension: trials
% frequencies - vector containing frequencies
% winCenter   - vector containing times of centers of windows
%

% Tomislav Milekovic, 06/19/2008


frequencies = sampleRate/2*linspace(0,1,ceil(windowSize/2+1));
winCenter=windowSize:step:size(data,1);

FFTofData=nan([length(frequencies) length(winCenter) size(data,2)]);

for trial=1:size(data,2)
    for window=1:length(winCenter)
        trailData=data(winCenter(window)-windowSize+1:winCenter(window),trial);
        trailData=winFunction.*trailData;
        FFTrez=fft(trailData);
        FFTofData(:,window,trial)=FFTrez(1:ceil(windowSize/2+1));
    end
end

winCenter=winCenter-floor(windowSize/2);



