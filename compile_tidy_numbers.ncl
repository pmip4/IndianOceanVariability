;This script cycles through all the files in a "data" directory and calculates the standard devations of the timeseries and their correlations/regressions

;History:
; 1. It was originally used to create the supplementary table for Brierley & Wainer (2018) - although that was then tidied up in Excel to make it presentable
; 2. It was then modified to output amplitude of EOF-based modes, as well as index-based ones. The output of this script was then plotted as Fig 3 in Rehfeld et al (2020,Earth Sys. Dynam.)
; 3. Now it's being overwritten to provide some tables as inputs for my PMIP4_past2future_analyzer repo

; run with:
; ncl -n data_scripts/mk_mode_tables.ncl

load "cvdp_data.functions.ncl"

data_dir="data/"
files=systemfunc("ls "+data_dir+"*.nc")
files = str_sub_str(files, data_dir, "")
;files=(/"INM-CM4-8_historical.cvdp_data.1850-2014.nc"/) ;select a single file for testing...


;define the filename for the outputting
fname="summary_data/tidy_numbers.csv"
system("rm -f "+fname)


; loop over the various CVDP files
do fi = 0, dimsizes(files)-1
  print("Working on "+files(fi))
  ;set up what to look over
  variables=new(50, string)
  headers=new(50, string)
  headers(0)="model"
  headers(1)="experiment"
  headers(2)="years"
  name_parts = str_split(files(fi),".")
  name_strs0 = str_split(name_parts(0),"_")
  name_strs2 = str_split(name_parts(2),"-")
  variables(0)=name_strs0(0) ;model
  if dimsizes(name_strs0).eq.1 then
    variables(1)="observations" ;experiment
  else
    variables(1)=name_strs0(1) ;experiment
  end if
  variables(2)=toint(name_strs2(1))-toint(name_strs2(0))+1 ;years

  ts_opt=True
  ts_opt@NO_EXIT_ON_ERROR=True
  if any(variables(1).eq.(/"1pctCO2","abrupt4xCO2","rcp26","rcp85"/)) then
    ts_opt@subset=True
    ts_opt@subset_syear=-30
    ts_opt@subset_eyear=0
    ts_opt@DETREND=True
  end if

  ;Global Mean TAS
  headers(3)="GMTemp"
  fil=addfile(data_dir+files(fi),"r")
  if .not.isfilevar(fil,"tas_spatialmean_ann") then
    variables(3)=variables@_FillValue
  else
    variables(3)=extract_latlon_areastat(data_dir+files(fi),"tas_spatialmean_ann",(/-90.,90./),(/0.,360./),"mean")
  end if
  delete(fil)

  ;IOD mean gradient
  ts_opt_abs=ts_opt
  ts_opt_abs@make_absolute=True
  ts_opt_abs@DETREND=False
  headers(4)="DMI mean"
  variables(4)=stat_ts_var(data_dir+files(fi),"iod_timeseries_mon","mean",ts_opt_abs)

  ;IOD Amplitude
  headers(5)="DMI stddev"
  variables(5)=stat_ts_var(data_dir+files(fi),"iod_timeseries_mon","stddev",ts_opt)

  ;Nino3.4 Amplitude
  headers(6)="Nino34 stddev"
  variables(6)=stat_ts_var(data_dir+files(fi),"nino34","stddev",ts_opt)

  ;Tropical Indian Ocean mean
  headers(7)="TIO mean"
  variables(7)=stat_ts_var(data_dir+files(fi),"tropical_indian_ocean","mean",ts_opt_abs)

  ;Indian Ocean Basin Mode
  headers(8)="IOBM"
  variables(8)=stat_ts_var(data_dir+files(fi),"tropical_indian_ocean","stddev",ts_opt)

  ;DMI Annual Cycle
  headers(9)="DMI AnnCycAmp"
  variables(9)=stat_ts_var(data_dir+files(fi),"iod_timeseries_mon","AnnCycAmp",ts_opt)

  ;Eastern Equatorial Indian Ocean 
  headers(10)="EEIO mean"
  variables(10)=stat_ts_var(data_dir+files(fi),"east_eq_indian_ocean","mean",ts_opt_abs)

  ;Indian Ocean Basin Mode
  headers(11)="EEIO stddev"
  variables(11)=stat_ts_var(data_dir+files(fi),"east_eq_indian_ocean","stddev",ts_opt)

  ;South Asian Monsoon Area
  headers(12)="SASmonsoon area mean"
  variables(12)=stat_ts_var(data_dir+files(fi),"monsoon_area_SAS","mean",ts_opt)

  ;South Asian Monsoon Rainrate
  headers(13)="SASmonsoon rain mean"
  variables(13)=stat_ts_var(data_dir+files(fi),"monsoon_rain_SAS","mean",ts_opt)

  ;South Asian Monsoon Area
  headers(14)="SASmonsoon area stddev"
  variables(14)=stat_ts_var(data_dir+files(fi),"monsoon_area_SAS","stddev",ts_opt)

  ;South Asian Monsoon Rainrate
  headers(15)="SASmonsoon rain stddev"
  variables(15)=stat_ts_var(data_dir+files(fi),"monsoon_rain_SAS","stddev",ts_opt)

  ;Subcontinent annual rain
  headers(16)="SAS rain ann"
  variables(16)=stat_ts_var(data_dir+files(fi),"ipcc_SAS_lnd_pr","mean",ts_opt_abs)

  ;Subcontinent summer rain
  ts_opt_jja_abs=ts_opt_abs
  ts_opt_jja_abs@SEASON="JJA"
  headers(17)="SAS rain jja"
  variables(17)=stat_ts_var(data_dir+files(fi),"ipcc_SAS_lnd_pr","mean",ts_opt_jja_abs)

  ;Subcontinent winter rain
  ts_opt_djf_abs=ts_opt_abs
  ts_opt_djf_abs@SEASON="DJF"
  headers(18)="SAS rain djf"
  variables(18)=stat_ts_var(data_dir+files(fi),"ipcc_SAS_lnd_pr","mean",ts_opt_djf_abs)

  ;Subcontinent summer rain stddev
  ts_opt_jja=ts_opt
  ts_opt_jja@SEASON="JJA"
  headers(19)="SAS rain jja stddev"
  variables(19)=stat_ts_var(data_dir+files(fi),"ipcc_SAS_lnd_pr","stddev",ts_opt_jja)

  ;Subcontinent winter rain stddev
  ts_opt_djf=ts_opt
  ts_opt_djf@SEASON="DJF"
  headers(20)="SAS rain djf stddev"
  variables(20)=stat_ts_var(data_dir+files(fi),"ipcc_SAS_lnd_pr","stddev",ts_opt_djf)

  ;compute correlations
  ts_opt_smooth=ts_opt
  ts_opt_smooth@SMOOTH=True
  ts_opt_smooth@nave=5
  nino34=read_ts(data_dir+files(fi),"nino34",ts_opt_smooth)
  iod=read_ts(data_dir+files(fi),"iod_timeseries_mon",ts_opt_smooth)
  iobm=read_ts(data_dir+files(fi),"tropical_indian_ocean",ts_opt_smooth)
  eeio=read_ts(data_dir+files(fi),"east_eq_indian_ocean",ts_opt_smooth)

  headers(21)="r(nino34.iod)"
  if (.not.all(ismissing(nino34))).and.(.not.all(ismissing(iod))) then
    variables(21)=escorc(nino34,iod)   
  else
    variables(21)=variables@_FillValue   
  end if

  headers(22)="r(iod.iobm)"
  if .not.all(ismissing(iobm)).and..not.all(ismissing(iod)) then
    variables(22)=escorc(iobm,iod)   
  else
    variables(22)=variables@_FillValue   
  end if
  
  headers(23)="r(iod.eeio)"
  if .not.all(ismissing(eeio)).and..not.all(ismissing(iod)) then
    variables(23)=escorc(eeio,iod)   
  else
    variables(23)=variables@_FillValue   
  end if
  delete([/nino34,iod,iobm,eeio/])

  ;IOD Period
  headers(24)="IOD Period"
  variables(24)=stat_ts_var(data_dir+files(fi),"iod_timeseries_mon","dominant_period_interann",ts_opt)

  ;ENSO Period
  headers(25)="ENSO Period"
  variables(25)=stat_ts_var(data_dir+files(fi),"nino34","dominant_period_interann",ts_opt)
 
  ;IOD Period
  headers(26)="IOBM Period"
  variables(26)=stat_ts_var(data_dir+files(fi),"tropical_indian_ocean","dominant_period_interann",ts_opt)

  ;IOD Period
  headers(27)="EEIO Period"
  variables(27)=stat_ts_var(data_dir+files(fi),"east_eq_indian_ocean","dominant_period_interann",ts_opt)
  
  ;write out to file
  exists=ind(.not.ismissing(headers))
  if fi.eq.0 then
    hlist=[/str_join(headers(exists),",")/]
    write_table(fname, "w", hlist, "%s")
  end if 
  vlist=[/str_join(variables(exists),",")/]
  write_table(fname, "a", vlist, "%s")

  delete([/headers,variables,ts_opt,ts_opt_abs,ts_opt_jja,ts_opt_djf,ts_opt_jja_abs,ts_opt_djf_abs,ts_opt_smooth/])
end do