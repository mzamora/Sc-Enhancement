function get_daily_breakup(date,LinkeTurb)
% Load GHI data for a day and find enhancement and down-ramp events.
% Results are saved at the Breakups folder, and include
%   GHI: timeseries of GHI, k, k_avg, SZA
%   IE: each IE even represented by mag, duration, SZA, time
%   Breakup: each breakup represented by tstart, tend, kstart
%   Min: each down-ramp represented by mag, duration, SZA, time
% Sc Enhancement study
% (ↄ) Mónica Zamora Z., July 2019. GNU GPL 3.0
% SRAF at UCSD solar.ucsd.edu

dir='EBU2/'; % Data folder
doy=day(date,'dayofyear');
filename=['EBU2_',num2str(year(date)),'_',num2str(doy)];
load([dir,filename])

%% compute moving average with 15 min window
navg=901;
GHI_avg=conv(GHI_day,ones(navg,1)/navg,'same');

%% compute clear sky radiation
addpath(genpath('../PV_LIB')) % Add pv lib if you don't have it already
Location.latitude = 32.881; Location.longitude = -117.232; Location.altitude = 125; %EBU2 location
DN=time_day;
Time = pvl_maketimestruct(DN,-8);
try
    [GHI_clearsky, ~, ~]= pvl_clearsky_ineichen(Time, Location,LinkeTurb);
catch % In case no linke turbidity is specified, we use the climate values
    [GHI_clearsky, ~, ~]= pvl_clearsky_ineichen(Time, Location);
end
time_clearsky = datetime(DN,'ConvertFrom','datenum');
[~, ~, ApparentSunEl, ~]=pvl_ephemeris(Time, Location);
SZA=90-ApparentSunEl;

%% clear sky index
try
    k=GHI_day./GHI_clearsky;
    k_avg=GHI_avg./GHI_clearsky;
catch
    k=GHI_day./GHI_clearsky';
    k_avg=GHI_avg./GHI_clearsky';
end

%% Filter initial and final data with SZA<85
f=SZA<85; GHI.SZA=SZA(f); GHI.time=time_clearsky(f);
GHI.real=GHI_day(f);
GHI.avg=GHI_avg(f); GHI.clearsky=GHI_clearsky(f);
GHI.k=k(f); GHI.k_avg=k_avg(f);
GHI.times=datetime(time_day(f),'ConvertFrom','datenum');
subplot(133); plot(GHI.times,GHI.real,GHI.times,GHI.clearsky); ylabel('GHI'); drawnow

%% Find breakup starting time
thrshld=0.15;
pks=islocalmax(GHI.k-GHI.k_avg)&(GHI.k-GHI.k_avg>thrshld); %find peaks greater than k_avg+0.2
i0=find(pks,1); % location of first peak
npeak=1;
while true %find point before peak below kavg
    i0=i0-1;
    if GHI.k(i0)<GHI.k_avg(i0)
        break
    elseif i0==1 %if initial point (look for next peak)
        npeak=npeak+1;
        ies=find(pks);
        i0=ies(npeak);        
    end
end
% time where k<=kavg
Breakup.tstart=GHI.times(i0);
Breakup.istart=i0;
Breakup.kstart=GHI.k(i0);
%% Find breakup end time
% first point whose 5min after has a mean k close to 1 and dkdt close to zero
% be careful with the thresholds!
subplot(131); plot(GHI.times,GHI.k,GHI.times,GHI.k_avg); ylabel('k')
i1=i0;
while true
    i1=i1+1;
    meank=mean(GHI.k(i1:i1+300));
    meandk=mean(abs(diff(GHI.k(i1:i1+300))));
    if abs(1-meank)<0.01 && (meandk<5e-3)
        break
    end
end %plot(times(i1),k(i1),'o')
Breakup.tend=GHI.times(i1);
Breakup.iend=i1;

%% find IE events between i0 and i1
IE.mag=[]; IE.time=[]; IE.SZA=[]; IE.duration=[]; %Duration of the event
Min.mag=[]; Min.time=[]; Min.SZA=[]; Min.duration=[]; %Duration of the event
ies=[]; %indices of local maxima

plots_on=1;
if plots_on
    subplot(132); plot(GHI.times(i0:i1),GHI.k(i0:i1),GHI.times(i0:i1),GHI.k_avg(i0:i1)); hold on;
    plot(GHI.times(i0:i1),GHI.k_avg(i0:i1)+thrshld,'r:',GHI.times(i0:i1),GHI.k_avg(i0:i1)-thrshld,':r');
    plot(xlim,[1.05 1.05],'--r')
end
% Loop trough the breakup to find all IE events and down-ramps
for i=i0:i1     
    %% Detect an IE event
    if GHI.k(i)>1 %We are in an IE event
        %% Save start point
        if GHI.k(i-1)<1
            istart=i; %is the start of this event
            if plots_on
              plot(GHI.times(istart),GHI.k(istart),'xg'); hold on
            end
        end
        
        %% Save local maximum
        if GHI.k(i)>GHI.k(i-1) && GHI.k(i)>GHI.k(i+1) %we are in a local max
            ies=[ies i]; %save index of local maxima
%             if plots_on
%               plot(GHI.times(i),GHI.k(i),'ok'); hold on
%             end
        end
        
        %% Save last point: if next point is not IE or if next point is the end of the breakup but we are still in IE
        if (GHI.k(i+1)<1) | (i==i1 & length(ies)>1)
            if isnan(GHI.k(i-1)) %not if the previous is unknown
                continue
            end
            if ~exist('istart','var') %not if we haven't started the IE event
                continue
            end
            iend=i; %it's the end of the IE event
            if plots_on
              plot(GHI.times(iend),GHI.k(iend),'xc'); hold on
            end

            % Duration of the event
            dt=GHI.times(iend+1)-GHI.times(istart); 

%             if dt>0.5 %if the event lasts more than half an hour, we don't compute anything else and continue with next IE event
%                 ies=[];
%                 continue
%             end

            %% Initialize the index of the global max IE 
            % (the first index in case there's only one local max)
            istar=istart; 

            %% Find global max of the event
            for j=1:length(ies) %going through all the stored local max
                if GHI.k(ies(j))>GHI.k(istar) %If bigger
                    istar=ies(j); %Then now that-s the new max of maxs
                end
            end
            
            %% Discard events with kIE<1.05
            %if GHI.k(istar)<1.05
            %    ies=[]; continue
            %end

            IE.mag=[IE.mag GHI.k(istar)];
            IE.SZA=[IE.SZA GHI.SZA(istar)];
            IE.duration=[IE.duration dt];
            IE.time=[IE.time GHI.times(istar)];

            %restart local maxima indices
            ies=[]; 

            if plots_on
                plot(GHI.times(istar),GHI.k(istar),'*r'); ylabel('k in the Breakup')
                tex=text(GHI.times(istar),GHI.k(istar),['\Deltat=',num2str(minutes(dt)),' min, SZA=',num2str(GHI.SZA(istar),3)]);
                set(tex,'rotation',25,'Fontsize',12)
                hold on
            end
        end
    elseif GHI.k(i)<GHI.k_avg(i)-thrshld %we are in a down ramp
         %% Save start point
        if GHI.k(i-1)>GHI.k_avg(i)-thrshld
            istart=i; %is the start of this event
            if plots_on
              plot(GHI.times(istart),GHI.k(istart),'xg'); hold on
            end
        end
        
        %% Save local minimum
        if GHI.k(i)<GHI.k(i-1) && GHI.k(i)<GHI.k(i+1) %we are in a local min
            ies=[ies i]; %save index of local minima
        end
        
        %% Save last point: if next point is not DR or if next point is the end of the breakup but we are still in DR
        if (GHI.k(i+1)>GHI.k_avg(i)-thrshld) | (i==i1 & length(ies)>1)
            if isnan(GHI.k(i-1)) %not if the previous is unknown
                continue
            end
            if ~exist('istart','var') %not if we haven't started the event
                continue
            end
            iend=i; %it's the end of the event
            if plots_on
              plot(GHI.times(iend),GHI.k(iend),'xc'); hold on
            end

            % Duration of the event
            dt=GHI.times(iend+1)-GHI.times(istart); 

%             if dt>0.5 %if the event lasts more than half an hour, we don't compute anything else and continue with next IE event
%                 ies=[];
%                 continue
%             end

            %% Initialize the index of the global min 
            % (the first index in case there's only one local min)
            istar=istart; 

            %% Find global min of the event
            for j=1:length(ies) %going through all the stored local min
                if GHI.k(ies(j))<GHI.k(istar) %If smaller
                    istar=ies(j); %Then now that-s the new min of maxs
                end
            end
            
            %% Discard events with kIE<1.05
            %if GHI.k(istar)<1.05
            %    ies=[]; continue
            %end

            Min.mag=[Min.mag GHI.k(istar)];
            Min.SZA=[Min.SZA GHI.SZA(istar)];
            Min.duration=[Min.duration dt];
            Min.time=[Min.time GHI.times(istar)]; %time of the min

            %restart local minima indices
            ies=[]; 

            if plots_on
                plot(GHI.times(istar),GHI.k(istar),'*r'); ylabel('k in the Breakup')
                tex=text(GHI.times(istar),GHI.k(istar),['\Deltat=',num2str(minutes(dt)),' min, SZA=',num2str(GHI.SZA(istar),3)]);
                set(tex,'rotation',25,'Fontsize',12)
                hold on
            end
        end
    end
end

%% Normalized plots
%  t_norm=(IE.time-Breakup.tstart)/(Breakup.tend-Breakup.tstart);
%  if plots_on
%      subplot(122); plot(t_norm,IE.mag,'.'); xlim([0 1])
%  end

%% Save daily pic and mat
 print(['Breakups/',datestr(date,'yyyymmdd')],'-dpng')
 save(['Breakups/',datestr(date,'yyyymmdd')],'GHI','IE','Breakup','Min')
end %function
