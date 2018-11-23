function [output] = GcodeToMatrix(gcode_file)
%Fucntion reads gcode file, outputs all toolpath data to a matrix.  

FID = fopen(strcat(gcode_file,'.gcode'));

line = fgetl(FID);

k=1;

output(k,:)= readGCode2(line);

while line ~= -1
    
    k=k+1;
    
    line = fgetl(FID);
    
    output(k,:)= readGCode2(line);
    
end
