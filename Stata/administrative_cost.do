/***************** Calculate Administrative Costs *****************/

set more off

cd "~/Desktop/NYC Food Inspection/Data/DTA"

//use nyc_inspect_shift.dta, clear
use code.dta, clear

cd "~/Desktop/NYC Food Inspection/Script/Stata"

run pre_process.do

gen adjusted_down = MOD_TOTALSCORE < SCORE
gen adjustment_down = MOD_TOTALSCORE - SCORE
gen adjudicated = CASE_DECISION_DATE > INSPDATE

lpoly adjusted_down SCORE if inspect_type  == 2 &  ///
post == 1 & adjudicated == 1 , noscatter ci bw(2) level(99) 

cd "~/Desktop/NYC Food Inspection/Figures"

reghdfe adjudicated i.SCORE ///
if inspect_type == 2 & post == 1 & SCORE <= 40 & year >= 2011 & SCORE > 10, ///
absorb(INSPDATE) cluster(InspectorID)

coefplot, vertical xlabel(, angle(vertical)) xline(16.5) ///
title("Probability of Pursuing Adjudication Across Scores") ///
ytitle("Probability") noci

cd "~/Desktop/NYC Food Inspection/Data/RegOutput/Adjudication"

reghdfe adjudicated SCORE  ///
if inspect_type == 2 & post == 1 & inspector_cnt > 50 & grade > 1, ///
absorb(INSPDATE) cluster(InspectorID ZIPCODE)
outreg2 using adjudication.tex, replace tex(frag) label nor2 ctitle("OLS") ///
addtext(Restaurant Control, No, Restaurant FE, No)

reghdfe adjudicated SCORE  ///
if inspect_type == 2 & post == 1 & inspector_cnt > 50 & grade > 1, ///
absorb(INSPDATE ZIPCODE cuisine venue service chain) ///
cluster(InspectorID ZIPCODE)
outreg2 using adjudication.tex, append tex(frag) label nor2 ctitle("OLS") ///
addtext(Restaurant Control, Yes, Restaurant FE, No)

reghdfe MOD_TOTALSCORE SCORE  ///
if inspect_type == 2 & post == 1 & inspector_cnt > 50 & grade > 1, ///
absorb(INSPDATE CAMIS) cluster(InspectorID ZIPCODE)

reghdfe adjudicated SCORE  ///
if inspect_type == 2 & post == 1 & inspector_cnt > 50 & grade > 1, ///
absorb(INSPDATE CAMIS) cluster(InspectorID ZIPCODE)
outreg2 using adjudication.tex, append tex(frag) label nor2 ctitle("OLS") ///
addtext(Restaurant Control, No, Restaurant FE, Yes)

reghdfe adjudicated (SCORE = LO_SCORE LO_SCORE2) ///
if inspect_type == 2 & post == 1 & inspector_cnt > 50 & grade > 1, ///
absorb(INSPDATE) cluster(InspectorID ZIPCODE)
outreg2 using adjudication.tex, append tex(frag) label nor2 ctitle("IV") ///
addtext(Restaurant Control, No, Restaurant FE, No)

reghdfe adjudicated (SCORE = LO_SCORE LO_SCORE2) ///
if inspect_type == 2 & post == 1 & inspector_cnt > 50 & grade > 1, ///
absorb(INSPDATE ZIPCODE cuisine venue service) cluster(InspectorID ZIPCODE)
outreg2 using adjudication.tex, append tex(frag) label nor2 ctitle("IV") ///
addtext(Restaurant Control, Yes, Restaurant FE, No)

reghdfe adjudicated (SCORE = LO_SCORE LO_SCORE2) ///
if inspect_type == 2 & post == 1 & inspector_cnt > 50 & grade > 1, ///
absorb(INSPDATE CAMIS) cluster(InspectorID ZIPCODE)
outreg2 using adjudication.tex, append tex(frag) label nor2 ctitle("IV") ///
addtext(Restaurant Control, No, Restaurant FE, Yes)


reghdfe adjustment_down SCORE  ///
if inspect_type == 2 & post == 1 & inspector_cnt > 50 & adjudicated == 1, ///
absorb(INSPDATE) cluster(InspectorID ZIPCODE)
outreg2 using adjustment.tex, replace tex(frag) label nor2 ctitle("OLS") ///
addtext(Restaurant Control, No, Restaurant FE, No)

reghdfe adjustment_down SCORE  ///
if inspect_type == 2 & post == 1 & inspector_cnt > 50 & adjudicated == 1, ///
absorb(INSPDATE ZIPCODE cuisine venue service) cluster(InspectorID ZIPCODE)
outreg2 using adjustment.tex, append tex(frag) label nor2 ctitle("OLS") ///
addtext(Restaurant Control, Yes, Restaurant FE, No)

reghdfe adjustment_down SCORE  ///
if inspect_type == 2 & post == 1 & inspector_cnt > 50 & adjudicated == 1, ///
absorb(INSPDATE CAMIS) cluster(InspectorID ZIPCODE)
outreg2 using adjustment.tex, append tex(frag) label nor2 ctitle("OLS") ///
addtext(Restaurant Control, No, Restaurant FE, Yes)

reghdfe adjustment_down (SCORE = LO_SCORE LO_SCORE2) ///
if inspect_type == 2 & post == 1 & inspector_cnt > 50 & adjudicated == 1, ///
absorb(INSPDATE) ///
cluster(InspectorID ZIPCODE)
outreg2 using adjustment.tex, append tex(frag) label nor2 ctitle("IV") ///
addtext(Restaurant Control, No, Restaurant FE, No)

reghdfe adjustment_down (SCORE = LO_SCORE LO_SCORE2) ///
if inspect_type == 2 & post == 1 & inspector_cnt > 50 & adjudicated == 1, ///
absorb(INSPDATE ZIPCODE cuisine venue service chain_restaurant) ///
cluster(InspectorID ZIPCODE)
outreg2 using adjustment.tex, append tex(frag) label nor2 ctitle("IV") ///
addtext(Restaurant Control, Yes, Restaurant FE, No)

reghdfe adjustment_down (SCORE = LO_SCORE LO_SCORE2) ///
if inspect_type == 2 & post == 1 & inspector_cnt > 50 & adjudicated == 1, ///
absorb(INSPDATE CAMIS) cluster(InspectorID ZIPCODE)
outreg2 using adjustment.tex, append tex(frag) label nor2 ctitle("IV") ///
addtext(Restaurant Control, No, Restaurant FE, Yes)



sort CAMIS INSPDATE
by CAMIS, sort: gen adjusted_down_lag1 = adjusted_down[_n-1]
by CAMIS, sort: gen adjusted_down_lag2 = adjusted_down[_n-2]
