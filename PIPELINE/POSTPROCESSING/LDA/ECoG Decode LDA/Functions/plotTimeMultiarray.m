function figureHandle = plotTimeMultiarray(dataCell,param)

%% If dataCell if matrix, create a cell out of it
if (~iscell(dataCell))
    dataCell = {dataCell};
end

%% If param is undefined, define it

if (nargin<2 || ~isstruct(param))
    param = struct;
end

%% Defining the font sizes
titleFont = 13;
labelFont = 11;
tickFont = 9;

noOfChannels = size(dataCell{1},2);

%% Checking the lineFormat entry in the parameters
if (~isfield(param,'lineFormat') || isempty(param.lineFormat))
    param.lineFormat = {'-b','-r','-k','-g','-m','-c',':k','-y',':b',':r',':g',':m',':c',':y',...
                      '--b','--r','--k','--g','--m','--c','.-k','--y','.-b','.-r','.-g','.-m','.-c','.-y'};
end

%% Checking the colorFormat entry in the parameters
if (~isfield(param,'colorFormat') || isempty(param.colorFormat))
    param.colorFormat = {'b','r','k','g','m','c','k','y','b','r','g','m','c','y'};
end

%% Checking the xAxis entry in the parameters
if (~isfield(param,'xAxis') || isempty(param.xAxis))
    param.xAxis = 1:size(dataCell{1},1);
end

if (size(param.xAxis,1) == 1)
    param.xAxis = param.xAxis';
end


%% Checking the plotInd entry in the parameters
if (~isfield(param,'plotInd') || isempty(param.plotInd))
    param.plotInd = 1:noOfChannels;
end

%% Checking the nameInd entry in the parameters
if (~isfield(param,'nameInd') || isempty(param.nameInd))
    param.nameInd = param.plotInd;
end

%% Checking the normalize entry in the parameters
if (~isfield(param,'normalize') || isempty(param.normalize))
    param.normalize = 'true';
end

%% Checking if the channel names are defined
if (~isfield(param,'channelNames'))
    param.channelNames = [];
end

%% Checking if the marked channels are defined
if (~isfield(param,'markedCh'))
    param.markedCh = [];
end

%% Chcking the consistency of insetMarker, insetTimeMarker and insetMarkerColor

if (~isfield(param,'insetMarker') || ~iscell(param.insetMarker))
    param.insetMarker = {};
end

if (~isfield(param,'insetTimeMarker') || ~iscell(param.insetTimeMarker))
    param.insetTimeMarker = {};
end

if (~isfield(param,'insetMarkerColor') || ~iscell(param.insetMarkerColor)...
        || length(param.insetMarkerColor)<max([length(param.insetMarkerColor) length(param.insetMarker)]))
    test = colormap(lines(7));
    test = test+(1-test)*2/3;
    param.insetMarkerColor = [];
    for ii = 1:max([length(param.insetTimeMarker) length(param.insetMarker)])
        param.insetMarkerColor{ii} = test(mod(ii-1,7)+1,:);
    end
end

%% Creating the yAxis limits
if (~isfield(param,'normLim') || isempty(param.normLim))
    tmpData = dataCell{1}(:);
    tmpData(isinf(tmpData)) = [];
    tmpData(isnan(tmpData)) = [];
    normLim = [min(tmpData) max(tmpData)];
    clear tmpData;


    for ii = 2:length(dataCell)
        tmpData = dataCell{ii}(:);
        tmpData(isinf(tmpData)) = [];
        tmpData(isnan(tmpData)) = [];
        normLim(1) = min([normLim(1) min(tmpData(:))]);
        normLim(2) = max([normLim(2) max(tmpData(:))]);
        clear tmpData;
    end
    
    normLim(1) = normLim(1)-0.05*(normLim(2)-normLim(1));
    normLim(2) = normLim(2)+0.05*(normLim(2)-normLim(1));
else
    normLim = param.normLim;
end

%% Creating the design sheet that is going to place small pictures within
% the figure
if(~isfield(param,'design') || isempty(param.design))
    noOfColumns = ceil(sqrt(noOfChannels));
    noOfRows = ceil(noOfChannels / noOfColumns);
    design = cell(noOfRows,noOfColumns);
    for ch = 1:noOfChannels
        design{ch} = ch;
    end
    
elseif (~iscell(param.design))
    assert(length(param.design) == 2);
    noOfRows = param.design(1);
    noOfColumns = param.design(2);
    design = cell(noOfRows,noOfColumns);
    for ch = 1:noOfChannels
        design{ch} = ch;
    end
else
    design = param.design;
    noOfRows = size(param.design,1);
    noOfColumns = size(param.design,2);
end


%% Defining the sizes of the picture margins
bottomMargin = 0.08;
channelMargin = 0.25;

if (~isfield(param,'interPictureMargin') || isempty(param.interPictureMargin))
    param.interPictureMargin = 0.035;
end

if (~isfield(param,'pictureTitle') || isempty(param.pictureTitle))
    topMargin = 0.015;
else
    topMargin = 0.05;
end

leftMargin = 0.065;
rightMargin = 0.035;

pictureWidth = ((1 - leftMargin - rightMargin) / noOfColumns);
pictureHeight = ((1 - bottomMargin - topMargin) / noOfRows);



%% create a figure of given proportions
figureHandle  =  figure('color','w','units','normalized');

handleH = zeros(1,length(dataCell));
for ii = 1:noOfRows
    for jj = 1:noOfColumns
        if (isempty(design{ii,jj}))
            continue;
        end
        assert(length(design{ii,jj}) == 1);
        
        minVal = Inf;
        maxVal = -Inf;
        
        bgColorChange = false;
        for mrk = 1:length(param.insetMarker)
            if (~isempty(find(param.insetMarker{mrk} == design{ii,jj},1,'first')))
                axes('color',param.insetMarkerColor{mrk},'units','normalized','pos',...
                     [leftMargin+(jj-1) * pictureWidth ...
                      1.0 - topMargin - ii * pictureHeight ...
                      pictureWidth * (1.0 - param.interPictureMargin) ...
                      pictureHeight * (1.0 - param.interPictureMargin)]);
                bgColorChange = true;
                break;
            end
        end
        
        if ~bgColorChange
            axes('color','w','units','normalized','pos',...
                 [leftMargin+(jj-1)*pictureWidth 1.0-topMargin-ii*pictureHeight pictureWidth*(1.0-param.interPictureMargin) pictureHeight*(1.0-param.interPictureMargin)]);
        end
        
        hold on;
        for kk = 1:length(dataCell)
            handleH(kk) = plot(param.xAxis,dataCell{kk}(:,design{ii,jj}),param.lineFormat{kk});
            minVal = min([minVal; dataCell{kk}(:,design{ii,jj})]);
            maxVal = max([maxVal; dataCell{kk}(:,design{ii,jj})]);
        end

        if (isfield(param,'markCh') && ~isempty(param.markCh) && ~isempty(intersect(design{ii,jj},param.markCh)))
            set(gca,'Color',[0.8 1 1]);
        end        
      

        set(gca,'xlim',[param.xAxis(1) param.xAxis(end)]);
        
        if (~isempty(param.markedCh) && ~isempty(find(design{ii,jj} == param.markedCh,1)))
            set(gca,'color',[1 0.9 0.9]);
        end

        if (isfield(param,'verticalMarker') && ~isempty(param.verticalMarker))
            for mark = 1:length(param.verticalMarker)
                plot(param.verticalMarker(mark)+[0 0],[normLim(1) normLim(end)],':m','LineWidth',1);
            end
        end

        if (isfield(param,'horizontalMarker') && ~isempty(param.horizontalMarker))
            for mark = 1:length(param.horizontalMarker)
                plot([param.xAxis(1) param.xAxis(end)],param.horizontalMarker(mark)+[0 0],':k','LineWidth',1);
            end
        end

        if (strcmp(param.normalize,'true'))
            set(gca,'ylim',normLim);
        else
            if (minVal ~= maxVal)
                set(gca,'ylim',[minVal maxVal]);
            else
                set(gca,'ylim',minVal + [-1 1]);
            end
        end

        if (ii == noOfRows)
            if (isfield(param,'xTick'))
                set(gca,'xtick',param.xTick);
            end
            
            if (isfield(param,'xTickLabel'))
                set(gca,'xticklabel',param.xTickLabel);
            end
        else
            set(gca,'xtick',[]);
        end

        if (jj>1 || strcmp(param.normalize,'false'))
            set(gca,'ytick',[])
        else
            if (isfield(param,'yTick'))
                set(gca,'ytick',param.yTick);
            end            
        end

        set(gca,'fontsize',tickFont);
    end
end

if (isfield(param,'legend') && ~isempty(param.legend))
    legend(handleH,param.legend,'Location',[0.01 ...
                                            1 - 1.5*pictureHeight ...
                                            1.5*pictureWidth ....
                                            1.5*pictureHeight]);
end

for ii = 1:noOfRows
    for jj = 1:noOfColumns
        if (isempty(design{ii,jj}))
            continue;
        end
        if (~isempty(param.channelNames))
            axes('units','normalized','pos',...
                [leftMargin+(jj-1)*pictureWidth 1.0-topMargin-ii*pictureHeight+pictureHeight*(1.0-channelMargin) pictureWidth*(1.0-param.interPictureMargin) pictureHeight*channelMargin]);
            set(gca,'visible','off');
            if (isfield(param,'useChNo') && ~isempty(param.useChNo) && param.useChNo)
                text(0.5,0.25,[param.channelNames{param.nameInd(design{ii,jj})} ' (' num2str(design{ii,jj}) ')'],'fontsize',8,...
                    'horizontalalignment','center','verticalalignment','middle');
            else
                text(0.5,0.25,param.channelNames{param.nameInd(design{ii,jj})},'fontsize',8,...
                    'horizontalalignment','center','verticalalignment','middle');
            end
            
        elseif (isfield(param,'useChNo') && ~isempty(param.useChNo) && param.useChNo)
            axes('units','normalized','pos',...
                [leftMargin + (jj - 1) * pictureWidth ...
                 1.0 - topMargin - ii * pictureHeight + pictureHeight * (1.0 - channelMargin) ...
                 pictureWidth * (1.0 - param.interPictureMargin) ...
                 pictureHeight * channelMargin]);
            set(gca,'visible','off');
            text(0.5,0.25,['Ch ' num2str(design{ii,jj})],'fontsize',8,...
                                                         'horizontalalignment','center',...
                                                         'verticalalignment','middle');
        end
    end
end



%% Creating title axis and writing the picture title
if (isfield(param,'pictureTitle') && ~isempty(param.pictureTitle))
    axes('units','normalized','pos',[leftMargin 1.0-topMargin 1.0-rightMargin-leftMargin topMargin]);
    set(gca,'visible','off');
    text(0.5,0.5,param.pictureTitle,'fontsize',titleFont,...
        'horizontalalignment','center','verticalalignment','middle');
end

%% Creating title axis and writing the x coordinate label
if (isfield(param,'xlabel') && ~isempty(param.xlabel))
    axes('units','normalized','pos',[0.0 0.0 1.0 bottomMargin*0.8]);
    set(gca,'visible','off');
    text(0.5,0.35,param.xlabel,'fontsize',labelFont,...
        'horizontalalignment','center','verticalalignment','middle');
end

%% Creating title axis and writing the y coordinate label
if (isfield(param,'ylabel') && ~isempty(param.ylabel))
    axes('units','normalized','pos',[0.0 0.0 leftMargin*0.8 1.0]);
    set(gca,'visible','off');
    text(0.25,0.5,param.ylabel,'fontsize',labelFont,...
        'horizontalalignment','center','verticalalignment','middle','rotation',90);
end

