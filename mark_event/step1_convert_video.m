close all
clear all
clc

videoDir = '/Users/ssq/Documents/EPFL/Device/SIMI/mark_event';
cd(videoDir)

extractFrames = false;

mkVideo = dir([videoDir filesep 'JJ08d20240130tkCORRdsVehicle+L-DOPAt002-3.avi']);
videoName = mkVideo(1).name;


mp4name = [videoName(1:end-4) '.mp4'];

if ~isfile(mp4name)
    setenv('PATH', [getenv('PATH') ':/usr/local/bin:/usr/bin:/bin']);
    str = sprintf(['ffmpeg -i ' videoName ' ' mp4name]);
    status = system(str);
else
    disp('mp4 file existed')
end

if extractFrames
    str = sprintf(['ffmpeg -i ' videoName ' -q:v 1 ' tmp{1} '_frame%%4d.jpg']);
    dos(str)
end

