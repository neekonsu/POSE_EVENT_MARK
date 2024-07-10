function figureHandle = plotMultigrid4D(dataMatrix,param)
% plotMultigrid4D - function that plots a 4D function as a matrix of color images. First two dimensions are the inset dimensions while the last two
% dimensions are the general matrix row and column.

% List of param:
%   colormap ('default') - any input to colormap function
%   normalize ('true') - mode of normalization of the plotted function
%       'true' -> plotting all miniplots in the [min max] of all the
%                 plotted data scale
%       'false' -> no normalization
%   useColorbar ('false') - manages the colorbar
%       'false' -> no colorbar
%       'individual' -> colorbar for every miniplot
%       'true' -> one colorbar for all plots, works for normalize=='true'
%   xAxis - values of the x axis corresponding to second dimension of the
%           dataMatrix
%   yAxis - values of the y axis corresponding to first dimension of the
%           dataMatrix
%   outXAxis - values of the outside x axis (matrix rows) corresponding to the third dimension of the
%           dataMatrix
%   outXAxis - values of the outside y axis (matrix columns) corresponding to the fourth dimension of the
%           dataMatrix

%% Setting up the parameters
% Setting up the font sizes

% Setting up the color map
if (~isfield(param,'titleFont') || isempty(param.titleFont))
    param.titleFont = 13;
end

% Setting up the color map
if (~isfield(param,'labelFont') || isempty(param.labelFont))
    param.labelFont = 11;
end

% Setting up the color map
if (~isfield(param,'tickFont') || isempty(param.tickFont))
    param.tickFont = 9;
end

% Setting up the color map
if (~isfield(param,'colormap') || isempty(param.colormap))
    param.colormap='default';
end

% Setting up the normalization
if (~isfield(param,'normalize') || isempty(param.normalize))
    param.normalize='true';
end

% Setting up the use of the colorbar
if (~isfield(param,'useColorbar') || isempty(param.useColorbar))
    param.useColorbar='false';
end

% Setting up the use of the colorbar
if (~isfield(param,'useTextNumbers') || isempty(param.useTextNumbers))
    param.useTextNumbers = false;
end

% Setting up the x axis in the iner plot
if (~isfield(param,'xAxis') || isempty(param.xAxis))
    param.xAxis=1:size(dataMatrix,2);
end

% Setting up the y axis in the iner plot
if (~isfield(param,'yAxis') || isempty(param.yAxis))
    param.yAxis=1:size(dataMatrix,1);
end


% Setting up the color limits
if (~isfield(param,'colorLimits') || isempty(param.colorLimits))
    tmpDataMat=dataMatrix(1:length(param.yAxis),1:length(param.xAxis),:,:);
    param.colorLimits=[min(tmpDataMat(:)) max(tmpDataMat(:))];
    clear tmpDataMat;
end

%% Setting up the inset plot axes

noOfRows=size(dataMatrix,3);
noOfColumns=size(dataMatrix,4);

figureWidth=1;
figureHeight=1;

rightMargin=0.01;
rightColorbarMargin=0.07;

leftTitleMargin=0.04;
leftScaleMargin=0.04;
leftLabelMargin=0.04;
leftTicksMargin=0.04;

topTitleMargin=0.045;

bottomTitleMargin=0.04;
bottomScaleMargin=0.04;
bottomLabelMargin=0.04;
bottomTicksMargin=0.04;

interFigureMargin=0.01;

pictureWidth=(figureWidth-rightMargin-rightColorbarMargin-leftTitleMargin-leftLabelMargin-leftScaleMargin-leftTicksMargin-(noOfColumns-1)*interFigureMargin)/noOfColumns;
pictureHeight=(figureHeight-topTitleMargin-bottomTitleMargin-bottomScaleMargin-bottomLabelMargin-bottomTicksMargin-(noOfRows-1)*interFigureMargin)/noOfRows;

figurePosX=zeros(noOfRows,noOfColumns);
figurePosY=zeros(noOfRows,noOfColumns);

for ii=1:noOfRows
    for jj=1:noOfColumns
        figurePosX(ii,jj)=leftTitleMargin+leftScaleMargin+leftLabelMargin+leftTicksMargin+(jj-1)*(pictureWidth+interFigureMargin);
        figurePosY(ii,jj)=figureHeight-topTitleMargin-ii*pictureHeight-(ii-1)*(interFigureMargin);
    end
end


%% Create a figure of given proportions
figureHandle = figure('color','w','units','normalized');

colormap(param.colormap);

insetCounter=0;
for row=1:noOfRows
    for col=1:noOfColumns
        insetCounter=insetCounter+1;
        axes('units','normalized','pos',[figurePosX(row,col) figurePosY(row,col) pictureWidth pictureHeight]);

        h=imagesc(param.xAxis,param.yAxis,squeeze(dataMatrix(:,:,row,col)));
        set(get(h,'Parent'),'ydir','normal');
        
        if (param.useTextNumbers)
            for ii = 1:length(param.xAxis)
                for jj = 1:length(param.yAxis)
                    text(ii,jj,num2str(dataMatrix(jj,ii,row,col)),'fontsize',param.titleFont,...
                               'horizontalalignment','center','verticalalignment','middle');
                end
            end
        end
        
        if (isfield(param,'marker') && iscell(param.marker))
            for ii=1:length(param.marker)
                if (param.marker{ii}(3)==row && param.marker{ii}(4)==col)
                    hold on
                    plot3(param.xAxis(param.marker{ii}(2)),param.yAxis(param.marker{ii}(1)),squeeze(dataMatrix(param.marker{ii}(1),param.marker{ii}(2),row,col)),'xk','MarkerSize',10);
                end
            end
        end


        if (strcmp(param.normalize,'true'))
            set(gca,'clim',param.colorLimits);
        end
              
        if (row==noOfRows)
            if (isfield(param,'xTick'))
                set(gca,'xtick',param.xTick);
                if (isfield(param,'xTickLabel'))
                    set(gca,'xticklabel',param.xTickLabel,'fontsize',param.tickFont);
                end
            end      
        else
            set(gca,'xtick',[]);
        end
        
        if (col==1)
            if (isfield(param,'yTick'))
                set(gca,'ytick',param.yTick);
                if (isfield(param,'yTickLabel'))
                    set(gca,'yticklabel',param.yTickLabel,'fontsize',param.tickFont);
                end
            end      
        else
            set(gca,'ytick',[])
        end
        
        set(gca,'fontsize',param.tickFont);
        
        if (isfield(param,'miniTitles') && ~isempty(param.miniTitles))
            title(param.miniTitles{row,col});
        end
    end
end
        


% Creating title axis and writing the picture title
if (isfield(param,'pictureTitle') && ~isempty(param.pictureTitle))
    axes('units','normalized','pos',[0 1.0-topTitleMargin 1.0 topTitleMargin]);
    set(gca,'visible','off');
    text(0.5,0.5,param.pictureTitle,'fontsize',param.titleFont,...
    'horizontalalignment','center','verticalalignment','middle');
end

% Creating title axis and writing the x coordinate label
if (isfield(param,'outXlabel') && ~isempty(param.outXlabel))
    axes('units','normalized','pos',...
        [leftLabelMargin+leftScaleMargin+leftTicksMargin+leftTitleMargin ...
         0.0 ...
         1.0-(leftLabelMargin+leftScaleMargin+leftTicksMargin+leftTitleMargin)-rightColorbarMargin-rightMargin ...
         bottomTitleMargin]);
     
    set(gca,'visible','off');
    text(0.5,0.5,param.outXlabel,'fontsize',param.labelFont,...
        'horizontalalignment','center','verticalalignment','middle');
end

% Creating title axis and writing the x coordinate scale label
if (isfield(param,'outXScale') && ~isempty(param.outXScale))
    for col=1:noOfColumns
        axes('units','normalized','pos',...
            [figurePosX(noOfRows,col) ...
             bottomTitleMargin ...
             pictureWidth ...
             bottomScaleMargin]);

        set(gca,'visible','off');
        text(0.5,0.35,param.outXScale{col},'fontsize',param.labelFont,...
            'horizontalalignment','center','verticalalignment','middle');
    end
end

% Creating title axis and writing the x coordinate label
if (isfield(param,'xlabel') && ~isempty(param.xlabel))
    axes('units','normalized','pos',...
        [leftLabelMargin+leftScaleMargin+leftTicksMargin+leftTitleMargin ...
         bottomTitleMargin+bottomScaleMargin ...
         1.0-(leftLabelMargin+leftScaleMargin+leftTicksMargin+leftTitleMargin)-rightColorbarMargin-rightMargin ...
         bottomLabelMargin]);
     
    set(gca,'visible','off');
    text(0.5,0.35,param.xlabel,'fontsize',param.tickFont,...
        'horizontalalignment','center','verticalalignment','middle');
end


% Creating title axis and writing the x coordinate label
if (isfield(param,'outYlabel') && ~isempty(param.outYlabel))
    axes('units','normalized','pos',...
        [0.0 ...
         bottomTitleMargin+bottomScaleMargin+bottomLabelMargin+bottomTicksMargin ...
         leftTitleMargin ...
         1.0-(bottomTitleMargin+bottomScaleMargin+bottomLabelMargin+bottomTicksMargin)-topTitleMargin]);
     
    set(gca,'visible','off');
    text(0.5,0.5,param.outYlabel,'fontsize',param.labelFont,...
        'horizontalalignment','center','verticalalignment','middle','rotation',90);
end

% Creating title axis and writing the x coordinate scale label
if (isfield(param,'outYScale') && ~isempty(param.outYScale))
    for row=1:noOfRows
        axes('units','normalized','pos',...
            [leftTitleMargin ...
             figurePosY(row,1) ...
             leftScaleMargin ...
             pictureHeight]);

        set(gca,'visible','off');
%         text(0.5,0.35,param.outYScale{row},'fontsize',param.labelFont,...
%             'horizontalalignment','center','verticalalignment','middle','rotation',90);
    end
end


% Creating title axis and writing the y coordinate label
if (isfield(param,'ylabel') && ~isempty(param.ylabel))
    axes('units','normalized','pos',...
        [leftTitleMargin+leftScaleMargin ...
         bottomTitleMargin+bottomScaleMargin+bottomLabelMargin+bottomTicksMargin ...
         leftLabelMargin ...
         1.0-(bottomTitleMargin+bottomScaleMargin+bottomLabelMargin+bottomTicksMargin)-topTitleMargin]);
     
    set(gca,'visible','off');
    text(0.25,0.5,param.ylabel,'fontsize',param.tickFont,...
        'horizontalalignment','center','verticalalignment','middle','rotation',90);
end

% Creating title axis and writing the color coordinate label
if (isfield(param,'clabel') && ~isempty(param.clabel))
    axes('units','normalized','pos',[1.0 - rightMargin * 0.8 ...
                                     1.0 - topTitleMargin ...
                                     rightMargin * 0.7 ...
                                     topTitleMargin]);
    set(gca,'visible','off');
    text(0.5,0.35,param.clabel,'fontsize',param.labelFont,...
        'horizontalalignment','center','verticalalignment','middle');
end

if (strcmp(param.normalize,'true') && strcmp(param.useColorbar,'true'))
    axes('units','normalized','pos',...
        [1.0-rightMargin-rightColorbarMargin ...
         bottomTitleMargin+bottomScaleMargin+bottomLabelMargin+bottomTicksMargin ...
         rightColorbarMargin ...
         1.0-(bottomTitleMargin+bottomScaleMargin+bottomLabelMargin+bottomTicksMargin)-topTitleMargin]);
    set(gca,'clim',param.colorLimits,'visible','off');
    colorbar('location','east');
end