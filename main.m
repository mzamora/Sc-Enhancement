% Guide to follow the Sc Enhancement study
% (ↄ) Mónica Zamora Z., July 2019. GNU GPL 3.0
% SRAF at UCSD solar.ucsd.edu

%% get all Sc days
wanted_years=[2016,2017];
load('NKX_stats.mat') % MLM study data
fout=zeros(size(TABLE.date_i))
for iy=1:length(wanted_years)
    f=(year(TABLE.date_i)==wanted_years(iy)); %filter per year
    fout=fout|f; %combine filters
end
Scdays=TABLE.date_i(fout); %get Scdays from wanted years

%% if wanting to add more years, you need to process TL and GHInotes manually

% load CloudClasses_TL.mat %linke turbidity table
% TL2017=TL; GHI_notes2017=GHI_notes; %create a temporary table for older years
% TL=nan(size(Scdays)) 
% GHI_notes=cell(size(Scdays))
% TL(97:195)=TL2017; %append old years
% GHI_notes(97:195)=GHI_notes2017';
% %go through all days, then save the stuff
% save('CloudClasses_TL','GHI_notes','TL','Scdays')

%% to go through all days... follow this
for i=1:length(Scdays)
    doy=day(Scdays(i),'dayofyear');
    filename=['EBU2/EBU2_',num2str(year(Scdays(i))),'_',num2str(doy)]; %load GHI data
    load(filename)
    
    % this part was done manually
    % change the LT values manually to better match GHI clear sky
    get_daily_breakup(Scdays(i),TL(i));
    
    % when you are happy with the value of LT and the case looks like it's 
    % Sc to clear, they were saved as 'Sc' in the GHI_notes cell array. 
    % Best values of Linke turbidity for them were saved in TL. Both arrays
    % are in the file current.mat
    % For example: if Linke=4.3 was good for a Sc case, it was saved:
    %                       TL(i)=4.3;
    %                       GHI_notes{i}='Sc'
end

%% Analysis: only Sc to clear cases
load CloudClasses_TL.mat
load NKX_wind.mat

ScToClear_id=find(strcmp('Sc',GHI_notes)); % use only Sc days
for id=1:length(ScToClear_id)
    filename=['Breakups/',datestr(Scdays(ScToClear_id(id)),'yyyymmdd')];    
    try
        load(filename)
    catch %just in case
        duration(id)=nan;     zinv(id)=nan; wind(id)=nan; kstart(id)=nan;
        maxIE(id)=nan; numberIE(id)=nan; tlBL(id)=nan;
        tstart(id)=nan; tend(id)=nan;
        continue
    end
    
    % normalized time vs kIE?
    time_h=hour(IE.time)+minute(IE.time)/60+second(IE.time)/3600; %this is pdt, all data is sumemr. time_h+7 is UTC: 4PDT is 11UTC
    plot(time_h,IE.mag,'.'); hold on
        %xlabel('Breakup normalized time'); ylabel('IE magnitudes')
    % no trend AT ALL
    
    [u_mag,u_dir,u_mag_all,u_dir_all]=get_breakup_wind(NKXwind,Breakup.tstart,Breakup.tend);
    wind_speed(id)=u_mag;
    wind_dir(id)=u_dir;
    wndsp_start(id)=u_mag_all(1);
    wndsp_end(id)=u_mag_all(end);
    kstart(id)=Breakup.kstart;
    tstart(id)=Breakup.tstart;
    SZAstart(id)=IE.SZA(1);
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
    dtl(id)=TABLE.thetaL_jump(TABLE.date_i==Scdays(ScToClear_id(id)));
    wind24(id)=TABLE.wind_mean24h(TABLE.date_i==Scdays(ScToClear_id(id)));
    wind(id)=TABLE.wind_mean_16h(TABLE.date_i==Scdays(ScToClear_id(id)));
end
 
%% Plot analysis
 
%initial and end times
ti_hours=hour(tstart)+minute(tstart)/60+second(tstart)/3600;
tf_hours=hour(tend)+minute(tend)/60+second(tend)/3600;
duration_hours=tf_hours-ti_hours;
freqIE=numberIE./duration_hours;
cosSZAstart=cos(SZAstart*pi/180);

subplot(121); plot(ti_hours,tf_hours,'.'); xlabel('Initial time [hh]'); ylabel('End time [hh]')
subplot(122); plot(tf_hours,duration_hours,'.'); xlabel('Final time [hh]'); ylabel('Duration [hh]')

%% Figure 1
edit Fig1_G_and_k_evolution

%% Figure 2
edit Fig2_Correlations
