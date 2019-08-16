#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Code for battery ramp-rate control 

Mónica Zamora Z., SRAF at UCSD
July, 2019
"""

import numpy as np
import datetime as dt
import pandas as pd
import pvlib
from pvlib import pvsystem
from pvlib.location import Location
from pvlib.modelchain import ModelChain
import seaborn as sns
import scipy.io
import matplotlib.pyplot as plt
import matplotlib.dates as mdates

sns.set(style="ticks",font_scale=1.1)

''' read GHI (mat format) '''
mat = scipy.io.loadmat('EBU2/EBU2_2017_173.mat',squeeze_me=True)
GHI=mat['GHI_day']

# convert Matlab datenum to datetime
def matlab2datetime(matlab_datenum):
    day = dt.datetime.fromordinal(int(matlab_datenum))
    dayfrac = dt.timedelta(days=matlab_datenum%1) - dt.timedelta(days = 366)
    return day + dayfrac + dt.timedelta(hours=8)
time = [matlab2datetime(tval) for tval in mat['time_day']]

# plot ghi to check 
ghi=pd.DataFrame(GHI,time,columns=['ghi'])
ax=ghi.plot()
ax.set_xlabel('Time [UTC]]')
ax.set_ylabel('GHI [W/m²]')


'''separate dhi and dni from ghi'''
sd = Location(32.883729,-117.239341)
sza=sd.get_solarposition(time).zenith # zenith angle
out=pvlib.irradiance.erbs(GHI,sza,pd.DatetimeIndex(time)) #using erbs method

# plot ghi dni dhi
irr=pd.concat([ghi,out['dni'],out['dhi']],axis=1) #concatenate irradiances
ax3=irr.plot(title='Erbs method')
ax3.set_xlabel('Time [UTC]')
ax3.set_ylabel('Irradiance [W/m²]')

'''convert irradiance to power'''

#load modules and inverters
sandia_modules = pvlib.pvsystem.retrieve_sam('SandiaMod')
cec_inverters = pvlib.pvsystem.retrieve_sam('cecinverter')
# sma_cols = [col for col in cec_inverters.columns if 'SMA' in col] # use to look for strings
# Equipment at EBU2:
inverter = cec_inverters['SMA_America__SB7000US__240V__w___11_or__12_240V__CEC_2012_'] #42 modules
module = sandia_modules['Kyocera_Solar_KD205GX_LP__2008__E__']
system = pvsystem.PVSystem(surface_tilt=10, surface_azimuth=180,
                  module_parameters=module,
                  inverter_parameters=inverter) #only takes one single module
system.module_parameters['pdc0'] = 10
system.module_parameters['gamma_pdc'] = -0.004 #temperature efficiency loss
system.modules_per_string=42
Pinv=7000 #inverter nominal power
weather=irr #bypassing temp and wind

#________Create model chain
mc = ModelChain(system, sd, aoi_model='physical',name='test')
mc.transposition_model = 'perez'

#________Run the model
mc.run_model(times=weather.index, weather=weather)
power = mc.ac /1000. #in kW
power.name = 'Power forecast'
   
#_______Plot AC output
ax5=power.plot(title='AC Power (from GHI)')
ax5.set_xlabel('Time [UTC]')
ax5.set_ylabel('Power [kW]')

#______Plot DC input
dcpower=mc.dc['p_mp']
dcpower[np.isnan(dcpower)]=0
ax6=mc.dc['p_mp'].plot(title='DC power (from GHI)')
ax6.set_xlabel('Time [UTC]')
ax6.set_ylabel('Power [W]')

# function to print battery stats
isc0=18662; isc1=22202 # time window to zoom into the breakup period
def print_batterystats():
    print ('All the time period')
    print ('Max. P bat: ' + str(np.max(P_bat/1000)) + '[kW]')
    print ('Min. P bat: ' + str(np.min(P_bat/1000)) + '[kW]')
    print ('Max.-Min. SOC: ' + str(np.max(SOC)-np.min(SOC)) + '[Wh]')
    print ('Final-Initial SOC: ' + str(SOC[-1]-SOC[0]) + '[Wh]')
    
    print ('Sc-IE only')
    print ('Max. P bat: ' + str(np.max(P_bat[isc0:isc1]/1000)) +'[kW]')
    print ('Min. P bat: ' + str(np.min(P_bat[isc0:isc1]/1000)) +'[kW]')
    print ('Max. SOC - Min. SOC: ' + str(np.max(SOC[isc0:isc1])-np.min(SOC[isc0:isc1])) + '[Wh]')
    print ('Final-Initial SOC: ' + str(SOC[isc1]-SOC[isc0]) + '[Wh]')
    print ('Energy output before control: '+str(np.sum(dcpower[isc0:isc1])/3600) + '[Wh]')
    print ('Energy output after control: '+str(np.sum(P_g[isc0:isc1])/3600) + '[Wh]')

def plot_Pbat():
    #______Plot Battery power
    ax8=outPbat.plot(title='Battery power')
    ax8.set_xlabel('Time [UTC]')
    ax8.set_ylabel('Charge/Discharge [kW]')

def plot_SOC():
    #_____Plot SOC
    ax9=outSOC.plot(title='SOC')
    ax9.set_xlabel('Time [UTC]')
    ax9.set_ylabel('SOC [Wh]')
    
def plot_DC_with_control():
    #_____Plot gen. power vs original DC power
    outP=pd.concat([mc.dc['p_mp']/1000,outPg/1000],axis=1)
    outP.columns=['Original','w/Control']
    ax10=outP.plot(title='Ramp rate control effect')
    ax10.set_xlabel('Time [UTC]')
    ax10.set_ylabel('DC power [kW]')

##################### Ramp rate control algorithm (1s version)
P_g=np.zeros(len(dcpower)) #generated power
P_bat=np.zeros(len(dcpower)) #Battery power
SOC=np.zeros(len(dcpower)) # State of charge
# first time step, we assume Pg=PDC, SOC=0
P_g[0]=dcpower[0]
P_bat[0]=0
SOC[0]=0
# rest of time steps
for it in range(1,len(dcpower)):
    ramprate=(dcpower[it]-P_g[it-1])/Pinv*100*60# 1s ramp
    if np.abs(ramprate)<=10:
        P_g[it]=dcpower[it]
    else:
        #print(it)
        #break
        P_g[it]=P_g[it-1]+np.sign(ramprate)*10/6000*Pinv #1s ramp
        #P_g[it]=0
    P_bat[it]=dcpower[it]-P_g[it]
    SOC[it]=SOC[it-1]+P_bat[it]/3600 # time step is 1s, to Wh
outPg=pd.DataFrame(P_g,time)
outPbat=pd.DataFrame(P_bat/1000,time) #in kW
outSOC=pd.DataFrame(SOC,time)    

plot_Pbat()
plot_SOC()
plot_DC_with_control()
print_batterystats()

Pg_1s=outPg; Pbat_1s=outPbat; SOC_1s=outSOC;
    
#################### 15 min average vs perfect forecast
PerfectForecast=pd.DataFrame(dcpower.values,time)
F_15=PerfectForecast.resample('15min').mean()
fc=F_15.resample('1s').first().interpolate()
dcpow=pd.DataFrame(dcpower,time)

fig = plt.figure()
ax = fig.add_subplot(111)
ax.plot(dcpow.index-dt.timedelta(hours=7),dcpower/1000,label='Perfect forecast')
ax.plot(fc.index-dt.timedelta(hours=7),fc/1000,label='Mean forecast')
plt.legend()
ax.xaxis.set_major_formatter(mdates.DateFormatter('%H:%M'))
fig.autofmt_xdate()
plt.xlabel('Time [hh]'); plt.ylabel('DC power [kW]')

##################### Ramp rate control algorithm (1s version)
P_g=np.zeros(len(dcpower)) #generated power
P_bat=np.zeros(len(dcpower)) #Battery power
SOC=np.zeros(len(dcpower)) # State of charge
# first time step, we assume Pg=PDC, SOC=0
P_g[0]=dcpower[0]
P_bat[0]=0
SOC[0]=0
# rest of time steps
for it in range(1,len(dcpower)):
    # get forecast at it, to decide what to do at it
    forecast=fc.iloc[fc.index.get_loc(time[it],method='nearest')].values
    ramprate=(forecast-P_g[it-1])/Pinv*100*60# 1min ramp

    if np.abs(ramprate)<=10:
        P_g[it]=dcpower[it]
    else:
        #print(it)
        #break
        P_g[it]=P_g[it-1]+np.sign(ramprate)*10/6000*Pinv #1s ramp
        #P_g[it]=0
    P_bat[it]=dcpower[it]-P_g[it]
    SOC[it]=SOC[it-1]+P_bat[it]/3600 # time step is 1s, to Wh
outPg=pd.DataFrame(P_g,time)
outPbat=pd.DataFrame(P_bat/1000,time) #in kW
outSOC=pd.DataFrame(SOC,time)

Pg_fc=outPg; Pbat_fc=outPbat; SOC_fc=outSOC;
plot_DC_with_control()
plot_Pbat()
plot_SOC()
plot_DC_with_control()
print_batterystats()

# comparing DC power output
fig = plt.figure()
ax = fig.add_subplot(111)
ax.plot(dcpow.index-dt.timedelta(hours=7),dcpower/1000,label='Original')
ax.plot(dcpow.index-dt.timedelta(hours=7),Pg_1s/1000,label='Perfect forecast')
ax.plot(dcpow.index-dt.timedelta(hours=7),Pg_fc/1000,label='Mean forecast')
plt.legend()
ax.xaxis.set_major_formatter(mdates.DateFormatter('%H:%M'))
fig.autofmt_xdate()
plt.xlabel('Time [hh]'); plt.ylabel('DC power [kW]')

# comparing P bat
fig = plt.figure()
ax = fig.add_subplot(111)
ax.plot(time,Pbat_fc,label='Mean forecast')
ax.plot(time,Pbat_1s,label='Perfect forecast')
plt.legend()
ax.xaxis.set_major_formatter(mdates.DateFormatter('%H:%M'))
fig.autofmt_xdate()
plt.xlabel('Time [UTC]'); plt.ylabel('DC power [kW]')

# comparing SOC
fig = plt.figure()
ax = fig.add_subplot(111)
ax.plot(time,SOC_fc,label='Mean forecast')
ax.plot(time,SOC_1s,label='Perfect forecast')
plt.legend()
ax.xaxis.set_major_formatter(mdates.DateFormatter('%H:%M'))
fig.autofmt_xdate()
plt.xlabel('Time [hh]'); plt.ylabel('SOC [Wh]')