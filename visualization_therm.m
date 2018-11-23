%visulatization of 3D printing thermal histories
%Author: Jordan Kruse

%visulatization of 3D printing thermal histories
%Author: Jordan Kruse

%clear MATLAB
clc,clear

%begin timing gcode processing
tic

a = 275; %accel in mm/s^2
max_jerk = 5;

%convert GCODE file to matrix and seperate variables
%NOTE: gcode must not have comments, empty lines, or fan(M160) commands
gcode = GcodeToMatrix('i100_90');
[height, width] = size(gcode);
G = gcode(:,1);
x = gcode(:,2);
y = gcode(:,3);
z = gcode(:,4);
E = gcode(:,5);
f = gcode(:,6);

%preallocations
s_all = zeros(height,1);
x_pos = zeros(height,1);
y_pos = zeros(height,1);
z_pos = zeros(height,1);
vec = zeros(height,2);
unit_vec = zeros(height,2);
vel = zeros(height,2);
t = zeros(height,1);

for line = 2:height
     if f(line) == 0
        s_all(line,1) = s_all(line-1);
    else
        s_all(line,1) = f(line)/60;
    end
    
    %create array of z positions 
    if z(line) == 0
        z_pos(line,1) = z_pos(line-1);
    else
        z_pos(line,1) = z(line);
    end
    

    if x(line) == 0 && y(line) == 0
        x_pos(line,1) = x_pos(line-1);
        y_pos(line,1) = y_pos(line-1);
    else
        x_pos(line,1) = x(line);
        y_pos(line,1) = y(line);
    end
    
    vec(line,[1 2]) = [x_pos(line)-x_pos(line-1) y_pos(line)-y_pos(line-1)];
    
    if vec(line,1) == 0 && vec(line,2) == 0
        unit_vec(line,[1 2]) = [0 0];
    else
        unit_vec(line,[1 2]) = vec(line,[1 2])/norm(vec(line,[1 2]));
    end
    
    vel(line,[1 2]) = unit_vec(line,[1 2])*s_all(line);
end

v2 = max_jerk/2;

for line = 2:height
    
   t_z = abs((z_pos(line)- z_pos(line-1))/s_all(line)); 
   
   jerk = sqrt((vel(line,1)-vel(line-1,1))^2+(vel(line,2)-vel(line-1,2))^2);
   
   v1 = v2;
   
   if jerk > max_jerk
       jerk_fact = max_jerk/jerk;
   else 
       jerk_fact = 1;
   end
   
   vmax_junc = max_jerk/2;
   
   v2 = min(s_all(line),s_all(line)*jerk_fact);
   
   t_xy = accel_time(a,v1,v2,vec(line,[1 2]),s_all(line));
   
   t_op = t_xy+t_z;
   
   t(line,1) = t(line-1) + t_op;
   
end

t_end_min = t(end)/60;
run_time = toc;
fprintf('Print will take %i minutes and %0.1f seconds \n',floor(t_end_min),(rem(t_end_min,1)*60))
fprintf('Time predicted in %0.2f seconds\n',toc);

%% interpolation
tic

indexed_t_loc = zeros(height,1);

t_interval = 0.01;
t_interp = 0:0.01:t(end);
frame_length = length(t_interp);

x_int = 0;
y_int = 0;
z_int = 0;
t_int = 0;

for c = 1:height
    [~, index] = min(abs(t_interp-t(c)));
    indexed_t_loc(c,1) = index;
end

t_index = transpose(t_interp(indexed_t_loc));
t_round = round(t_index,2);
%create position array


for c = 2:height
    if t_round(c) ~= t_round(c-1)
        t_int_op = t_round(c-1)+t_interval:t_interval:t_round(c)-t_interval;
        x_int_op = interp1([t_index(c-1) t_index(c)],[x_pos(c-1) x_pos(c)],t_int_op);
        y_int_op = interp1([t_index(c-1) t_index(c)],[y_pos(c-1) y_pos(c)],t_int_op); 
        z_int_op = interp1([t_index(c-1) t_index(c)],[z_pos(c-1) z_pos(c)],t_int_op);
        
        x_int = [x_int; transpose(x_int_op); x_pos(c)];
        y_int = [y_int; transpose(y_int_op); y_pos(c)];
        z_int = [z_int; transpose(z_int_op); z_pos(c)];
        t_int = [t_int; transpose(t_int_op); t_round(c)];
    end
end

pos = [x_int y_int z_int t_int];
%add vectors and time to original gcode matrix (debugging)
gcode = [gcode vec t];

%end stopwatch
gcode_creation_time = toc;

%print processing time
fprintf('gcode processed in %0.2f seconds \n', gcode_creation_time)


%% thermal data
tic
therm_data = xlsread('90_100i_btwn3+4_test2.xlsx');

first_layer_end = 160; %any time inbetween 1st and 2nd peak in thermal data
therm_time = therm_data(:,1);
therm_temp = therm_data(:,2);

max_array = find(therm_time <= first_layer_end);
peak1_1_temp = therm_temp(max_array);
max1 = max(peak1_1_temp);
max1_loc = find(therm_temp == max1);
max1_time = therm_time(max1_loc);

%find position where extruder first contacts thermal couple

contact_z = 0.8;
lay_pos = find(z_int == contact_z);
lay_x = x_int(lay_pos);
lay_y = y_int(lay_pos);
plot(lay_x,lay_y)
axis equal
[x_sel, y_sel] = ginput(1);
close(gcf)

[~, min_pos] = min(abs((lay_x-x_sel).^2+(lay_y-y_sel).^2)); %closest index
x_closest = lay_x(min_pos); %extract
y_closest = lay_y(min_pos);

contact = [x_closest y_closest contact_z];
    
c = 1;
n = 0;

while n == 0
    if x_int(c) == contact(1) && y_int(c) == contact(2) && z_int(c) == contact(3)
        n = 1;
        contact_time = t_int(c);
    else
        c = c + 1;
    end
end

time_offset = contact_time - max1_time;
time_act = therm_time + time_offset;

start = find(t_interp == round(time_act(1),2));

therm_pros_time = toc;
fprintf('thermal data processed in %0.2f seconds \n', therm_pros_time)


%% movie

%clear up memory for vid process
%clearvars -except start frame_length x_int y_int z_int contact therm_temp t_interp time_act

%begin stopwatch
tic

%set video save location
%PC
%myVideo = VideoWriter('E:/MATLAB_Videos/vis_output.avi');
%laptop
myVideo = VideoWriter('C:/MATLAB_Videos/vis_output');
%set video framerate
myVideo.FrameRate = 60;

%open file in MATLAB
open(myVideo);

%set figure and axis
m_fig = figure(1);
    set(m_fig, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]); %fullscreen
    s1 = subplot(2,6,[7 8 9 10 11 12]);
        hold on
            mainplot = plot3(x_int(1),y_int(1),z_int(1),'g-');
            coup = plot3(contact(1),155,0.8,'ks');
        hold off
    subplot(2,6,[2 3 4 5 6])
        therm_plot = plot(time_act,therm_temp);
        hold on
            therm_mark = plot([900 900],[90 180],'k-');
        hold off
    subplot(2,6,1); 
        temp_text = num2str(therm_temp(1));
        textstr = 'Current Temperature: ';
        textplot = text(-0.75,.5,[textstr temp_text]); 
            set(textplot,'FontSize',18)
            ax = subplot(2,6,1);
            set ( ax, 'visible', 'off')
     
k = 1;  
z = 50;
q = 1;

for c = start:frame_length
    subplot(2,6,[7 8 9 10 11 12])
        set(mainplot,'XData',x_int(1:c),'YData',y_int(1:c),'ZData',z_int(1:c))  
        hold on
            set(mainplot,'XData',x_int(1:c-z),'YData',y_int(1:c-z),'ZData',z_int(1:c-z))
            campos([100 155 100])
            secondary = plot3(x_int(c-z:c),y_int(c-z:c),z_int(c-z:c),'r-');
            secondary2 = plot3(x_int(c),y_int(c),z_int(c),'r+');
        hold off
        
        axis('equal',[0 200 135 175 0 100])
    temp_text = num2str(round(therm_temp(q),2));
    textstr = 'Current Temperature: ';
    set(textplot,'String',[textstr temp_text])
    
    set(therm_mark,'XData',[t_interp(c) t_interp(c)])

    if k == 10
        frames = getframe(m_fig);
        writeVideo(myVideo, frames);
        k = 1;
    else
        k = k + 1;
    end
    
    delete(secondary);
    delete(secondary2);
    q = q + 1;
end

%close video file
close(myVideo);

%display end messages
movie_creation_time = toc/60;
msgbox('Job Complete!')
fprintf('Movie created in %i minutes and %0.1f seconds \n',floor(movie_creation_time),(rem(movie_creation_time,1)*60))
