close all
clear all
clc

addpath('/Volumes/Smile347/ECoG-Decoding/Code/Functions')
monkey_dir = 'Natalya';
task_dir = 'TM20';
the_date = '20200727';

data_dir = ['/Volumes/Smile347/ECoG-Decoding/Model' filesep monkey_dir filesep the_date];
load([data_dir filesep 'ModelBuildData_2k_' monkey_dir '_' the_date '_' task_dir '.mat'])
save_dir = data_dir;

neuralDataDS = neuralDSData;
chUsed = 1:64;
eventsUsed = 1:2; % 1,RFS  2,RFO   3,LFS . 4, LFO
load([data_dir filesep 'trft_normMean_' task_dir '.mat'],'trft_normMean')
%% Setting up the parameters
% ------------- Parameters for extracting spectral features ------------- 
DP.fftWinSize = floor(H.sampleRate/2);
DP.fftWinFunction = hamming(DP.fftWinSize);
DP.fftBaseStep = floor(DP.fftWinSize/10);
DP.fftDecFR = 100;
DP.fftDecStep = floor(H.sampleRate/DP.fftDecFR);
DP.offsetBase = 0;

DP.fftBaseFR = round(1/(DP.fftBaseStep/H.sampleRate));
DP.decFreqBand = [80 200];
DP.chUsed = chUsed;

%  ------------- Filter search decoding parameters ------------- 
% parameters for rLDA decoder
searchParam.eventsUsed = eventsUsed;
searchParam.sampleRate = DP.fftDecFR;
searchParam.featureDim = [3 5 10];
searchParam.featureLen = round(searchParam.sampleRate * [0.3 0.5 0.8]);
searchParam.regCoeff = [0 0.05 0.2 0.5 0.8 1];
searchParam.indStarts = 0;
searchParam.treshVal = 0.8;  % 0.95;
searchParam.detectMethod = 'rLDA';
searchParam.deadTime = searchParam.sampleRate * 0.01;
searchParam.noOfNegTrain = 100000;
searchParam.refractorySec = 0.5;

% parameters for low-pass filter
searchParam.halfWidth = 0;
searchParam.featureOffset = 0;
searchParam.chUsed = 1:H.noOfCh;
searchParam.sessToUse = 1:H.noOfCuts;

% parameters for training/testing scheme
searchParam.testDivision = 3;        % Divide the dataset into how many parts to be used for testing
searchParam.noOfCV = 3;              % Number of CV folds
% searchParam.noOfRepermutations = 10;
searchParam.verbose = true;
searchParam.plotDiagnostics = true;

% parameters for model building (ms)
searchParam.estimatedStimDelay = 0;%150
searchParam.estimatedRfoAnticipation = 0;%50;
searchParam.estimatedRfsAnticipation = 0;
searchParam.estimatedLfoAnticipation = 0;%50;
searchParam.estimatedLfsAnticipation = 0;
searchParam.tolWin = 0.4 * searchParam.sampleRate;

% parameters for shift optimization
shiftParam.iniShift = [0 0];    %pts in dec frequency, corresponding to the events used
shiftParam.sampleRate = DP.fftDecFR;
shiftParam.featureDim = 5;
shiftParam.regCoeff = 0.05;
shiftParam.featureLen = round(DP.fftDecFR * 0.5);
shiftParam.indStarts = 0;
shiftParam.treshVal = 0.8;  % 0.95;
shiftParam.detectMethod = 'rLDA';
shiftParam.deadTime = DP.fftDecFR * 0.1;
shiftParam.noOfNegTrain = 100000;
shiftParam.refractorySec = 0.5;
%% Calculating STFT baseline used for z-scoring the features
[neuralDataDec, hand_triggers, DP] = nestCV_extractDecData(neuralDataDS,trft_normMean,triggersCuts,DP,H);
used_triggers = hand_triggers(:,1:2);
%% divide datasets into training sets and test sets
[MI, MI_Train, ParamOpt] = evaluateRLDA_NestCV(used_triggers,neuralDataDec, searchParam, shiftParam,save_dir);
%%
REZ.MI = MI;
REZ.MI_train = MI_Train;
REZ.param_train = ParamOpt;

save([data_dir filesep 'WHFB_Decoding_REZ_' monkey_dir '_' the_date '.mat'],'REZ','DP','searchParam','shiftParam')
disp('................. Finished ! .........................')

