function figureHandle = plotMultiarray(dataMatrix,param)

if (~isfield(param,'titleFont') || isempty(param.titleFont))
    param.titleFont = 13;
end

if (~isfield(param,'labelFont') || isempty(param.labelFont))
    param.labelFont = 11;
end

if (~isfield(param,'tickFont') || isempty(param.tickFont))
    param.tickFont=9;
end

if (~isfield(param,'colormap') || isempty(param.colormap))
    param.colormap='default';
end

if (~isfield(param,'normalize') || isempty(param.normalize))
    param.normalize='true';
end

if (~isfield(param,'ydir') || isempty(param.ydir))
    param.ydir='normal';
end

if (~isfield(param,'useColorbar') || isempty(param.useColorbar))
    param.useColorbar='false';
end

if (~isfield(param,'plotInd') || isempty(param.plotInd))
    param.plotInd=1:size(dataMatrix,3);
end

if (~isfield(param,'xAxis') || isempty(param.xAxis))
    param.xAxis=1:size(dataMatrix,2);
end

if (~isfield(param,'yAxis') || isempty(param.yAxis))
    param.yAxis=1:size(dataMatrix,1);
end

%% Creating the design sheet that is going to place small pictures within
% the figure
if(~isfield(param,'design') || isempty(param.design))
    noOfChannels=size(dataMatrix,3);
    noOfColumns=ceil(sqrt(noOfChannels));
    noOfRows=ceil(noOfChannels/noOfColumns);
    design=cell(noOfRows,noOfColumns);
    for ch=1:noOfChannels
        design{ch}=ch;
    end
elseif (~iscell(param.design))
    assert(length(param.design)==2);
    noOfRows=param.design(1);
    noOfColumns=param.design(2);
    design=cell(noOfRows,noOfColumns);
    for ch=1:noOfChannels
        design{ch}=ch;
    end
else
    design=param.design;
    noOfRows=size(param.design,1);
    noOfColumns=size(param.design,2);
end



if (~isfield(param,'nameInd') || isempty(param.nameInd))
    param.nameInd=param.plotInd;
end

if (~isfield(param,'colorLimits') || isempty(param.colorLimits))
    tmpDataMat=dataMatrix(1:length(param.yAxis),1:length(param.xAxis),param.plotInd);
    param.colorLimits=[min(tmpDataMat(:)) max(tmpDataMat(:))];
    clear tmpDataMat;
end

if (~isfield(param,'fontSize') || isempty(param.fontSize))
    param.fontSize=8;
end

if (~isfield(param,'useChannelNumbers') || isempty(param.useChannelNumbers))
    param.useChannelNumbers=false;
end

if (~isfield(param,'triggersAt') || isempty(param.triggersAt))
    param.triggersAt=0;
end

if (~isfield(param,'plotBandMarker') || isempty(param.plotBandMarker))
    param.plotBandMarker=false;
end

bottomMargin=0.1;
topMargin=0.05;

if (~isfield(param,'channelNames') || isempty(param.channelNames))
    pictureNameMargin=0.0;
else
    pictureNameMargin=0.1;
end

if (~isfield(param,'interPictureMargin') || isempty(param.interPictureMargin))
    param.interPictureMargin=0.04;
end

leftMargin=0.09;
rightMargin=0.075;

pictureWidth=((1-leftMargin-rightMargin)/noOfColumns);
pictureHeight=((1-bottomMargin-topMargin)/noOfRows);

% create a figure of given proportions
figureHandle = figure('color','w','units','normalized');

colormap(param.colormap);

for ii=1:noOfRows
    for jj=1:noOfColumns
        if (isempty(design{ii,jj}))
            continue;
        end
        assert(length(design{ii,jj})==1);
        
        axes('units','normalized','pos',...
            [leftMargin+(jj-1)*pictureWidth 1.0-topMargin-ii*pictureHeight pictureWidth*(1.0-param.interPictureMargin) pictureHeight*(1.0-param.interPictureMargin-pictureNameMargin)]);

        h=imagesc(param.xAxis,param.yAxis,dataMatrix(1:length(param.yAxis),1:length(param.xAxis),design{ii,jj}));
   
        set(get(h,'Parent'),'ydir',param.ydir);
        
        if (strcmp(param.normalize,'true'))
            set(gca,'clim',param.colorLimits);
        else
            tmpMat=dataMatrix(1:length(param.yAxis),1:length(param.xAxis),design{ii,jj});
            cLim = [min(tmpMat(~isnan(tmpMat(:)))) max(tmpMat(~isnan(tmpMat(:))))];
            if (cLim(1) ~= cLim(2))
                set(gca,'clim',[min(tmpMat(~isnan(tmpMat(:)))) max(tmpMat(~isnan(tmpMat(:))))]);
            end
        end
        
        if (isfield(param,'plotTriggerMarker') && param.plotTriggerMarker)
            hold on
            for kk=1:length(param.triggersAt)
                plot([param.triggersAt(kk) param.triggersAt(kk)],[param.yAxis(1) param.yAxis(end)],'--w','LineWidth',1);
            end
        end

        if (param.plotBandMarker)
            hold on
            for kk=1:length(param.bandMarkerAt)
                plot([param.xAxis(1) param.xAxis(end)],[param.bandMarkerAt(kk) param.bandMarkerAt(kk)],'--w','LineWidth',1);
            end
        end

        if (isfield(param,'plotSurfMarker') && param.plotSurfMarker)
            hold on
            plot(param.xAxis(param.surfMarker(:,2)),param.yAxis(param.surfMarker(:,1)),'ok');
        end        
        
        set(gca,'fontsize',param.tickFont);
        
        if (ii==size(design,1) || isempty(design{ii+1,jj}))
            if (isfield(param,'xTick'))
                set(gca,'xtick',param.xTick);
            end      
            
            if (isfield(param,'xTickLabel'))
                set(gca,'xticklabel',param.xTickLabel);
            end 
        else
            set(gca,'xtick',[]);
        end
        
        if (jj~=1)
            set(gca,'ytick',[])
        else
             if (isfield(param,'yTick'))
                set(gca,'ytick',param.yTick);
            end     
            
            if (isfield(param,'yTickLabel'))
                set(gca,'yticklabel',param.yTickLabel);
            end            
        end
        
        
        if (strcmp(param.useColorbar,'individual'))
            colorbar('location','east');
        end
        
        if (isfield(param,'channelNames') && ~isempty(param.channelNames))
            axes('units','normalized','pos',...
                [leftMargin+(jj-1)*pictureWidth 1.0-topMargin-ii*pictureHeight+pictureHeight*(1.0-param.interPictureMargin-pictureNameMargin) pictureWidth*(1.0-param.interPictureMargin) pictureHeight*(param.interPictureMargin+pictureNameMargin)]);
            set(gca,'visible','off');
            
            if (param.useChannelNumbers)
                channelText=[param.channelNames{param.nameInd(design{ii,jj})} ' (' num2str(design{ii,jj}) ')'];
            else
                channelText=param.channelNames{param.nameInd(design{ii,jj})};
            end
            
            text(0.5,0.32,channelText,'fontsize',param.fontSize,'horizontalalignment','center','verticalalignment','middle');            
        end
    end
end
        


% Creating title axis and writing the picture title
if (isfield(param,'pictureTitle') && ~isempty(param.pictureTitle))
    axes('units','normalized','pos',[leftMargin 1.0-topMargin 1.0-rightMargin-leftMargin topMargin]);
    set(gca,'visible','off');
    text(0.5,0.35,param.pictureTitle,'fontsize',param.titleFont,...
    'horizontalalignment','center','verticalalignment','middle');
end

% Creating title axis and writing the x coordinate label
if (isfield(param,'xlabel') && ~isempty(param.xlabel))
    axes('units','normalized','pos',[0.0 0.0 1.0 bottomMargin*0.8]);
    set(gca,'visible','off');
    text(0.5,0.35,param.xlabel,'fontsize',param.labelFont,...
        'horizontalalignment','center','verticalalignment','middle');
end

% Creating title axis and writing the y coordinate label
if (isfield(param,'ylabel') && ~isempty(param.ylabel))
    axes('units','normalized','pos',[0.0 0.0 leftMargin*0.8 1.0]);
    set(gca,'visible','off');
    text(0.25,0.5,param.ylabel,'fontsize',param.labelFont,...
        'horizontalalignment','center','verticalalignment','middle','rotation',90);
end

% Creating title axis and writing the color coordinate label
if (isfield(param,'clabel') && ~isempty(param.clabel))
    axes('units','normalized','pos',[1.0-rightMargin*0.8 1.0-topMargin rightMargin*0.7 topMargin]);
    set(gca,'visible','off');
    text(0.5,0.35,param.clabel,'fontsize',param.labelFont,...
        'horizontalalignment','center','verticalalignment','middle');
end

if (strcmp(param.normalize,'true') && strcmp(param.useColorbar,'true'))
    axes('units','normalized','pos',[1.0-rightMargin bottomMargin rightMargin*0.8 1.0-topMargin-bottomMargin]);
    set(gca,'clim',param.colorLimits,'fontsize',param.tickFont,'visible','off');
    colorbar('location','east');
end