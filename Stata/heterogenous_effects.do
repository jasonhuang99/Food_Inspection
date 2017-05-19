
set more off

cd "~/Desktop/NYC Food Inspection/Data/DTA"
use inspect_processed.dta, clear

cd "~/Dropbox/Research Ideas/Food Inspection Scores/New York/Tex/Tables/hetero/"

label define boro_label ///
1 "Manhattan" 2 "The Bronx" 3 "Brooklyn" 4 "Queens" 5 "Staten Isl."

label values BORO boro_label

drop if BORO == 0
quietly levelsof BORO, local(boro_levels)

reghdfe SCORE LO_SCORE2 ///
if post == 1 & inspect_type  == 1 & inspector_cnt > 50,  ///
a(i = INSPDATE c = CAMIS n = next_same_type_date) cluster(InspectorID ZIPCODE) 

foreach boro of local boro_levels {
	local curr_boro: label (BORO) `boro'
	
	qui: reghdfe n_same_type_A (SCORE = LO_SCORE2) ///
	if post == 1 & inspect_type  == 1 & inspector_cnt > 50 & BORO == `boro', ///
	a(INSPDATE CAMIS next_same_type_date ) ///
	cluster(InspectorID ZIPCODE)     
	qui: estadd ysumm
	
	outreg2 using next_A_boro.tex, append tex(frag) label ///
	ctitle("`curr_boro'") nor2 ///
	addtext(Inspection Date FE, YES, Restaurant FE, YES)    ///
	addstat("Dependent mean", e(ymean)) 

	qui: reghdfe n_same_type_shutdown (SCORE = LO_SCORE2) ///
	if post == 1 & inspect_type  == 1 & inspector_cnt > 50 & BORO == `boro', ///
	a(INSPDATE CAMIS next_same_type_date ) ///
	cluster(InspectorID ZIPCODE)     
	qui: estadd ysumm
	disp r(ymean)
	
	outreg2 using shutdown_next_boro.tex, append tex(frag) label ///
	ctitle("`curr_boro'") nor2 ///
	addtext(Inspection Date FE, YES, Restaurant FE, YES) ///
	addstat("Dependent mean", e(ymean)) 
	
	qui: reghdfe n_same_type_score (SCORE = LO_SCORE2) ///
	if post == 1 & inspect_type  == 1 & inspector_cnt > 50 & BORO == `boro', ///
	a(INSPDATE CAMIS next_same_type_date ) ///
	cluster(InspectorID ZIPCODE)     
	qui: estadd ysumm
	disp r(ymean)
	
	outreg2 using next_score_boro.tex, append tex(frag) label ///
	ctitle("`curr_boro'") nor2 ///
	addtext(Inspection Date FE, YES, Restaurant FE, YES) ///
	addstat("Dependent mean", e(ymean)) 
}

qui: reghdfe SCORE i.inspect_type if post == 1, ///
absorb(i = INSPDATE c = CAMIS) cluster(InspectorID ZIPCODE)

predict score_pred, xbd
qui: sum score_pred, detail

local p25 = r(p25)
local p50 = r(p50)
local p75 = r(p75)

disp `p25'
disp `p50'
disp `p75'

reghdfe n_same_type_score (SCORE = LO_SCORE2) ///
if post == 1 & inspect_type == 1 & inspector_cnt > 50, ///
absorb(INSPDATE CAMIS) ///
cluster(InspectorID ZIPCODE)
//qui: 
reghdfe n_same_type_score (SCORE = LO_SCORE2) ///
if post == 1 & inspect_type == 1 & inspector_cnt > 50 & score_pred <= `p25', ///
absorb(INSPDATE ZIPCODE chain cuisine service venue) ///
cluster(InspectorID ZIPCODE)
/*
outreg2 using quartile`f'.tex, replace tex(frag) label ///
ctitle("1st Quartile") nor2 long title("`title'") */

//qui: 
reghdfe n_same_type_score (SCORE = LO_SCORE2) ///
if post == 1 & inspect_type == 1 & inspector_cnt > 50 & score_pred <= `p50' & score_pred > `p25', ///
absorb(INSPDATE ZIPCODE chain cuisine service venue) ///
cluster(InspectorID ZIPCODE)
/* outreg2 using quartile`f'.tex, append tex(frag) label ///
ctitle("2nd") nor2 long */

//qui: 
reghdfe n_same_type_score (SCORE = LO_SCORE2) ///
if post == 1 & inspect_type == 1 & inspector_cnt > 50 & score_pred <= `p75' & score_pred > `p50', ///
absorb(INSPDATE ZIPCODE chain cuisine service venue) ///
cluster(InspectorID ZIPCODE)
/* outreg2 using quartile`f'.tex, append tex(frag) label ///
ctitle("3nd") nor2 long */

//qui: 
reghdfe n_same_type_score (SCORE = LO_SCORE2) ///
if post == 1 & inspect_type == 1 & inspector_cnt > 50 & score_pred > `p75', ///
absorb(INSPDATE ZIPCODE chain cuisine service venue) ///
cluster(InspectorID ZIPCODE)
/* outreg2 using quartile`f'.tex, append tex(frag) label ///
ctitle("4th") nor2 long */
