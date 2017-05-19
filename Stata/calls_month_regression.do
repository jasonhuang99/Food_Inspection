set more off

cd "~/Desktop/NYC Food Inspection/Data/DTA"
use geocoded_camis.dta, clear
sort CAMIS
save geocoded_camis.dta, replace

use calls_month.dta, clear

sort CAMIS InspectorID

//Consider only whether a complaint call occured or not. 
gen called_vis = min(Counted_Calls_vis,1)
gen called = min(Counted_Calls,1)

joinby CAMIS InspectorID using inspector_score

sort CAMIS
merge CAMIS using geocoded_camis.dta

/* egen called_ever = max(called), by(CAMIS)
keep if _merge == 3 | called_ever */

encode INSPTYPE, gen(inspect_type)
gen month_year = mdy(month, 1, year)
gen next_month = month_year + 32
gen mnth_yr_end = mdy(month(next_month),1,year(next_month)) - 1
drop next_month

gen weight = (mnth_yr_end - max(month_year,INSPDATE) + 1)/(mnth_yr_end - month_year+1)
gen weight_vis = (mnth_yr_end - max(month_year,INSPDATE_vis)+1)/(mnth_yr_end - month_year+1)
by visible_score, sort: gen vis_score_uniq = _n == 1
by SCORE, sort: gen score_uniq = _n == 1

/*
reghdfe called SCORE [w = weight], ///
a(CAMIS month_year) cluster(ZIPCODE InspectorID)

reghdfe Counted_Calls (SCORE = LO_SCORE2) [w = weight], ///
a(CAMIS month_year) cluster(ZIPCODE InspectorID)

reghdfe Counted_Calls inspect_type (SCORE c.SCORE#inspect_type = LO_SCORE2 c.LO_SCORE2#inspect_type) ///
if inspect_type == 1 | inspect_type == 2, ///
a(CAMIS month_year) cluster(ZIPCODE InspectorID)

reghdfe called (SCORE = LO_SCORE2) [w = weight] if inspect_type == 2, ///
a(CAMIS month_year) cluster(ZIPCODE InspectorID)

reghdfe Counted_Calls visible_score if num_inspect == 0, ///
a(CAMIS month_year) cluster(ZIPCODE InspectorID)  */

/*********** Make Plots ****************/
reghdfe called_vis i.visible_score ///
if visible_score <= 40 & visible_score >= 0 [w = weight_vis], ///
a(CAMIS month_year) cluster(CAMIS InspectorID)

predict calls_visible, xb

reghdfe called i.SCORE if SCORE <= 40, ///
a(CAMIS month_year) cluster(CAMIS InspectorID)

predict calls_scores, xb

twoway (hist Modified_Score if Modified_Score <= 40, ///
discrete width(1) gap(50) bcolor(gs11) graphregion(color(white)) yaxis(1) xtitle("")) ///
(scatter calls_visible visible_score ///
if vis_score_uniq == 1 & visible_score <= 40 & visible_score >= 0, ///
xline(13.5) xline(27.5) yaxis(2) mcolor(navy))  ///
(scatter calls_scores SCORE ///
if score_uniq == 1 & SCORE <= 40, yaxis(2) mcolor(green)) ///
(fpfit calls_score SCORE ///
if score_uniq == 1 & SCORE <= 13, yaxis(2) lcolor(green)) ///
(fpfit calls_scores SCORE ///
if score_uniq == 1 & SCORE >= 28 & SCORE <= 40, ///
yaxis(2) lcolor(green)) ///
(fpfit calls_scores SCORE ///
if score_uniq == 1 & SCORE >= 14 & SCORE <= 27, ///
yaxis(2) lcolor(green)) ///
(fpfit calls_visible visible_score ///
if vis_score_uniq == 1 & visible_score <= 13, yaxis(2) lcolor(navy)) ///
(fpfit calls_visible visible_score ///
if vis_score_uniq == 1 & visible_score >= 28 & visible_score <= 40, ///
yaxis(2) lcolor(navy)) ///
(fpfit calls_visible visible_score ///
if vis_score_uniq == 1 & visible_score >= 14 & visible_score <= 27, ///
yaxis(2) lcolor(navy)),  ///
ylabel(0(0.01)0.02,axis(2)) ///
legend(order(1 "Density" 2 "Visible Scores" 3 "Underlying Scores") cols(3)) ///
title("Monthly Probability of Complaint Calls and Visible Scores")

cd "~/Dropbox/Research Ideas/Food Inspection Scores/New York/Tex/Figures/Calls"
graph export score_calls_hist_vis.png, replace

/*
gen grade_C = visible_score > 27

gen visible_grade = "A" if visible_score <= 13 & visible_score >= 0
replace visible_grade = "B" if visible_score <= 27 & visible_score > 13
replace visible_grade = "C" if visible_score > 27 
replace visible_grade = "P" if visible_score < 0
encode visible_grade , gen(visible_grade_enc)
drop visible_grade
rename visible_grade_enc visible_grade



sort CAMIS month_year, stable
foreach l of numlist 1/5 {
	disp `l'
	by CAMIS: gen lag_grade_`l' = visible_grade[_n - `l']
	by CAMIS: gen lag_num_inspect_`l' = num_inspect[_n - `l']
	
	by CAMIS: gen led_grade_`l' = visible_grade[_n + `l']
	by CAMIS: gen led_num_inspect_`l' = num_inspect[_n + `l']
}
foreach l of numlist 1/5 {
	label define lag_level`l' 1 "A t = `'" 2 "B t = `l'" 3 "C t =`l'" 4 "P t = `l'"
	label values lag_grade_`l' lag_level`l'
	label define led_level`l' 1 "A t = -`'" 2 "B t = -`l'" 3 "C t = -`l'" 4 "P t = -`l'"
	label values led_grade_`l' led_level`l'
}


gen SCORE_pwr2 = SCORE*SCORE

reghdfe Counted_Calls_vis i.visible_grade SCORE SCORE_pwr2 [w = weight_vis], ///
a(CAMIS month_year) cluster(ZIPCODE InspectorID)

reghdfe Counted_Calls i.lag_grade_1 SCORE SCORE_pwr2, ///
a(CAMIS month_year) cluster(ZIPCODE InspectorID)

reghdfe called_vis ///
i.led_grade_5 i.led_grade_4 i.led_grade_3 i.led_grade_2 i.led_grade_1 ///
i.visible_grade ///
i.lag_grade_* , ///
a(CAMIS month_year) cluster(ZIPCODE InspectorID)

/***************** Coefficient Plots ***************************************/
local span = 20
local dif = 4
gen time = `span'*(_n - 6)
replace time = time - (11*`span' + `dif') if time > 5*`span' & time <= 17*`span'
replace time = time - (23*`span' - `dif') if time > 17*`span' & time <= 29*`span'
gen B = _b[2.visible_grade] if time == -`dif'
gen C = _b[3.visible_grade] if time == 0
gen P = _b[4.visible_grade] if time == `dif'

gen B_se = _se[2.visible_grade] if time == -`dif'
gen C_se = _se[3.visible_grade] if time == 0
gen P_se = _se[4.visible_grade] if time == `dif'

foreach l of numlist 1/5 {
	replace B = _b[2.led_grade_`l'] if time == -`span'*`l' - `dif'
	replace B = _b[2.lag_grade_`l'] if time ==  `span'*`l' - `dif'
	replace C = _b[3.led_grade_`l'] if time == -`span'*`l' 
	replace C = _b[3.lag_grade_`l'] if time ==  `span'*`l'  
	replace P = _b[4.led_grade_`l'] if time == -`span'*`l' + `dif' 
	replace P = _b[4.lag_grade_`l'] if time ==  `span'*`l' + `dif'
	
	replace B_se = _se[2.led_grade_`l'] if time == -`span'*`l' - `dif'
	replace B_se = _se[2.lag_grade_`l'] if time ==  `span'*`l' - `dif'
	replace C_se = _se[3.led_grade_`l'] if time == -`span'*`l' 
	replace C_se = _se[3.lag_grade_`l'] if time ==  `span'*`l'  
	replace P_se = _se[4.led_grade_`l'] if time == -`span'*`l' + `dif'
	replace P_se = _se[4.lag_grade_`l'] if time ==  `span'*`l' + `dif'
}

foreach g of varlist B C P {
	gen `g'_H = `g' + 1.96*`g'_se
	gen `g'_L = `g' - 1.96*`g'_se
}

replace time = time/`span'

twoway (scatter B time if time <= 5, color(blue) ) ///
(scatter C time if time <= 6, color(red)) ///
(scatter P time if time <= 6, color(green)) ///
(rcap B_H B_L time if time <= 5, color(blue)) ///
(rcap C_H C_L time if time <= 6, color(red) ) ///
(rcap P_H P_L time if time <= 6, color(green) ), ///
legend(order(1 "B" 2 "C" 3 "P") cols(3)) xlabels(-5(1)5) ///
title("Impact of Letter Grades on Complaint Calls") ///
graphregion(color(white)) ///
ylabel(-0.01(0.005)0.025,gstyle(dot)) xlabel(-6(1)6) ///
xtitle("Months") ytitle("Estimated Coefficients")

/**************** Plots **************************/
/*
coefplot, keep(3.lag_grade_* 3.visible_grade 3.led_grade_*) ///
vertical xlabel(,angle(vertical)) graphregion(color(white)) ///
ylabel(-0.01(0.005)0.02,gstyle(dot)) title("C grade")

coefplot, keep(2.lag_grade_* 2.visible_grade 2.led_grade_*) ///
vertical xlabel(,angle(vertical)) graphregion(color(white)) ///
ylabel(-0.01(0.005)0.02,gstyle(dot)) title("B grade")

coefplot, keep(4.lag_grade_* 4.visible_grade 4.led_grade_*) ///
vertical xlabel(,angle(vertical)) graphregion(color(white)) ///
ylabel(-0.01(0.005)0.02,gstyle(dot)) title("P grade")
*/
reghdfe called (grade_A = LO_SCORE2), ///
a(CAMIS month_year) cluster(CAMIS InspectorID)

reghdfe Counted_Calls grade_A, ///
a(CAMIS month_year) cluster(ZIPCODE InspectorID)

reghdfe Counted_Calls grade_A, ///
a(CAMIS month_year) cluster(ZIPCODE InspectorID)

reghdfe Counted_Calls (grade_A = LO_SCORE2), ///
a(CAMIS month_year) cluster(ZIPCODE InspectorID)

reghdfe Unique_Key num_inspect , ///
a(CAMIS month_year) cluster(CAMIS InspectorID)  */
