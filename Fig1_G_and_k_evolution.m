date=datetime(2017,6,17)
%% Load data
dir='EBU2/'; doy=day(date,'dayofyear');
filename=['EBU2_',num2str(year(date)),'_',num2str(doy)];
load([dir,filename])

%% compute moving average with 15 min window
navg=901; GHI_avg=conv(GHI_day,ones(navg,1)/navg,'same');

%% compute clear sky radiation
addpath(genpath('../PV_LIB'))
Location.latitude = 32.881; Location.longitude = -117.232; Location.altitude = 125;
DN=time_day; Time = pvl_maketimestruct(DN,-8);
try
    [GHI_clearsky, ~, ~]= pvl_clearsky_ineichen(Time, Location,LinkeTurb);
catch
    [GHI_clearsky, ~, ~]= pvl_clearsky_ineichen(Time, Location);
end
time_clearsky = datetime(DN,'ConvertFrom','datenum');
[~, ~, ApparentSunEl, ~]=pvl_ephemeris(Time, Location);
SZA=90-ApparentSunEl;

%% Get clear sky index
k=GHI_day./GHI_clearsky;
k_avg=GHI_avg./GHI_clearsky;

%% Filter initial and final data with SZA<85
f=SZA<85; GHI.SZA=SZA(f); GHI.time=time_clearsky(f);
GHI.real=GHI_day(f);
GHI.avg=GHI_avg(f); GHI.clearsky=GHI_clearsky(f);
GHI.k=k(f); GHI.k_avg=k_avg(f);
GHI.times=datetime(time_day(f),'ConvertFrom','datenum');
subplot(133); plot(GHI.times,GHI.real,GHI.times,GHI.clearsky); ylabel('GHI'); drawnow

%% Plot!
subplot(121); plot(GHI.times,GHI.real,'-k',GHI.times,GHI.clearsky,'--r'); 
ylabel('Irradiance [W m^{-2}]')
legend('\it G_h','\it G_{cs}')
xlim([date+6/24 date+10/24])
text(0.02,0.98,'a)','Units', 'Normalized', 'VerticalAlignment', 'Top')

subplot(122); plot(GHI.times,GHI.k,'-k',GHI.times,GHI.k_avg,'--r'); 
ylabel('\it k')
legend('\it k','\it k_{15}')
xlim([date+5/24 date+12/24])
text(0.02,0.98,'b)','Units', 'Normalized', 'VerticalAlignment', 'Top')