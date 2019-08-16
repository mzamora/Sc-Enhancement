% Figure 2 - Sc Enhancement study
% (ↄ) Mónica Zamora Z., July 2019. GNU GPL 3.0
% SRAF at UCSD solar.ucsd.edu

%% tf vs duration
subplot(241); 
plot(tf_hours,duration_hours,'.'); xlabel('Breakup end time [hh]'); ylabel('Breakup duration [hh]')
text(0.02,0.98,'a)','Units', 'Normalized', 'VerticalAlignment', 'Top')
corrcoef(tf_hours,duration_hours)
%% k start vs ti
subplot(242)
plot(kstart,ti_hours,'.'); xlabel('\it k_i'); ylabel('Breakup start time [hh],');
text(0.02,0.98,'b)','Units', 'Normalized', 'VerticalAlignment', 'Top')
corrcoef(kstart,ti_hours)
%% ui vs ti
subplot(243)
plot(wndsp_start,ti_hours,'.'); xlabel('\it u_i \rm [m s^{-1}]'); ylabel('Breakup start time [hh]');
text(0.02,0.98,'c)','Units', 'Normalized', 'VerticalAlignment', 'Top')
corrcoef(wndsp_start,ti_hours)
%% k max vs breakup time
subplot(244)
plot(tf_hours,maxIE,'.'); xlabel('Breakup end time [hh]'); ylabel('\it k_{\rm max}');
text(0.02,0.98,'d)','Units', 'Normalized', 'VerticalAlignment', 'Top')
corrcoef(tf_hours,maxIE)
%% k max vs SZA
subplot(245)
plot(maxIE_SZA,maxIE,'.'); xlabel('\Theta_z [deg]'); ylabel('\it k_{\rm max}');
text(0.02,0.98,'e)','Units', 'Normalized', 'VerticalAlignment', 'Top')
corrcoef(maxIE_SZA,maxIE)
%% k max vs u breakup
subplot(246)
plot(wind_speed,maxIE,'.'); xlabel('\it u \rm [m s^{-1}]'); ylabel('\it k_{\rm max}');
text(0.02,0.98,'f)','Units', 'Normalized', 'VerticalAlignment', 'Top')
corrcoef(wind_speed,maxIE)
%% k max vs k min
subplot(247)
plot(minII,maxIE,'.'); xlabel('\it k_{\rm min}'); ylabel('\it k_{\rm max}');
text(0.02,0.98,'g)','Units', 'Normalized', 'VerticalAlignment', 'Top')
f=~isnan(minII+maxIE); corrcoef(minII(f),maxIE(f))
%% k min vs breakup time
subplot(248)
plot(tf_hours,minII,'.'); xlabel('Breakup end time [hh]'); ylabel('\it k_{\rm min}');
text(0.02,0.98,'h)','Units', 'Normalized', 'VerticalAlignment', 'Top')
f=~isnan(minII+tf_hours); corrcoef(tf_hours(f),minII(f))

%% Other things

%% t start vs wind
plot(tf_hours,wind_speed,'.'); xlabel('Breakup end time [hh]'); ylabel('u [m s^{-1}]');
f=~isnan(wind_speed); corrcoef(tf_hours(f),wind_speed(f))
%% t start vs wind dir
plot(ti_hours,wind_dir,'.'); xlabel('Initial time [hh]'); ylabel('Wind direction [deg]');
corrcoef(ti_hours,wind_dir)
%% k max vs wind speed
plot(wind_speed,maxIE,'.'); xlabel('Wind speed [m s^{-1}]'); ylabel('\it k_{\rm max}');
text(0.02,0.98,'f)','Units', 'Normalized', 'VerticalAlignment', 'Top')
f=~isnan(wind_speed+maxIE); corrcoef(wind_speed(f),maxIE(f))
%% k min vs wind speed
plot(wind_speed,minII,'.'); xlabel('Wind speed [m s^{-1}]'); ylabel('\it k_{\rm min}');
f=~isnan(wind_speed+minII); corrcoef(wind_speed(f),minII(f))
%% ti vs kstart
plot(ti_hours,kstart,'.'); xlabel('Initial time [hh]'); ylabel('Initial \it k \rm[hh]')
corrcoef(ti_hours,kstart)
