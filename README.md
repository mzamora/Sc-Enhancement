# Sc-Enhancement

Mónica Zamora Zapata, Elynn Wu, Jan Kleissl. “Irradiance enhancement events in the coastal Stratocumulus dissipation process” Solar World Congress. Santiago, 2019 (Accepted)

## Enhancement events
To follow the enhancement detection and processing, take a look at `main.m`. While the detection and characterization of IE events is done automatically, we manually checked if a day presented a Stratocumulus to clear transition. That was done by looking at the GHI timeseries. In case of doubt, we further checked sky imagery. The classification is available at `CloudClasses_TL.mat`.

Note that the `NKX_stats.mat` dataset has processed sounding data. More on that is available at the Sc-utils repository.

## Ramp-rate control
This part was coded in python `Ramp_rate_control.py`. It takes the GHI data from a single day and converts it to power. We use that power and its 15 min average as two idealized forecasts and then do 1 second ramp-rate control. 

---
mzamoraz at eng dot ucsd dot edu

San Diego, August 2019
