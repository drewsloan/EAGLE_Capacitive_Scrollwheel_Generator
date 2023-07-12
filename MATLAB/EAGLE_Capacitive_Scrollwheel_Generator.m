function EAGLE_Capacitive_Scrollwheel_Generator

%
% EAGLE_Capacitive_Scrollwheel_Generator.m - Drew Sloan.
%
%   EAGLE_CAPACITIVE_SCROLLWHEEL_GENERATOR generates a *.scr file which can
%   be run in EAGLE to create interleaved capacitive touchpads for a
%   scrollwheel.
%       
%       1. Set your desired parameters in the first section of this 
%          function and run it to generate the EAGLE script (*.scr).
%       2. Run the script in EAGLE.
%           a. File >> Execute Script...
%       3. Manually convert each set of closed wires to a polygon.
%           a. [Right Click] >> Convert to Polygon >> Replace
%   
%   UPDATE LOG:
%   2023-07-07 - Drew Sloan - Function first created.
%


% Design parameters - change these values to customize the size of your scroll wheel.
n_elements = 3;         %The number of elements in the wheel (minimum of 3).
n_tines = 3;            %The number of tines overlapping between elements.
r_outer = 20;           %Outer radius, in millimeters.
r_inner = 15;           %Inner radius, in millimeters.
dead_zone = 1.0;        %Width of the center line of the element, in millimeters.
line_width = 0.2;       %Line width of the polygon, in millimeters.
separation = 0.5;       %Separation between the traces, in millimeters.
start_angle = 90;       %Starting angle for the middle of element #1.


repo = ...
    'https://github.com/drewsloan/EAGLE_Capacitive_Scrollwheel_Generator';  %We'll write the repository URL into the description to make it easy to find in the future.


% Have the user set a *.scr destination.
filename = sprintf(['captouch_scrollwheel_'...
    'n=%1.0f_'...
    't=%1.0f_'...
    'ro=%1.1f_'...
    'ri=%1.1f_'...
    'dz=%1.1f_'...
    'lw=%1.2f_'...
    's=%1.2f'...
    ],n_elements,n_tines,r_outer,r_inner,dead_zone,line_width,separation);  %Create a default *.scr filename.
filename(filename == '.') = 'p';                                            %Replace all the decimal points with "p".
[file, path] = uiputfile([filename '.scr'],'Save EAGLE script file');       %Have the use select a place to save the script file.
if file(1) == 0                                                             %If the user clicked cancel...
    return                                                                  %Skip the reset of the function.
end
filename = fullfile(path,file);                                             %Add the path to the file.
fid = fopen(filename,'wt');                                                 %Create a script file for writing as text.
fprintf(fid,'GRID MM;\n');                                                  %Set the grid to millimeter scale.
fprintf(fid,'LAYER 1;\n');                                                  %Set the current layer to 1.
fprintf(fid,'CHANGE DRILL 0.3mm;\n');                                       %Set the default via drill size.
fprintf(fid,'CHANGE DIAMETER 0.6mm;\n');                                    %Set the default via diameter.
fprintf(fid,'SET WIRE_BEND 2;\n\n');                                        %Set the wire bend type.


% Draw the inside edge of each element.
r_inner = r_inner + line_width/2;                                           %Adjust the inner radius to account for the line width.
r_outer = r_outer - line_width/2;                                           %Adjust the outer radius to account for the line width.
sp = 2*separation + line_width;                                             %Set the spacing step.
tw = ((r_outer - r_inner) - (n_tines - 0.5)*sp)/(n_tines - 0.5);            %Set the tine base width.
for i = 1:n_elements                                                        %Step through each element.
    angle = start_angle - 360*(i-1)/n_elements;                             %Calculate the central angle.
    R = [cosd(angle), -sind(angle); sind(angle), cosd(angle)];              %Create the rotation matrix.

    % Calculate the inner edge of each element.
    center_a = atand((dead_zone/2)/r_inner);                                %Calculate the center angle.
    gap_a = 2*(atand(((separation + line_width)/2)/r_inner));               %Calulcate the gap angle.
    x = [r_inner*cosd(-center_a); ...
        r_inner*cosd((360/n_elements)-center_a-gap_a)];                     %Start a matrix of x-coordinates.
    y = [-dead_zone/2; r_inner*sind((360/n_elements)-center_a-gap_a)];      %Start a matrix of y-coordinates.
    r = [0; r_inner];                                                       %Start a matrix of radii.

    %Create the upper tines.
    for t = 1:n_tines                                                       %Step through each tine.        
        cur_r = sqrt(x(end)^2 + y(end)^2);                                  %Calculate the current radius.        
        new_r = cur_r + tw/2;                                               %Set the top of the current tine.
        center_a = atand((dead_zone/2)/new_r);                              %Calculate the center angle.
        x(end+1) = new_r*cosd(center_a);                                    %Calculate the top of the tine base.
        y(end+1) = dead_zone/2;                                             %Set the top of the tine base.
        r(end+1) = -(cur_r + new_r)/2;                                      %Set the radius to the mean of the former and current radius.
        if t < n_tines                                                      %If this isn't the last tine.
            new_r = new_r + sp;                                             %Set the bottom of the next tine base.
        else                                                                %Otherwise..
            new_r = r_outer;                                                %Set the outer x-coordinate.
        end
        x(end+1) = new_r*cosd(center_a);                                    %Calculate the top of the tine base.
        y(end+1) = dead_zone/2;                                             %Set the top of the tine base.
        r(end+1) = 0;                                                       %Set the radius to zero.
        if t < n_tines                                                      %If this isn't the last tine.
            cur_r = new_r;                                                  %Save the current radius for arc calculations.
            new_r = new_r + tw/2;                                           %Set the radius for the next tine tip.            
            center_a = atand((dead_zone/2)/new_r);                          %Calculate the center angle.
            gap_a = 2*(atand(((separation + line_width)/2)/r_inner));       %Calculate the gap angle.
            x(end+1) = new_r*cosd((360/n_elements)-center_a-gap_a);         %Calculate the x-coordinate of the next tine tip.
            y(end+1) = new_r*sind((360/n_elements)-center_a-gap_a);         %Calculate the y-coordinate of the next tine tip.
            r(end+1) = (cur_r + new_r)/2;                                   %Set the radius to the mean of the former and current radius.
        end
    end
    
    % Draw the outer edge of each element.
    center_a = atand((dead_zone/2)/r_outer);                                %Calculate the center angle.
    gap_a = 2*(atand(((separation + line_width)/2)/r_outer));               %Calulcate the gap angle.
    x(end+1) = r_outer*cosd((360/n_elements)-center_a-gap_a);               %Calculate the x-coordinates.
    y(end+1) = -r_outer*sind((360/n_elements)-center_a-gap_a);              %Calculate the x-coordinates.
    r(end+1) = -r_outer;                                                    %Set the arc radius.

    % Create the lower tines.
    for t = 1:n_tines                                                       %Step through each tine.        
        cur_r = sqrt(x(end)^2 + y(end)^2);                                  %Calculate the current radius.        
        new_r = cur_r - tw/2;                                               %Set the top of the current tine.
        center_a = atand((dead_zone/2)/new_r);                              %Calculate the center angle.
        x(end+1) = new_r*cosd(center_a);                                    %Calculate the top of the tine base.
        y(end+1) = -dead_zone/2;                                            %Set the top of the tine base.
        r(end+1) = (cur_r + new_r)/2;                                       %Set the radius to the mean of the former and current radius.
        if t < n_tines                                                      %If this isn't the last tine.
            new_r = new_r - sp;                                             %Set the bottom of the next tine base.
        else                                                                %Otherwise..
            new_r = r_inner;                                                %Set the outer x-coordinate.
        end
        x(end+1) = new_r*cosd(center_a);                                    %Calculate the top of the tine base.
        y(end+1) = -dead_zone/2;                                            %Set the top of the tine base.
        r(end+1) = 0;                                                       %Set the radius to zero.
        if t < n_tines                                                      %If this isn't the last tine.
            cur_r = new_r;                                                  %Save the current radius for arc calculations.
            new_r = new_r - tw/2;                                           %Set the radius for the next tine tip.            
            center_a = atand((dead_zone/2)/new_r);                          %Calculate the center angle.
            gap_a = 2*(atand(((separation + line_width)/2)/r_inner));       %Calculate the gap angle.
            x(end+1) = new_r*cosd((360/n_elements)-center_a-gap_a);         %Calculate the x-coordinate of the next tine tip.
            y(end+1) = -new_r*sind((360/n_elements)-center_a-gap_a);        %Calculate the y-coordinate of the next tine tip.
            r(end+1) = -(cur_r + new_r)/2;                                  %Set the radius to the mean of the former and current radius.
        end
    end

    x(end) = x(1);                                                          %Make sure the first and last x-coordinates match.
    y(end) = y(1);                                                          %Make sure the first and last y-coordinates match.

    xy = (R*[x, y]')';                                                      %Rotate the points.

    for j = 2:size(xy,1)                                                    %Step through each pair of points.
        if r(j) == 0                                                        %If the line is straight...
            fprintf(fid,['LINE ''E%1.0f'' %1.2fmm '...
                '(%1.3f %1.3f) '...
                '(%1.3f %1.3f);\n'],...
                i, line_width,...
                xy(j-1,1), xy(j-1,2),...
                xy(j,1),xy(j,2));                                           %Don't include the radius.
        else                                                                %If the line is an arc...
            if r(j) > 0                                                     %If the radius is positive...
                fprintf(fid,['LINE ''E%1.0f'' %1.2fmm '...
                    '(%1.3f %1.3f) '...
                    '@+%1.3f '...    
                    '(%1.3f %1.3f);\n'],...
                    i, line_width,...
                    xy(j-1,1), xy(j-1,2),...
                    r(j),...
                    xy(j,1),xy(j,2));                                       %Include the radius.
            else                                                            %Otherwise, if the radius is negative...
                fprintf(fid,['LINE ''E%1.0f'' %1.2fmm '...
                    '(%1.3f %1.3f) '...
                    '@%1.3f '...    
                    '(%1.3f %1.3f)'...
                    ';\n'],...
                    i, line_width,...
                    xy(j-1,1), xy(j-1,2),...
                    r(j),...
                    xy(j,1),xy(j,2));                                       %Include the radius.
            end
        end
    end

    x = (r_inner + r_outer)/2;                                              %Set the x-coordinates for an SMD pad.
    y = 0;                                                                  %Set the y-coorindates for an SMD pad.
    xy = (R*[x, y]')';                                                      %Rotate the points.
    smd_h = dead_zone - line_width;                                         %Set the height of the SMD pad.
    smd_w = (r_outer - r_inner) - line_width;                               %Set the width of the SMD pad.

    fprintf(fid,['SMD %1.3f %1.3f '...
        '-100 '...
        'R%1.0f '...
        'NOSTOP NOCREAM NOTHERMALS '...
        '''%1.0f'' ',...
        '(%1.3f %1.3f)'...
        ';\n'],...
        smd_w, smd_h,...
        angle,...
        i,...
        xy(1), xy(2));                                                      %Create an SMD pad for each element.

end

title = sprintf('<h3>Capacitive Scrollwheel, %1.0f Elements</h3>',...
    n_elements);                                                            %Create a title for the description.
params = sprintf(['<p># of elements = %1.0f</p>'...
    '<p># of tines = %1.0f</p>'...
    '<p>radius (outer) = %1.1f mm</p>'...
    '<p>radius (inner) = %1.1f mm</p>'...
    '<p>dead zone width = %1.1f mm</p>'...
    '<p>separation = %1.2f mm</p>'...
    ],...
    n_elements, n_tines, r_outer, r_inner, dead_zone, separation);          %List the parameters in the description.
url = sprintf(['<p>This footprint was created programmatically '...
    'using functions from <a href="%s">this Github repository</a>.'...
    '</p>'],...
    repo);                                                                  %Create a link to the repository.
fprintf(fid,'DESCRIPTION ''%s %s %s'';\n',title,params,url);                %Create the description.     


fclose(fid);                                                                %Close the *.scr file.
edit(filename);                                                             %Open the *.scr file in the MATLAB browser.