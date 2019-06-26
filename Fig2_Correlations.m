%% tf vs duration
subplot(231); 
plot(tf_hours,duration_hours,'.'); xlabel('Breakup end time [hh]'); ylabel('Breakup duration [hh]')
text(0.02,0.98,'a)','Units', 'Normalized', 'VerticalAlignment', 'Top')
corrcoef(tf_hours,duration_hours)
%% k max vs SZA
subplot(234)
plot(maxIE_SZA,maxIE,'.'); xlabel('\Theta_z [deg]'); ylabel('\it k_{\rm max}');
text(0.02,0.98,'d)','Units', 'Normalized', 'VerticalAlignment', 'Top')
corrcoef(maxIE_SZA,maxIE)
%% k max vs breakup time
subplot(232)
plot(tf_hours,maxIE,'.'); xlabel('Breakup end time [hh]'); ylabel('\it k_{\rm max}');
text(0.02,0.98,'b)','Units', 'Normalized', 'VerticalAlignment', 'Top')
corrcoef(tf_hours,maxIE)
%% k max vs k min
subplot(235)
plot(minII,maxIE,'.'); xlabel('\it k_{\rm min}'); ylabel('\it k_{\rm max}');
text(0.02,0.98,'e)','Units', 'Normalized', 'VerticalAlignment', 'Top')
f=~isnan(minII+maxIE); corrcoef(minII(f),maxIE(f))
%% k min vs breakup time
subplot(233)
plot(tf_hours*0.5,minII,'.'); xlabel('Breakup end time [hh]'); ylabel('\it k_{\rm min}');
text(0.02,0.98,'c)','Units', 'Normalized', 'VerticalAlignment', 'Top')
f=~isnan(minII+tf_hours); corrcoef(tf_hours(f),minII(f))
%% t start vs wind
plot(tf_hours,wind_speed,'.'); xlabel('Breakup end time [hh]'); ylabel('Wind speed [m s^{-1}]');
f=~isnan(wind_speed); corrcoef(tf_hours(f),wind_speed(f))
%% t start vs wind dir
plot(ti_hours,wind_dir,'.'); xlabel('Initial time [hh]'); ylabel('Wind direction [deg]');
corrcoef(ti_hours,wind_dir)
%% k max vs wind speed
subplot(236)
plot(wind_speed,maxIE,'.'); xlabel('Wind speed [m s^{-1}]'); ylabel('\it k_{\rm max}');
text(0.02,0.98,'f)','Units', 'Normalized', 'VerticalAlignment', 'Top')
f=~isnan(wind_speed+maxIE); corrcoef(wind_speed(f),maxIE(f))
%% k min vs wind speed
plot(wind_speed,minII,'.'); xlabel('Wind speed [m s^{-1}]'); ylabel('\it k_{\rm min}');
f=~isnan(wind_speed+minII); corrcoef(wind_speed(f),minII(f))
%% ti vs kstart
plot(ti_hours,kstart,'.'); xlabel('Initial time [hh]'); ylabel('Initial \it k \rm[hh]')
corrcoef(ti_hours,kstart)
