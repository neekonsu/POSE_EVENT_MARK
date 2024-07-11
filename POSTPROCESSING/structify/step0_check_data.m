%% structure for event files
close all
clear all
clc

evt_file = '/Users/ssq/Documents/EPFL/STROKE-BSI/Decoding/LDA/Data/20200723/EVT/Natalya_20200723_001_EVT.mat';
load(evt_file)

events = struct;

events.MetaTags.syncInfo.start = [1 66821];
events.MetaTags.syncInfo.end   = [15382 4681380];
events.MetaTags.videoFrameRate = 100;
events.MetaTags.ecogSamplingRate = 30000;

events.EventsInfo(1).Name = 'ST_RCH';
events.EventsInfo(1).Description = 'Start of reaching';
events.EventsInfo(2).Name = 'ST_PULL';
events.EventsInfo(2).Description = 'Start of pulling';

events.ST_RCH = ST_RCH;
events.ST_PULL = ST_PULL;


%% structure for traj files
close all
clear all
clc

traj_file = '/Users/ssq/Documents/EPFL/STROKE-BSI/Decoding/LDA/Data/20200723/TRJ/Natalya_20200723_001_TRJ.mat';
load(traj_file)

traj = struct;
traj.MetaTags.frameRate = 100;
traj.MarkerInfo = {'bodypart1','bodypart2','bodypart3','bodypart4','bodypart5','bodypart6','bodypart7'};
traj.CamInfo(1).Camera = 'Cam1';
traj.CamInfo(1).Video = 'Natalya_20200723_ARM_001-1.avi';
traj.CamInfo(2).Camera = 'Cam2';
traj.CamInfo(2).Video = 'Natalya_20200723_ARM_001-2.avi';
traj.Cam1.bodypart1 = points.bodypart1;  % nrSamples * (2+1): x,y,likelihood
traj.Cam2.bodypart1 = points.bodypart1;  % nrSamples * (2+1): x,y,likelihood
traj.bodypart1 = points.bodypart1;  % nrSamples * 3: x,y,z