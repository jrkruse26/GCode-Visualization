function [values,lno] = readGCode2(gcode)
%Function recieves a line of gcode and it extracts the relavent values.
%The output is an array. The output values are in the following order: G#, 
%X# Y#, Z#, and then I#, J#, K# (if IJK values exist). The function only 
%accepts G1, G2, or G3 commands. The IJK format should be used for G2/G3 
%commands (not the R format).
lno=0;
%return if not G1, or ;layer command, values(1)=0 means skip command
if ~strncmp(gcode, 'G1 ', 3) && ...
        ~strncmp(gcode, 'G92', 3) && ...
          ~strncmp(gcode, ';layer', 6) && ...
            ~strncmp(gcode, ';travel', 7) && ...
                ~strncmp(gcode, ';retract', 8) && ...
                    ~strncmp(gcode, ';unretract', 10) && ...
                        ~strncmp(gcode, ';shell', 6) && ...
                            ~strncmp(gcode, ';infill', 7)
    values(1) = 0;
    return;  
end
% return layer number, if layer number is 2 digit else code
if strncmp(gcode, ';layer', 6)
    olno = sscanf(gcode, '%s');
    [a,b]=size(olno);
    if b==7
        lno=str2num(olno(7));
    elseif b==8
        [~, status]=str2num(olno(7));
        if status ~=0;
            lno=(str2num(olno(7)))*10+str2num(olno(8));
        else
            lno=1;
        end
    end
    values(1) = 2;
    return;
elseif strncmp(gcode,';travel',7)
    values(1)=3;
    return;
elseif strncmp(gcode,';retract', 8)
    values(1)=4;
    return;
elseif strncmp(gcode,';unretract', 10)
    values(1)=5;
    return;
elseif strncmp(gcode, ';shell', 6)
    values(1)=6;
    return;
elseif strncmp(gcode, ';infill', 7)
    values(1)=6.5;
    return;
end

%get all the numbers from the string
input = sscanf(gcode, ...
            '%*c %f %*c %f %*c %f %*c %f %*c %f %*c %f');

%define the array 'values'  
values = zeros(1,6);
values(1)=1;

%for loop that puts the values in the correct order. If Z# or K# is not
%specified it is set to 0;
char1 = '';
k = 2;
for i = 3:length(gcode)
    char1 = gcode(i);
    if strcmp(char1, 'X')
       values(2) = input(k);
       k = k+1;
    elseif strcmp(char1, 'Y')
       values(3) = input(k);
       k = k+1;
   elseif strcmp(char1, 'Z')
       values(4) = input(k);
       k = k+1;
   elseif strcmp(char1, 'E')
       values(5) = input(k);
       k = k+1;
   elseif strcmp(char1, 'F')
       values(6) = input(k);
       k = k+1;
   %if it is a speed change command return do not detect 
    elseif strcmp(char1, 'F')
       values(1) = 0;
       return
    end
end
if (values(2)^2+values(3)^2+values(4)^2) <= 0
       values(1)=0;
       return;
end


