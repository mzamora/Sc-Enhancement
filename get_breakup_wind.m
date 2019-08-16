function [u_mag,u_dir,u_mag_all,u_dir_all]=get_breakup_wind(windtable,tstart,tend)
% gets the average wind speed (in m/s) and direction (in deg) during the
% breakup - Sc Enhancement study
% (ↄ) Mónica Zamora Z., July 2019. GNU GPL 3.0
% SRAF at UCSD solar.ucsd.edu

%% filter times
f=((windtable.wind_date-hours(7))>=tstart)&((windtable.wind_date-hours(7))<=tend);
ies=find(f);

if sum(f)==0 %maybe the breakup is too short
    [~,ies]=min(abs((windtable.wind_date-hours(7))-(tstart))); 
    u_mag=windtable.wind_speed_knots(ies)*0.514444; % to m/s
    u_dir=windtable.wind_direction(ies);
    u_mag_all=u_mag; u_dir_all=u_dir;
else %if the breakup is long enough or it is found
    u=-windtable.wind_speed_knots(ies)*0.514444.*sin(windtable.wind_direction(ies)*pi/180);
    v=-windtable.wind_speed_knots(ies)*0.514444.*cos(windtable.wind_direction(ies)*pi/180);
    umean=mean(u);
    vmean=mean(v);
    u_mag=sqrt(umean^2+vmean^2);
    u_dir=atan2(vmean,umean)*180/pi;
    u_mag_all=sqrt(u.^2+v.^2);
    u_dir_all=atan2(v,u)*180/pi;
end

end
