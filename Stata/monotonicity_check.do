/************************************
** Checks for Monotonicity Condition
*********************************/

cd "~/Desktop/NYC Food Inspection/Data/DTA"
use inspect_processed.dta, clear

cd "~/Dropbox/Research Ideas/Food Inspection Scores/New York/Tex/Tables/Mono/"

gen relevant = 1
gen LO_Inv_sample = .
label variable LO_Inv_sample "Estimate"
label variable LO_SCORE2 "Estimate"
capture program drop inverse_sample
program define inverse_sample
	replace relevant = 1
	`0'
	capture drop LO_Inv_sample
	egen LO_Inv_sample = mean(SCORE*relevant), ///
	by(InspectorID post inspect_type)
	label variable LO_Inv_sample "Estimate"
	capture drop inspector_inv_sample_cnt
	egen inspector_inv_sample_cnt = sum(relevant), ///
	by(InspectorID post inspect_type)
end

qui: reghdfe SCORE i.inspect_type if post == 1, ///
absorb(i = INSPDATE c = CAMIS) cluster(InspectorID ZIPCODE)

predict score_pred, xbd
qui: sum score_pred, detail

local p25 = r(p25)
local p50 = r(p50)
local p75 = r(p75)

foreach LO_sample of varlist LO_Inv_sample LO_SCORE2 {
	if "`LO_sample'" == "LO_Inv_sample" {
		local f = "inverse" 
		local title = "Inverse-Sample"
		local condition = "inspector_inv_sample_cnt > 50"
	}
	else {
		local f = ""
		local title = "Baseline-Sample"
		local condition = "inspector_cnt > 50"
	}
	inverse_sample replace relevant = . if score_pred <= `p25'
	qui: reghdfe SCORE `LO_sample' ///
	if post == 1 & `condition' & score_pred <= `p25', ///
	absorb(INSPDATE ZIPCODE chain cuisine service venue) ///
	cluster(InspectorID ZIPCODE)
	outreg2 using quartile`f'.tex, replace tex(frag) label ///
	ctitle("1st Quartile") nor2 long title("`title'")

	inverse_sample replace relevant = . if score_pred <= `p50' & score_pred > `p25'
	qui: reghdfe SCORE `LO_sample' ///
	if post == 1 & `condition' & score_pred <= `p50' & score_pred > `p25', ///
	absorb(INSPDATE ZIPCODE chain cuisine service venue) ///
	cluster(InspectorID ZIPCODE)
	outreg2 using quartile`f'.tex, append tex(frag) label ///
	ctitle("2nd") nor2 long
	
	inverse_sample replace relevant = . if score_pred <= `p75' & score_pred > `p50'
	qui: reghdfe SCORE `LO_sample' ///
	if post == 1 & `condition' & score_pred <= `p75' & score_pred > `p50', ///
	absorb(INSPDATE ZIPCODE chain cuisine service venue) ///
	cluster(InspectorID ZIPCODE)
	outreg2 using quartile`f'.tex, append tex(frag) label ///
	ctitle("3nd") nor2 long
	
	inverse_sample replace relevant = . if score_pred > `p75'
	qui: reghdfe SCORE `LO_sample' ///
	if post == 1 & `condition' & score_pred > `p75', ///
	absorb(INSPDATE ZIPCODE chain cuisine service venue) ///
	cluster(InspectorID ZIPCODE)
	outreg2 using quartile`f'.tex, append tex(frag) label ///
	ctitle("4th") nor2 long

	/************ Cuisine Sub-sample *************/
	inverse_sample replace relevant = . if cuisine == 3
	qui: reghdfe SCORE `LO_sample' ///
	if post == 1 & `condition' & cuisine == 3, ///
	absorb(INSPDATE ZIPCODE chain service venue) ///
	cluster(InspectorID ZIPCODE) /* American */
	outreg2 using cuisine_mono`f'.tex, replace tex(frag) label ///
	ctitle("American") nor2 long title("`title'")

	inverse_sample replace relevant = . if cuisine == 62
	qui: reghdfe SCORE `LO_sample' ///
	if post == 1 & `condition' & cuisine == 62, ///
	absorb(INSPDATE ZIPCODE chain service venue) ///
	cluster(InspectorID ZIPCODE) /**Pizza/Italian */
	outreg2 using cuisine_mono`f'.tex, append tex(frag) label ///
	ctitle("Pizza/Italian") nor2 long

	inverse_sample replace relevant = . if cuisine == 20
	qui: reghdfe SCORE `LO_sample' ///
	if post == 1 & `condition' & cuisine == 20, ///
	absorb(INSPDATE ZIPCODE chain service venue) ///
	cluster(InspectorID ZIPCODE) /* American */
	outreg2 using cuisine_mono`f'.tex, append tex(frag) label ///
	ctitle("Chinese") nor2 long

	inverse_sample replace relevant = . if cuisine == 14
	qui: reghdfe SCORE `LO_sample' ///
	if post == 1 & `condition' & cuisine == 14, ///
	absorb(INSPDATE ZIPCODE chain service venue) ///
	cluster(InspectorID ZIPCODE)  /*Japanese*/
	outreg2 using cuisine_mono`f'.tex, append tex(frag) label ///
	ctitle("Cafe/Coffee/Tea") nor2 long

	inverse_sample replace relevant = . if cuisine == 47
	qui: reghdfe SCORE `LO_sample' ///
	if post == 1 & `condition' & cuisine == 47, ///
	absorb(INSPDATE ZIPCODE chain service venue) ///
	cluster(InspectorID ZIPCODE)  /*Japanese*/
	outreg2 using cuisine_mono`f'.tex, append tex(frag) label ///
	ctitle("Japanese") nor2 long

	/**** Boro *********************/
	inverse_sample replace relevant = . if BORO == 1
	qui: reghdfe SCORE `LO_sample' ///
	if post == 1 & `condition' & BORO == 1, ///
	absorb(INSPDATE ZIPCODE chain service venue) ///
	cluster(InspectorID ZIPCODE) 
	outreg2 using boro`f'.tex, replace tex(frag) label ///
	ctitle("Manhattan") nor2 long title("`title'")

	inverse_sample replace relevant = . if BORO == 2
	qui: reghdfe SCORE `LO_sample' ///
	if post == 1 & `condition' & BORO == 2, ///
	absorb(INSPDATE ZIPCODE chain service venue) ///
	cluster(InspectorID ZIPCODE) 
	outreg2 using boro`f'.tex, append tex(frag) label ///
	ctitle("Bronx") nor2 long

	inverse_sample replace relevant = . if BORO == 3
	qui: reghdfe SCORE `LO_sample' ///
	if post == 1 & `condition' & BORO == 3, ///
	absorb(INSPDATE ZIPCODE chain service venue) ///
	cluster(InspectorID ZIPCODE) 
	outreg2 using boro`f'.tex, append tex(frag) label ///
	ctitle("Brooklyn") nor2 long

	inverse_sample replace relevant = . if BORO == 4
	qui: reghdfe SCORE `LO_sample' ///
	if post == 1 & `condition' & BORO == 4, ///
	absorb(INSPDATE ZIPCODE chain service venue) ///
	cluster(InspectorID ZIPCODE) 
	outreg2 using boro`f'.tex, append tex(frag) label ///
	ctitle("Queens") nor2 long

	inverse_sample replace relevant = . if BORO == 5
	qui: reghdfe SCORE `LO_sample' ///
	if post == 1 & `condition' & BORO == 5, ///
	absorb(INSPDATE ZIPCODE chain service venue) ///
	cluster(InspectorID ZIPCODE) 
	outreg2 using boro`f'.tex, append tex(frag) label ///
	ctitle("Staten-Isl") nor2 long
	/************* Service ****************************************************/

	inverse_sample replace relevant = . if counter_serv == 1
	qui: reghdfe SCORE `LO_sample' ///
	if post == 1 & `condition' & counter_serv == 1, ///
	absorb(INSPDATE ZIPCODE chain service venue) ///
	cluster(InspectorID ZIPCODE) 
	outreg2 using service`f'.tex, replace tex(frag) label ///
	ctitle("Counter Service") nor2 long title("`title'")

	inverse_sample replace relevant = . if take_out_serv == 1
	qui: reghdfe SCORE `LO_sample' ///
	if post == 1 & `condition' & take_out_serv == 1, ///
	absorb(INSPDATE ZIPCODE chain service venue) ///
	cluster(InspectorID ZIPCODE) 
	outreg2 using service`f'.tex, append tex(frag) label ///
	ctitle("Takeout Service") nor2 long

	inverse_sample replace relevant = . if wait_serv == 1
	qui: reghdfe SCORE `LO_sample' ///
	if post == 1 & `condition' & wait_serv == 1, ///
	absorb(INSPDATE ZIPCODE chain service venue) ///
	cluster(InspectorID ZIPCODE) 
	outreg2 using service`f'.tex, append tex(frag) label ///
	ctitle("Wait Service") nor2 long
}
