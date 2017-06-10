/****
** Dif-on-Dif on inspection scores on prob of calls
**************************/
set more off

cd "~/Desktop/NYC Food Inspection/Data/DTA"
use geocoded_camis.dta, clear
sort CAMIS
save geocoded_camis.dta, replace

use calls_month.dta, clear

sort CAMIS InspectorID

//Consider only whether a complaint call occured or not. 
gen called_vis = min(Counted_Calls_vis,1)
gen called_vis_non_LG = min(Counted_Calls_vis_non_LG,1)
gen called_vis_LG = called_vis - called_vis_non_LG
gen called = min(Counted_Calls,1)

joinby CAMIS InspectorID using inspector_score

sort CAMIS
merge CAMIS using geocoded_camis.dta

gen mon_from_inspect = (year - year(INSPDATE))*12 + (month - month(INSPDATE))
encode INSPTYPE, gen(inspect_type)
gen month_year = mdy(month, 1, year)
gen next_month = month_year + 32
gen mnth_yr_end = mdy(month(next_month),1,year(next_month)) - 1
drop next_month

gen weight = (mnth_yr_end - max(month_year,INSPDATE) + 1)/(mnth_yr_end - month_year+1)
gen weight_vis = (mnth_yr_end - max(month_year,INSPDATE_vis)+1)/(mnth_yr_end - month_year+1)

label variable mon_from_inspect "Months Since Inspection"
cd "~/Dropbox/Research Ideas/Food Inspection Scores/New York/Tex/Tables/Calls/"

reghdfe called_vis_non_LG SCORE if inspector_cnt > 50, ///
a(CAMIS month_year) cluster(CAMIS InspectorID)
qui: estadd ysumm
outreg2 using calls.tex, replace tex(frag) label                     ///
ctitle("Prob Call (OLS)") addstat("dependent mean", e(ymean)) ///
nor2 addtext(Year-Month FE, YES, Restaurant FE, YES) 

reghdfe called_vis_non_LG SCORE mon_from_inspect if inspector_cnt > 50, ///
a(CAMIS month_year) cluster(CAMIS InspectorID)
qui: estadd ysumm 
outreg2 using calls.tex, append tex(frag) label                     ///
ctitle("Prob Call (OLS)") addstat("dependent mean", e(ymean)) ///
nor2 addtext(Year-Month FE, YES, Restaurant FE, YES) 

reghdfe called_vis_non_LG SCORE mon_from_inspect c.mon_from_inspect#c.SCORE ///
if inspector_cnt > 50, ///
a(CAMIS month_year) cluster(CAMIS InspectorID)
qui: estadd ysumm 
outreg2 using calls.tex, append tex(frag) label                     ///
ctitle("Prob Call (OLS)") addstat("dependent mean", e(ymean)) ///
nor2 addtext(Year-Month FE, YES, Restaurant FE, YES) 

reghdfe called_vis_non_LG  ///
( SCORE = LO_SCORE2 ) if inspector_cnt > 50, ///
a(CAMIS month_year) cluster(CAMIS InspectorID)
qui: estadd ysumm 
outreg2 using calls.tex, append tex(frag) label                     ///
ctitle("Prob Call (IV)") addstat("dependent mean", e(ymean)) ///
nor2 addtext(Year-Month FE, YES, Restaurant FE, YES) 

reghdfe called_vis_non_LG mon_from_inspect  ///
( SCORE = LO_SCORE2 ) if inspector_cnt > 50, ///
a(CAMIS month_year) cluster(CAMIS InspectorID)
qui: estadd ysumm 
outreg2 using calls.tex, append tex(frag) label                     ///
ctitle("Prob Call (IV)") addstat("dependent mean", e(ymean)) ///
nor2 addtext(Year-Month FE, YES, Restaurant FE, YES) 

reghdfe called_vis_non_LG mon_from_inspect ///
(SCORE c.mon_from_inspect#c.SCORE = LO_SCORE2 c.LO_SCORE2#c.mon_from_inspect) ///
if inspector_cnt > 50, ///
a(CAMIS month_year) cluster(CAMIS InspectorID)
qui: estadd ysumm 
outreg2 using calls.tex, append tex(frag) label                     ///
ctitle("Prob Call (IV)") addstat("dependent mean", e(ymean)) ///
nor2 addtext(Year-Month FE, YES, Restaurant FE, YES) 



