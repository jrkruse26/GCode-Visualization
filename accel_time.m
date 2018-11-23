function [t] = accel_time(a,v1,v2,vec,vmax)
%ACCEL_TIME Calculates time for an accelerating obeject give points of
%travel, acceleration, initial and final velocity.
d = norm(vec);
d_accel = abs(((vmax^2)-(v1^2))/(2*a));
d_decel = abs(((v2^2)-(vmax^2))/(2*a));


if (d_accel+d_decel) <= d
    t1 = abs((vmax-v1)/a); %accel
    d1 = v1*t1+(.5)*a*(t1^2);
    t2 = abs((v2-vmax)/a); %deaccel
    d2 = vmax*t2+(.5)*(-a)*(t2^2);
    d3 = d - d1 - d2; %const vel area
    t3 = abs(d3/vmax);
    t = t1+t2+t3;
else
    d_gap = (d_accel+d_decel) - d;
    max_vel_d = d_accel - (d_gap/2);
    true_max_vel = sqrt((v1^2) + (2*a*max_vel_d));
    t1 = abs((true_max_vel - v1)/a);
    t2 = abs((v2 - true_max_vel)/(-a));
    t = t1 + t2;
end

end
    
    
    



