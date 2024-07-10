close all
clear all
clc

addpath('/Volumes/Smile347/ECoG-Decoding/Code/Functions')
monkey_dir = 'Natalya';
task_dir = 'SS';
the_date = '20200715';

data_dir = ['/Volumes/Smile347/ECoG-Decoding/Model' filesep monkey_dir filesep the_date];
load([data_dir filesep 'ModelBuildData_2k_' monkey_dir '_' the_date '_' task_dir '.mat'])
save_dir = [data_dir filesep 'figure'];
mkdir(save_dir)
%% Do small laplacian spatial filtering to raw neural data
% get the filter map for each location 6*11 map
% lsfMap = nan(66,4);
% for ii = 1:6
%     for jj = 1:11
%         idx = (ii-1)*11 + jj;
%         
%         if ii == 1 && jj == 1
%             lsfMap(idx,:) = [NaN NaN idx+1 idx+11];
%         elseif ii == 1 && jj == 11
%             lsfMap(idx,:) = [NaN idx-1 NaN idx+11];
%         elseif ii == 1 && jj>1 && jj<11
%             lsfMap(idx,:) = [NaN idx-1 idx+1 idx+11];
%         elseif ii ==6 && jj == 1
%             lsfMap(idx,:) = [idx-11 NaN idx+1 NaN];
%         elseif ii == 6 && jj == 11
%             lsfMap(idx,:) = [idx-11 idx-1 NaN NaN];
%         elseif ii == 6 && jj>1 && jj<11
%             lsfMap(idx,:) = [idx-11 idx-1 idx+1 NaN];
%         elseif ii>1 && ii<6 && jj==1
%             lsfMap(idx,:) = [idx-11 NaN idx+1 idx+11];
%         elseif ii>1 && ii<6 && jj==11
%             lsfMap(idx,:) = [idx-11 idx-1 NaN idx+11];  
%         else
%             lsfMap(idx,:) = [idx-11 idx-1 idx+1 idx+11]; 
%         end
%         
%     end 
% end
% 
% arLsfMap = lsfMap-2;
% arLsfMap(arLsfMap<1) = NaN;
% arLsfMap(1:2,:) = [];
% % arLsfMap = [(1:64)' arLsfMap];
% 
% % fo spatial filtering
% neuralRawData = neuralDSData{1}';
% neuralFiltData = neuralRawData;
% for ch = 1:H.noOfCh
%     ch2filt = arLsfMap(ch,:);
%     ch2filt(isnan(ch2filt)) = [];
%     neuralFiltData(ch,:) = neuralFiltData(ch,:) - mean(neuralRawData(ch2filt,:),1);
% end
%% Setting up the parameters

DP.fftWinSize = floor(H.sampleRate/2);
DP.fftWinFunction = hamming(DP.fftWinSize);
DP.fftBaseStep = floor(DP.fftWinSize/10);
DP.fftDecStep = floor(H.sampleRate/20);
DP.offsetBase = 0;

DP.fftBaseFR = round(1/(DP.fftBaseStep/H.sampleRate));
DP.fftDecFR = round(1/(DP.fftDecStep/H.sampleRate));
%% Doing the STFT analysis for baseline
neuralBaseData = [];

for cut = 1:H.noOfCuts
    if ~isempty(triggersCuts.corrStartOfRest{cut})
        if isempty(triggersCuts.corrEndOfRest{cut})
            ptsBase = round(triggersCuts.corrStartOfRest{cut}):size(neuralDSData{cut},1);
        else
            ptsBase = round(triggersCuts.corrStartOfRest{cut}):round(triggersCuts.corrEndOfRest{cut});
        end
        neuralBaseData = [neuralBaseData; neuralDSData{cut}(ptsBase,:)];
    else
        neuralBaseData = [neuralBaseData; neuralDSData{cut}];
    end
end
[trft_norm,DP.trft_frequencies,normInd,trft_blkInd] = baselineAmplitude_SE(neuralBaseData, ...
                                                                     [], ...
                                                                     [], ...
                                                                     DP.offsetBase, ...
                                                                     DP.fftWinSize, ...
                                                                     DP.fftBaseStep, ...
                                                                     H.sampleRate, ...
                                                                     DP.fftWinFunction);
                                        
trft_normMean = mean(trft_norm,3);
save([data_dir filesep 'trft_normMean_' task_dir '.mat'],'trft_normMean')
%% 
[trft_all,~,decInd,blkInd] = baselineAmplitude_SE(neuralDSData, ...
                                                  [], ...
                                                  [], ...
                                                  DP.offsetBase, ...
                                                  DP.fftWinSize, ...
                                                  DP.fftDecStep, ...
                                                  H.sampleRate, ...
                                                  DP.fftWinFunction);

[trft_allnorm,~,~,~] = baselineAmplitude_SE(neuralDSData, ...
                                                  trft_normMean, ...
                                                  [], ...
                                                  DP.offsetBase, ...
                                                  DP.fftWinSize, ...
                                                  DP.fftDecStep, ...
                                                  H.sampleRate, ...
                                                  DP.fftWinFunction);     
% save([data_dir filesep 'trft_all_' task_dir '.mat'],'trft_all','trft_allnorm','decInd','blkInd','DP')
%% check the data in one channel
% fr_range = [80 200];
% fr_sel = find(DP.trft_frequencies>fr_range(1) & DP.trft_frequencies<fr_range(2));
% 
% cut_sel = 4;
% for ch_sel = 12%[12 29 32 44]
% 
%     idx_cut = find(blkInd==cut_sel);
%     figure
%     set(gcf,'units','pixel','position',[100 100 1200 200])
%     data = squeeze(trft_allnorm(fr_sel,ch_sel,idx_cut));
% %     subplot(2,1,1)
%     imagesc(decInd(idx_cut),DP.trft_frequencies(fr_sel),data)
%     hold on
%     for i=1:length(triggersCuts.corrReaching{cut_sel})
%         plot(triggersCuts.corrReaching{cut_sel}(i)*[1 1], [0 fr_range(1)], 'b')
%     end
%     for i=1:length(triggersCuts.corrGrasping{cut_sel})
%         plot(triggersCuts.corrGrasping{cut_sel}(i)*[1 1], [0 fr_range(1)], 'r')
%     end
%     
%     for i=1:length(triggersCuts.corrReachingFood{cut_sel})
%         plot(triggersCuts.corrReachingFood{cut_sel}(i)*[1 1], [0 fr_range(1)], '--b')
%     end
%     for i=1:length(triggersCuts.corrGraspingFood{cut_sel})
%         plot(triggersCuts.corrGraspingFood{cut_sel}(i)*[1 1], [0 fr_range(1)], '--r')
%     end
%     set(gca,'ydir','normal')
%     set(gca,'clim',[prctile(data(:),1) prctile(data(:),99)],'ylim',[0 fr_range(2)])
%     title(['Electrode ' num2str(ch_sel)])
% 
% %     subplot(2,1,2)
% %     hold on
% %     for i=1:length(triggersCuts.corrGrasping{cut_sel})
% %         plot(triggersCuts.corrGrasping{cut_sel}(i)*[1 1], [0 1], 'r')
% %     end
% %     set(gca,'xlim',[0 size(neuralDSData{cut_sel},1)])
% %     title('Grasping')
% 
%     saveas(gcf,[data_dir filesep 'elec' num2str(ch_sel) '_cut' num2str(cut_sel) '.png'])
% 
% end
%%
close all
band = [8 12;...
        12 30;...
        80 200];
fr_sel = find(DP.trft_frequencies>5 & DP.trft_frequencies<50);
ch_sel = 12;
maxNum = 100;
trft_grasp = nan(length(DP.trft_frequencies),H.noOfCh,2*DP.fftDecFR+1,maxNum);
trftNorm_grasp = nan(length(DP.trft_frequencies),H.noOfCh,2*DP.fftDecFR+1,maxNum);

bp_grasp = nan(size(band,1),H.noOfCh,2*DP.fftDecFR+1,maxNum);
bpNorm_grasp = nan(size(band,1),H.noOfCh,2*DP.fftDecFR+1,maxNum);

counter = 1;
for cut = 1:H.noOfCuts
    idxBlk = find(blkInd==cut);
    decIndBlk = decInd(idxBlk);
    for ii = 1:length(triggersCuts.corrGrasping{cut})
        cntEventBlk = triggersCuts.corrGrasping{cut}(ii);
        startEpochBlk = cntEventBlk-H.sampleRate; 
        endEpochBlk = cntEventBlk+H.sampleRate;
        
        idxGraspblk = find(decIndBlk>cntEventBlk,1);
        idxCntStartblk = idxGraspblk - DP.fftDecFR;
        idxCntEndblk = idxGraspblk + DP.fftDecFR;
        
        if idxCntStartblk>0 && idxCntEndblk<length(idxBlk)
            idxCntStartall = idxBlk(idxCntStartblk);
            idxCntEndall = idxBlk(idxCntEndblk);

%             figure
%             subplot(3,1,1)
%             y = neuralDSData{cut}(startEpochBlk:endEpochBlk,ch_sel);
%             plot([startEpochBlk:endEpochBlk]/H.sampleRate,y)
%             set(gca,'xtick',[startEpochBlk cntEventBlk endEpochBlk]/H.sampleRate,'xticklabel',{'-1 s','Grasping','1 s '},...
%                 'xlim',[startEpochBlk endEpochBlk]/H.sampleRate)
%             title(['Elec ' num2str(ch_sel) ' - counter ' num2str(counter)])
% 
%             subplot(3,1,2) 
%             cntTF = squeeze(trft_all(fr_sel,1,idxCntStartall:idxCntEndall));
%             hold on
%             imagesc(-1:1/DP.fftDecFR:1,DP.trft_frequencies(fr_sel),cntTF)
%             plot([0 0],[0 500],'-g','linewidth',2)
%             set(gca,'ydir','normal','xtick',[-1 0 1],'xticklabel',{'-1 s','Grasp','1 s'},...
%                 'ytick',[8 12 30 80 200 500],'xlim',[-1 1],'ylim',[5 50])
%             ylabel('Freq')
%             title([num2str(counter) ' - trft'])
% 
%             subplot(3,1,3) 
%             cntTF = squeeze(trft_allnorm(fr_sel,1,idxCntStartall:idxCntEndall));
%             hold on
%             imagesc(-1:1/DP.fftDecFR:1,DP.trft_frequencies(fr_sel),cntTF)
%             plot([0 0],[0 500],'-g','linewidth',2)
%             set(gca,'ydir','normal','xtick',[-1 0 1],'xticklabel',{'-1 s','Grasp','1 s'},...
%                 'ytick',[8 12 30 80 200 500],'xlim',[-1 1],'ylim',[5 50])
%             ylabel('Freq')
%             title([num2str(counter) ' - trft - norm'])
            

            for ch = 1:H.noOfCh
                for f = 1:length(DP.trft_frequencies)
                    cntTF = reshape(squeeze(trft_all(f,ch,idxCntStartall:idxCntEndall)),1,[]);
                    trft_grasp(f,ch,:,counter) = cntTF;
                end
            end

            for ch = 1:H.noOfCh
                for f = 1:length(DP.trft_frequencies)
                    cntTF = reshape(squeeze(trft_allnorm(f,ch,idxCntStartall:idxCntEndall)),1,[]);
                    trftNorm_grasp(f,ch,:,counter) = cntTF;
                end
            end

            for ch = 1:H.noOfCh
                for b = 1:size(band,1)
                    cntBP = reshape(mean(trft_all(band(b,1):band(b,2),ch,idxCntStartall:idxCntEndall),1),1,[]);
                    bp_grasp(b,ch,:,counter) = cntBP;
                    cntBP = reshape(mean(trft_allnorm(band(b,1):band(b,2),ch,idxCntStartall:idxCntEndall),1),1,[]);
                    bpNorm_grasp(b,ch,:,counter) = cntBP;
                    
                end
            end

            counter = counter+1;

        end
    end
end

trft_grasp(:,:,:,counter:end) = [];
trftNorm_grasp(:,:,:,counter:end) = [];
bp_grasp(:,:,:,counter:end) = [];
bpNorm_grasp(:,:,:,counter:end) = [];
%% remove noisy trials
tr2rm = [];
trft_grasp(:,:,:,tr2rm) = [];
trftNorm_grasp(:,:,:,tr2rm) = [];
bp_grasp(:,:,:,tr2rm) = [];
bpNorm_grasp(:,:,:,tr2rm) = [];
%%
fr_sel = find(DP.trft_frequencies>5 & DP.trft_frequencies<50);
figure
set(gcf,'units','pixel','position',[50 50 1500 1200])
for ch = 1:H.noOfCh
    
    cntTF = squeeze(mean(trft_grasp(fr_sel,ch,:,:),4));
    
%     figure
%     hold on
    subplot(6,11,ch+2)
    
    imagesc(-1:1/DP.fftDecFR:1,DP.trft_frequencies(fr_sel),cntTF)
    set(gca,'ydir','normal','xtick',[-1 0 1],'xticklabel',{'-1 s','Grasp','1 s'},...
        'ytick',[8 12 30 80 200 500],'xlim',[-1 1],'ylim',[5 50])
    xlabel('Gait Phases')
    ylabel('Freq')
    title(['elec' num2str(ch)])
%     pause
%     close gcf
end
saveas(gcf,[save_dir filesep 'trft_grasp.png'])
%%
fr_sel = find(DP.trft_frequencies>5 & DP.trft_frequencies<200);
figure
set(gcf,'units','pixel','position',[50 50 1500 1200])
for ch = 1:H.noOfCh
    
    cntTF = squeeze(mean(trftNorm_grasp(fr_sel,ch,:,:),4));
    
%     figure
%     hold on
    subplot(6,11,ch+2)
    
    imagesc(-1:1/DP.fftDecFR:1,DP.trft_frequencies(fr_sel),cntTF)
    set(gca,'ydir','normal','xtick',[-1 0 1],'xticklabel',{'-1 s','Grasp','1 s'},...
        'ytick',[8 12 30 80 200 500],'xlim',[-1 1],'ylim',[5 200])
    xlabel('Gait Phases')
    ylabel('Freq')
    title(['elec' num2str(ch)])
    
%     pause
%     close gcf
end
saveas(gcf,[data_dir filesep 'trftNorm_grasp.png'])


%%
% close all
fr_range = [5 200];
fr_sel = find(DP.trft_frequencies>fr_range(1) & DP.trft_frequencies<fr_range(2));
for ch = 1:64
    figure
    set(gcf,'units','pixel','position',[50 50 800 400])
    subplot(1,size(band,1)+2,1)
    cntTF = squeeze(mean(trft_grasp(fr_sel,ch,:,:),4));


    imagesc(-1:1/DP.fftDecFR:1,DP.trft_frequencies(fr_sel),cntTF)
    set(gca,'ydir','normal','xtick',[-1 0 1],'xticklabel',{'-1 s','Grasp','1 s'},...
        'ytick',[8 12 30 80 200 500],'xlim',[-1 1],'ylim',fr_range)
    xlabel('Gait Phases')
    ylabel('Freq')
    title(['elec' num2str(ch)])

    subplot(1,size(band,1)+2,2)
    cntTF = squeeze(mean(trftNorm_grasp(fr_sel,ch,:,:),4));

    imagesc(-1:1/DP.fftDecFR:1,DP.trft_frequencies(fr_sel),cntTF)
    set(gca,'ydir','normal','xtick',[-1 0 1],'xticklabel',{'-1 s','Grasp','1 s'},...
        'ytick',[8 12 30 80 200 500],'xlim',[-1 1],'ylim',fr_range)
    xlabel('Gait Phases')
    ylabel('Freq')
    title(['elec' num2str(ch) ' - Norm'])

    nrTrial = size(bp_grasp,4);
    for b = 1:size(band,1)
    subplot(1,size(band,1)+2,b+2)
    data = squeeze(bp_grasp(b,ch,:,:))';
    imagesc(-1:1/DP.fftDecFR:1,1:nrTrial,data)
    hold on
    plot([0 0],[0 nrTrial],'-r','linewidth',2)
    set(gca,'clim',[prctile(data(:),10) prctile(data(:),90)],'xtick',[-1 0 1],'xticklabel',{'-1s','Grasp','1s'})
    ylabel('Trial')
    xlabel('Grasping')
    title(['Freq Band ' num2str(band(b,:))])
    end
    
    saveas(gcf,[save_dir filesep 'elec' num2str(ch) '.png'])

end
%%
% fr_sel = find(DP.trft_frequencies>8 & DP.trft_frequencies<12);
% tmpInd = find(blkInd==cut_sel);
% BPall = mean(trft_all(fr_sel,:,:),1);
% cmin = prctile(BPall(:),1);
% cmax = prctile(BPall(:),99);
% figure
% set(gcf,'units','pixel','position',[100 100 1200 400])
% for ii = 1:length(tmpInd)
%     t = tmpInd(ii);
%     BP = mean(trft_all(fr_sel,:,t),1);
%     BPmap = [NaN; NaN; BP(:)];
%     BPmap = reshape(BPmap,11,6);
% %     imagesc(BPmap') 
% %     pause(0.1)
%     
%     data = squeeze(trft_all(fr_sel,ch_sel,idx_cut));
%     subplot(2,1,1)
%     imagesc(BPmap')
%     set(gca,'clim',[cmin cmax])
% 
%     subplot(2,1,2)
%     hold on
%     for i=1:length(triggersCuts.corrGrasping{cut_sel})
%         plot(triggersCuts.corrGrasping{cut_sel}(i)*[1 1], [0 1], 'r')
%     end
%     plot([decInd(t) decInd(t)],[0 1],'-g','linewidth',2)
%     set(gca,'xlim',[0 size(neuralDSData{cut_sel},1)])
%     title('Grasping')
%     pause(0.3)
%     clf
% end


%%
% nrTrial = size(bp_grasp,4);
% for ch_sel = 1:64
% figure
% set(gcf,'units','pixel','position',[100 100 600 1200])
% for b = 1:size(band,1)
%     subplot(2,size(band,1),b)
%     data = squeeze(bp_grasp(b,ch_sel,:,:))';
%     imagesc(-1:1/DP.fftDecFR:1,1:nrTrial,data)
%     hold on
%     plot([0 0],[0 nrTrial],'-r','linewidth',2)
%     set(gca,'clim',[prctile(data(:),10) prctile(data(:),90)],'xtick',[-1 0 1],'xticklabel',{'-1s','Grasp','1s'})
%     ylabel('Trial')
%     xlabel('Grasping')
%     title(['Freq Band ' num2str(band(b,:))])
% 
%     subplot(2,size(band,1),b+size(band,1))
%     data = squeeze(bpNorm_grasp(b,ch_sel,:,:))';
%     imagesc(-1:1/DP.fftDecFR:1,1:nrTrial,data)
%     hold on
%     plot([0 0],[0 nrTrial],'-r','linewidth',2)
%     set(gca,'clim',[prctile(data(:),10) prctile(data(:),90)],'xtick',[-1 0 1],'xticklabel',{'-1s','Grasp','1s'})
%     ylabel('Trial')
%     xlabel('Grasping')
%     title(['Norm - Freq Band ' num2str(band(b,:))])
% end
% sgtitle(['Elec ' num2str(ch_sel)])
% saveas(gcf,[data_dir filesep 'elec' num2str(ch_sel) '_bandpower.png'])
% end