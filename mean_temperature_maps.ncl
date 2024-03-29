;This script was used to create sufficient figures to populate a research publication
;It makes full use of the programs in cvdp_data.functions.ncl to plot figures solely from the output data of cvdp (without needing recomputation).
;The code it set up to look at the Indian Ocean Dipole.
; It makes 1 table (showing simulations used) and many figures. 

;load the NCL functions from Zhao et al (2021; https://doi.org/10.5194/gmd-15-2475-2022)
; These functions are lots of plotting and searching functions. They are hardwired to look for the data in data/
load "cvdp_data.functions.ncl"

plot_regions=(/(/-35,35/),(/30,130/)/);lat and lons of the edge of the plots (/(/lonW,lonE/),(/latS,latN/)/)
expts=(/"midHolocene-cal-adj","lig127k-cal-adj","lgm-cal-adj","abrupt4xCO2"/)

;some plot switches
MAKE_PLOT=True;if True, this will actually output the plot in it's pretty form
OUTPUT_PLOT_DATA=False;if True, this will actually output the combined
if MAKE_PLOT.eq.OUTPUT_PLOT_DATA then 
   print("You set both MAKE_PLOT and OUTPUT_PLOT_DATA to "+MAKE_PLOT+". The code is not set-up for both options to be True, and will do all")
   print("The code is not set-up for both options to be True, and will do all computation and not output anythign is both are False")
   exit
end if
if MAKE_PLOT then
    OUTPUT_TYPE="pdf"; either "png" or "pdf"
else
    OUTPUT_TYPE="png"; either "png" or "pdf"
end if
TS_NOT_TAS=False ;if True use SST rather TAS in the figure
VERBOSE=False ;if True, provides a modicum of more information about whats goign on in the plots - used for debugging mainly.

if TS_NOT_TAS then
  vars=(/"sst_spatialmean_ann","sst_spatialmean_djf","sst_spatialmean_jja"/)
  plot_str="plots/mean_sea_temperature_maps"
else
  vars=(/"tas_spatialmean_ann","tas_spatialmean_djf","tas_spatialmean_jja"/)
  plot_str="plots/mean_air_temperature_maps"
end if

plot_letters=(/(/"a","b","c"/),(/"d","e","f"/),(/"g","h","i"/),(/"j","k","l"/)/)


;First deal with the data outputting (uses default plotting and creates lots of maps) 
if OUTPUT_PLOT_DATA then
  OPTS=True
  OPTS@filetype=OUTPUT_TYPE
  OPTS@VERBOSE=VERBOSE
  do expt_i=0,dimsizes(expts)-1
    do var_i=0,2
        title="summary_data/"+expts(expt_i)+"-piControl_"+vars(var_i)+"_EnsembleMean"
        plot_output_DiffEnsMn(expts(expt_i),"piControl",vars(var_i),title,OPTS)
    end do
  end do
end if

if MAKE_PLOT then
  ;Rather than immediately sending the plot to a file, this plot first opens a wks and panels within it. 
  wks=gsn_open_wks(OUTPUT_TYPE,plot_str)
  wks@VERBOSE=VERBOSE

  ; Set-up some initial NCL plot options ;
  opt=True
    opt@mpProjection="CylindricalEqualArea"
    opt@gsnStringFontHeightF=0.03
    opt@lbLabelFontHeightF=0.018
    opt@mpLimitMode="LatLon"
    opt@mpMinLonF=plot_regions(1,0)
    opt@mpMaxLonF=plot_regions(1,1)
    opt@mpMinLatF=plot_regions(0,0)
    opt@mpMaxLatF=plot_regions(0,1)
    opt@tiMainString=""
    opt@gsnCenterString=""
    opt@gsnRightString=""
    opt@lbLabelBarOn=False
    opt@cnFillPalette="temp_19lev"
    opt@cnLevelSelectionMode = "ExplicitLevels"   
    opt@cnLevels=(/-5.,-4.,-3.,-2.,-1.,-.75,-0.5,-0.25,-0.1,0.1,0.25,0.5,0.75,1.,2.,3.,4.,5./)
    opt@cnMinLevelValF = -6
    opt@cnMaxLevelValF = 6
    opt@cnLevelSpacingF = 0.2
    opt@CONSISTENCY=True ;Turn on Stippling


  opt_pan=True
    opt_pan@lbTitleFontHeightF=0.02
    opt_pan@lbLabelFontHeightF=0.016
    opt_pan@gsnFrame=False
    opt_pan@gsnMaximize=True
    opt_pan@lbTitlePosition="Bottom"
    opt_pan@gsnPanelLabelBar=False
    opt_pan@lbTitleOn=True
    opt_pan@dims=(/1,3/)
    opt_pan@lbTitleString="Temperature Change (oC)"

  do expt_i=0,dimsizes(expts)-1
    opt_pan@gsnPanelTop=1.-0.9*(tofloat(expt_i)/tofloat(dimsizes(expts)))
    opt_pan@gsnPanelBottom=1.-0.9*(tofloat(expt_i)/tofloat(dimsizes(expts)))-(0.9/tofloat(dimsizes(expts)))
    opt@gsnLeftString=plot_letters(expt_i,:)
    plotDiffEnsMnMaps(expts(expt_i),"piControl",vars,wks,opt,opt_pan)
  end do
  opt_pan@gsnPanelTop=0.1
  opt_pan@gsnPanelBottom=0.0
  opt_pan@gsnPanelLabelBar=True
  opt@gsnDraw=False
  plotDiffEnsMnMaps(expts(0),"piControl",vars,wks,opt,opt_pan)
  frame(wks)
  delete(wks)
end if