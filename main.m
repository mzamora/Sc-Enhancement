% checking sc days

%% load NKX data
load NKX_stats.mat

%% get all Sc days
wanted_years=[2016,2017]
load('NKX_stats.mat')
fout=zeros(size(TABLE.date_i))
for iy=1:length(wanted_years)
    f=(year(TABLE.date_i)==wanted_years(iy))
    fout=fout|f;
end
Scdays=TABLE.date_i(fout)

%% if wanting to add more years, fix TL and GHInotes
% load CloudClasses_TL.mat
% TL2017=TL; GHI_notes2017=GHI_notes;
% TL=nan(size(Scdays))
% GHI_notes=cell(size(Scdays))
% TL(97:195)=TL2017; %append old years
% GHI_notes(97:195)=GHI_notes2017';
% %go through all days, then save the stuff
% save('CloudClasses_TL','GHI_notes','TL','Scdays')

%% to go through all days... follow this
for i=1:length(Scdays)
    doy=day(Scdays(i),'dayofyear');
    filename=['EBU2/EBU2_',num2str(year(Scdays(i))),'_',num2str(doy)];    
    load([filename])
    
    % this part was done manually
    % changing LT values manually to better match GHI cs
    get_daily_breakup(Scdays(i),TL(i));
    
    % when there were cases that looked like Sc to clear, were saved as
    % 'Sc' in the GHI_notes cell array. Best values of Linke turbidity for
    % them were saved in TL. Both arrays are in current.mat
    % For example: if Linke=4.3 was good for a Sc case, it was saved.
    %                       TL(i)=4.3;
    %                       GHI_notes{i}='Sc'
end

%% only Sc to clear cases
load CloudClasses_TL.mat
load NKX_wind.mat
%%
ScToClear_id=find(strcmp('Sc',GHI_notes)); % find only Sc days
for id=1:length(ScToClear_id)
    filename=['Breakups/',datestr(Scdays(ScToClear_id(id)),'yyyymmdd')];    
    try
        load(filename)
    catch %something's wrong with 23
        duration(id)=nan;     zinv(id)=nan; wind(id)=nan; kstart(id)=nan;
        maxIE(id)=nan; numberIE(id)=nan; tlBL(id)=nan;
        tstart(id)=nan; tend(id)=nan;
        continue
    end
    
    % normalized time vs kIE?
    time_h=hour(IE.time)+minute(IE.time)/60+second(IE.time)/3600;
    plot(time_h,IE.mag,'.-'); hold on
        %xlabel('Breakup normalized time'); ylabel('IE magnitudes')
    % no trend AT ALL
    
    [u_mag,u_dir]=get_breakup_wind(NKXwind,Breakup.tstart,Breakup.tend);
    wind_speed(id)=u_mag;
    wind_dir(id)=u_dir;
    kstart(id)=Breakup.kstart;
    tstart(id)=Breakup.tstart;
    tend(id)=Breakup.tend;
    duration(id)=Breakup.tend-Breakup.tstart;
    [maxIE(id),iIE]=max(IE.mag);
    maxIE_SZA(id)=IE.SZA(iIE);
    try
        minII(id)=min(Min.mag);
    catch
        minII(id)=nan;
    end
    numberIE(id)=length(IE.mag);
    zinv(id)=TABLE.z_inv_base(TABLE.date_i==Scdays(ScToClear_id(id)));
    tlBL(id)=TABLE.thetaL_BL(TABLE.date_i==Scdays(ScToClear_id(id)));
    wind(id)=TABLE.wind_mean_16h(TABLE.date_i==Scdays(ScToClear_id(id)));
end
% plot(duration,zinv,'.'); xlabel('Breakup duration'); ylabel('z_i')
%  plot(maxIE,zinv,'.'); xlabel('Max. k IE'); ylabel('z_i')
%  plot(numberIE,zinv,'.'); xlabel('Number of IE events'); ylabel('z_i')
% plot(duration,tlBL,'.'); xlabel('Breakup duration'); ylabel('\theta_l BL')
%  plot(maxIE,tlBL,'.'); xlabel('Max. k IE'); ylabel('\theta_l BL')
%  plot(numberIE,tlBL,'.'); xlabel('Number of IE events'); ylabel('\theta_l BL')
% plot(duration,wind,'.'); xlabel('Breakup duration'); ylabel('16-h mean wind')
%  plot(maxIE,wind,'.'); xlabel('Max. k IE'); ylabel('16-h mean wind')
%  plot(numberIE,wind,'.'); xlabel('Number of IE events'); ylabel('16-h mean wind')
%  plot(numberIE,duration,'.'); xlabel('Number of IE events'); ylabel('Breakup duration')
 
%% Plot analysis
 
%initial and end times
ti_hours=hour(tstart)+minute(tstart)/60+second(tstart)/3600;
tf_hours=hour(tend)+minute(tend)/60+second(tend)/3600;
duration_hours=tf_hours-ti_hours;

subplot(121); plot(ti_hours,tf_hours,'.'); xlabel('Initial time [hh]'); ylabel('End time [hh]')
subplot(122); plot(tf_hours,duration_hours,'.'); xlabel('Final time [hh]'); ylabel('Duration [hh]')

%% Figure 1
edit Fig1_G_and_k_evolution

%% Figure 2
edit Fig2_Correlations
