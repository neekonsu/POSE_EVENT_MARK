<<<<<<< Updated upstream
%% Neurorestore's palette

set(0, 'DefaultFigureRenderer', 'painters');

palette.color.ir = [249,82,91]/255;
palette.color.ird = [134,46,56]/255;
palette.color.bd = [25,211,197]/255;
palette.color.bl = [138,210,211]/255;
palette.color.yd = [252,176,33]/255;
palette.color.yl = [254,197,87]/255;
palette.color.vy = [240,223,0]/255;
palette.color.db = [49,51,53]/255;
palette.color.cg11 = [84,86,91]/255;
palette.color.cg9 = [117,118,121]/255;
palette.color.cg7 = [150,152,153]/255;
palette.color.cg4 = [187,186,186]/255;
palette.color.cg1 = [219,219,221]/255;

palette.discrete.b3 = [palette.color.bd;palette.color.vy;palette.color.ir];
palette.discrete.b4 = [palette.color.ir;[55,35,103]/255;palette.color.bd;palette.color.vy];
palette.discrete.b5 = [palette.color.ir;[149,151,152]/255;[55,35,103]/255;palette.color.bd;palette.color.vy];
palette.discrete.b6 = [[8,136,128]/255;[108,0,95]/255;palette.color.ir;[55,35,103]/255;palette.color.bd;palette.color.vy];

% backgrounds
palette.background.cg_circles_nr = imread('\\upcourtinenas\UPPERLIMB\Toolboxes\templates\cg_circles_nr.jpg');
palette.background.cg_edges_nr = imread('\\upcourtinenas\UPPERLIMB\Toolboxes\templates\cg_edges_nr.jpg');
palette.background.db_circles_nr = imread('\\upcourtinenas\UPPERLIMB\Toolboxes\templates\db_circles_nr.jpg');
palette.background.db_edges_nr = imread('\\upcourtinenas\UPPERLIMB\Toolboxes\templates\db_edges_nr.jpg');
palette.background.ir_circles_nr = imread('\\upcourtinenas\UPPERLIMB\Toolboxes\templates\ir_circles_nr.jpg');
palette.background.ir_edges_nr = imread('\\upcourtinenas\UPPERLIMB\Toolboxes\templates\ir_edges_nr.jpg');
palette.background.w_circles_nr = imread('\\upcourtinenas\UPPERLIMB\Toolboxes\templates\w_circles_nr.jpg');
palette.background.w_edges_nr = imread('\\upcourtinenas\UPPERLIMB\Toolboxes\templates\w_edges_nr.jpg');
palette.background.ir_nr = imread('\\upcourtinenas\UPPERLIMB\Toolboxes\templates\ir_nr.png');
%%


palette.default_color = [palette.color.ir;
    palette.color.bd;
    palette.color.yd;
    palette.color.db;
    palette.color.bl;
=======
%% Neurorestore's palette

set(0, 'DefaultFigureRenderer', 'painters');

palette.color.ir = [249,82,91]/255;
palette.color.ird = [134,46,56]/255;
palette.color.bd = [25,211,197]/255;
palette.color.bl = [138,210,211]/255;
palette.color.yd = [252,176,33]/255;
palette.color.yl = [254,197,87]/255;
palette.color.vy = [240,223,0]/255;
palette.color.db = [49,51,53]/255;
palette.color.cg11 = [84,86,91]/255;
palette.color.cg9 = [117,118,121]/255;
palette.color.cg7 = [150,152,153]/255;
palette.color.cg4 = [187,186,186]/255;
palette.color.cg1 = [219,219,221]/255;

palette.discrete.b3 = [palette.color.bd;palette.color.vy;palette.color.ir];
palette.discrete.b4 = [palette.color.ir;[55,35,103]/255;palette.color.bd;palette.color.vy];
palette.discrete.b5 = [palette.color.ir;[149,151,152]/255;[55,35,103]/255;palette.color.bd;palette.color.vy];
palette.discrete.b6 = [[8,136,128]/255;[108,0,95]/255;palette.color.ir;[55,35,103]/255;palette.color.bd;palette.color.vy];

% backgrounds
palette.background.cg_circles_nr = imread('\\upcourtinenas\UPPERLIMB\Toolboxes\templates\cg_circles_nr.jpg');
palette.background.cg_edges_nr = imread('\\upcourtinenas\UPPERLIMB\Toolboxes\templates\cg_edges_nr.jpg');
palette.background.db_circles_nr = imread('\\upcourtinenas\UPPERLIMB\Toolboxes\templates\db_circles_nr.jpg');
palette.background.db_edges_nr = imread('\\upcourtinenas\UPPERLIMB\Toolboxes\templates\db_edges_nr.jpg');
palette.background.ir_circles_nr = imread('\\upcourtinenas\UPPERLIMB\Toolboxes\templates\ir_circles_nr.jpg');
palette.background.ir_edges_nr = imread('\\upcourtinenas\UPPERLIMB\Toolboxes\templates\ir_edges_nr.jpg');
palette.background.w_circles_nr = imread('\\upcourtinenas\UPPERLIMB\Toolboxes\templates\w_circles_nr.jpg');
palette.background.w_edges_nr = imread('\\upcourtinenas\UPPERLIMB\Toolboxes\templates\w_edges_nr.jpg');
palette.background.ir_nr = imread('\\upcourtinenas\UPPERLIMB\Toolboxes\templates\ir_nr.png');
%%


palette.default_color = [palette.color.ir;
    palette.color.bd;
    palette.color.yd;
    palette.color.db;
    palette.color.bl;
>>>>>>> Stashed changes
    palette.color.yl;];