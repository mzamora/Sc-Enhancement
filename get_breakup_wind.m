function [u_mag,u_dir]=get_breakup_wind(windtable,tstart,tend)
% gets the average wind speed (in m/s) and direction (in deg) during the
% breakup

%% filter times
f=((windtable.wind_date-8/24)>=tstart)&((windtable.wind_date-8/24)<=tend);
ies=find(f);

if isempty(f) %maybe the breakup is too short
    [~,ies]=min(abs((windtable.wind_date-8/24)-tstart)); %we find the closest time
    u_mag=windtable.wind_speed_knots(ies)*0.514444; % to m/s
    u_dir=windtable.wind_direction(ies);
else
    u=-windtable.wind_speed_knots(ies)*0.514444.*sin(windtable.wind_direction(ies)*pi/180);
    v=-windtable.wind_speed_knots(ies)*0.514444.*cos(windtable.wind_direction(ies)*pi/180);
    umean=mean(u);
    vmean=mean(v);
    u_mag=sqrt(umean^2+vmean^2);
    u_dir=atan2(vmean,umean)*180/pi;
end

end