/******************
* This file merges food inspection data with complaint calls
* It then run regressions and saves output .tex files 
*******************************************************/
set more off

cd "~/Desktop/NYC Food Inspection/Data/DTA"

capture use calls_processed.dta
if _rc != 0 {
	/***************************** Data Construction ********************/
	use single_add_camis.dta, clear
	sort CAMIS
	save single_add_camis.dta, replace

	use calls_matched.dta, clear
	sort CAMIS
	save calls_matched.dta, replace
	use code.dta, clear

	sort CAMIS

	merge CAMIS using single_add_camis.dta
	keep if _merge == 3
	drop _merge

	by CAMIS INSPDATE, sort: gen inspect_check = _N
	drop if inspect_check > 1 //exclude inspections that occured on same day at same establishment
	drop inspect_check

	run "~/Desktop/NYC Food Inspection/Script/Stata/pre_process2.do"
	count 
	disp r(N)

	sort CAMIS
	joinby CAMIS using calls_matched.dta, unmatched(master)
	drop if _merge == 2
	save calls_processed.dta, replace
}

label variable time2nextInit "Days Until Next"
gen posted_date = max(CASE_DECISION_DATE,INSPDATE)
/******************** Calculating complaint numbers ****************/
egen complaints = sum(Created_Date != . & INSPDATE <= Created_Date & ///
next_same_type_date >= Created_Date), by(CAMIS INSPDATE)

egen complaints_re = sum(Created_Date != . & INSPDATE <= Created_Date & ///
next >= Created_Date), by(CAMIS INSPDATE)

egen complaints_post = sum(Created_Date != . & /// 
posted_date <= Created_Date & next >= Created_Date), by(CAMIS INSPDATE)

by inspectionID, sort: gen inspection_id = _n == 1
keep if inspection_id == 1
drop Created_Date Unique_Key

sort CAMIS INSPDATE, stable
by CAMIS: gen last_complaints = complaints[_n - 1]
by CAMIS: gen last_complaints_re = complaints_re[_n - 1]

/************** Regressions ****************************************/
cd "~/Desktop/NYC Food Inspection/Data/RegOutput/Complaints"

//Generated and label necessary variables


reghdfe complaints SCORE time2nextInit ///
if inspect_type == 1 & post == 1 & complaints_re < 4, ///
a(CAMIS INSPDATE) cluster(InspectorID ZIPCODE)
outreg2 using complaints.tex, replace tex(frag) label nor2 ///
ctitle("Initial Inspections")

gen time2nextInit_temp = time2nextInit
replace time2nextInit = time2next

reghdfe complaints_re  SCORE last_score time2nextInit ///
if inspect_type == 2 & next_type == 1 & post == 1 & complaints_re <= 4 & ///
last_type == 1 & inspector_cnt > 50, ///
a(CAMIS INSPDATE) cluster(InspectorID ZIPCODE)
outreg2 using complaints.tex, append tex(frag) label nor2 ///
ctitle("Re-inspections (OLS)")

replace time2nextInit = next - max(CASE_DECISION_DATE,INSPDATE)

reghdfe complaints_post MOD_TOTALSCORE time2nextInit ///
if inspect_type == 2 & next_type == 1 & post == 1 & complaints_re <= 4 & ///
last_type == 1 & inspector_cnt > 50, ///
a(CAMIS INSPDATE) cluster(InspectorID ZIPCODE)
outreg2 using complaints.tex, append tex(frag) label nor2 ///
ctitle("Re-inspections (OLS)")

reghdfe complaints_re time2nextInit (SCORE = LO_SCORE2) ///
if inspect_type == 2 & next_type == 1 & post == 1 & complaints_re <= 4 & ///
last_type == 1 & inspector_cnt > 50, ///
a(CAMIS INSPDATE) cluster(InspectorID ZIPCODE)
outreg2 using complaints.tex, append tex(frag) label nor2 ///
ctitle("Re-inspections (IV)")

replace time2nextInit = time2nextInit_temp

gen time2adjud = max(CASE_DECISION_DATE - INSPDATE, 0)
reghdfe complaints_re time2next (SCORE = LO_SCORE2) ///
if inspect_type == 2 & next_type == 1 & post == 1 & complaints_re <= 4 & ///
SCORE <= 13, ///
a(CAMIS INSPDATE) cluster(InspectorID ZIPCODE)

gen not_A = MOD_TOTALSCORE > 13

reghdfe complaints_re not_A time2next   ///
if inspect_type == 1 & post == 1 & complaints_re <= 4, ///
a(CAMIS INSPDATE) cluster(InspectorID ZIPCODE)
outreg2 using A_complaints.tex, replace tex(frag) label nor2 ///
ctitle("Initial Inspections")

replace time2nextInit = time2next

reghdfe complaints_post not_A time2nextInit   ///
if inspect_type == 2 & next_type == 1 & post == 1 & complaints_re <= 4 & ///
inspector_cnt > 50, ///
a(CAMIS INSPDATE) cluster(InspectorID ZIPCODE)
outreg2 using A_complaints.tex, append tex(frag) label nor2 ///
ctitle("Re-inspections (OLS)")

replace time2nextInit = next - posted_date

reghdfe not_A LO_SCORE2 time2next time2adjud ///
if inspect_type == 2 & next_type == 1 & post == 1 & complaints_re <= 4 & ///
inspector_cnt > 50, ///
a(c = CAMIS i = INSPDATE) cluster(InspectorID ZIPCODE)

predict not_A_res, resid

reghdfe dep not_A time2next time2adjud ///
if inspect_type == 2 & next_type == 1 & post == 1 & complaints_re <= 4 & ///
inspector_cnt > 50 [aweight = post2next], ///
a(CAMIS INSPDATE) cluster(InspectorID ZIPCODE)

reghdfe dep time2next time2adjud (not_A = LO_SCORE2) ///
if inspect_type == 2 & next_type == 1 & post == 1 & complaints_re <= 4 & ///
inspector_cnt > 50 [aweight = post2next], ///
a(CAMIS INSPDATE) cluster(InspectorID ZIPCODE)
outreg2 using A_complaints.tex, append tex(frag) label nor2 ///
ctitle("Re-inspections (IV)")

cd "~/Desktop/NYC Food Inspection/Figures"

gen post2next = next - post_date
capture drop _s_*
foreach s of numlist 1/40 {
	gen _s_`s' = MOD_TOTALSCORE == `s'
	label variable _s_`s' "`s'"
}

gen dep = complaints_post/post2next
reghdfe dep time2next _s_*  ///
if inspect_type == 2 & next_type == 1 & post == 1 & complaints_re <= 4 & ///
MOD_TOTALSCORE <= 40 & MOD_TOTALSCORE >= 0 [w = post2next], ///
a(CAMIS INSPDATE post_date) 

reghdfe post2next _s_*  ///
if inspect_type == 2 & next_type == 1 & post == 1 & complaints_re <= 4 & ///
MOD_TOTALSCORE <= 40 & MOD_TOTALSCORE >= 0 & CASE_DECISION_DATE > INSPDATE, ///
a(CAMIS INSPDATE post_date) 

coefplot, vertical xlabel(,angle(65)) ///
keep(_s_*) noci xline(12.5) xline(26.5) xtitle("Modified Score") ///
title("Average Number of Complaints by Modified Scores") ///
graphregion(color(white)) saving(mod.gph, replace)

graph export mod_complaint.png, replace
foreach s of numlist 1/40 {
	replace _s_`s' = SCORE == `s'
}
reghdfe complaints_re time2next _s_* ///
if inspect_type == 2 & next_type == 1 & post == 1 & complaints_re <= 4 & ///
SCORE <= 40 & SCORE >= 0, ///
a(CAMIS INSPDATE) cluster(InspectorID ZIPCODE)

coefplot, vertical xlabel(,angle(65)) ///
keep(_s_*) noci xline(12.5) xline(26.5) xtitle("Score") ///
title("Average Number of Complaints by Scores") graphregion(color(white)) ///
saving(score.gph, replace)
graph export score_complaint.png, replace

graph combine mod.gph score.gph, col(1) graphregion(color(white)) 
graph export non_param.png, replace
//keep if inspection_id == 1

//drop if (INSPDATE > Created_Date | next < Created_Date) & Created_Date != .




