set more off

cd "~/Desktop/NYC Food Inspection/Data/DTA"
//use nyc_inspect_shift.dta, clear
use code.dta, clear
cd "~/Desktop/NYC Food Inspection/Script/Stata"
run pre_process2.do

cd "~/Desktop/NYC Food Inspection/Data/RegOutput"
/********** 1st Stage **************/
label variable LO_SCORE "Z"
label variable LO_SCORE2 "Z"
qui: reghdfe SCORE LO_SCORE2 if post == 1, ///
absorb(INSPDATE) cluster(InspectorID ZIPCODE)

outreg2 using FirstStage.tex, replace tex(frag) label ///
addtext(Restaurant Controls, NO, Next Time FE, NO) addstat("F Statistics", e(F))

qui: reghdfe SCORE LO_SCORE2 if post == 1, ///
absorb(INSPDATE ZIPCODE chain cuisine service venue) cluster(InspectorID ZIPCODE)

outreg2 using FirstStage.tex, append tex(frag) label ///
addtext(Restaurant Controls, YES, Next Time FE, NO) addstat("F Statistics", e(F))


qui: reghdfe SCORE LO_SCORE if post == 1, ///
absorb(INSPDATE CAMIS) cluster(InspectorID ZIPCODE)

outreg2 using FirstStage.tex, append tex(frag) label ///
addtext(Restaurant FE, YES, Next Time FE, NO) addstat("F Statistics", e(F))

reghdfe MOD_TOTALSCORE LO_SCORE if post == 1 & grade > 1, ///
absorb(INSPDATE ZIPCODE chain cuisine service venue) ///
cluster(InspectorID ZIPCODE)

outreg2 using FirstStage.tex, append tex(frag) label ///
addtext(Restaurant FE, YES, Next Time FE, NO) addstat("F Statistics", e(F))

reghdfe open SCORE  ///
if post == 1 & inspect_type  == 1, ///
absorb(INSPDATE CAMIS) cluster(InspectorID ZIPCODE) 

/************ next inspect scores **********************/

local vars Facility_Maintenance Food_Protection Personal_Hygiene ///
Food_Temperature Vermin_Garbage General_Food_Source Facility_Design ///
Critical_Food_Source  

local inst LO_Facility_Maintenance LO_Food_Protection LO_Personal_Hygiene ///
LO_Food_Temperature LO_Vermin_Garbage LO_General_Food_Source LO_Facility_Design ///
LO_Critical_Food_Source 

/*
foreach v of varlist `vars' {
	local lab: variable label `v'
	if "`v'" == "Facility_Maintenance" {
		disp "`v'"
		local change "replace"
	} 
	else {
		local change "append"
	}
	/*
	reghdfe n_`v' `vars'             ///
	if post == 1 & inspect_type  == 1 & inspector_cnt > 50,                      ///
	a(INSPDATE next_same_type_date) cluster(InspectorID ZIPCODE)
	outreg2 using tasks_OLS.tex, `change' tex(frag) label nor2 ctitle("`lab'") */     ///

	reghdfe n_`v' (`vars' = `inst')              ///
	if post == 1 & inspect_type  == 1 & inspector_cnt > 50,                      ///
	a(INSPDATE next_same_type_date ZIPCODE chain cuisine service venue) ///
	cluster(InspectorID ZIPCODE)
	outreg2 using tasks_IV.tex, `change' tex(frag) label ctitle("`lab'") nor2    
}
*/
foreach v of varlist SCORE MOD_TOTALSCORE {

	qui: reghdfe n_same_type_score `v'                                         ///
	if post == 1 & inspect_type  == 1 & inspector_cnt > 50,                      ///
	a(INSPDATE next_same_type_date) cluster(InspectorID ZIPCODE)
	outreg2 using `v'_next.tex, replace tex(frag) label ctitle("OLS") nor2        ///
	addtext(Restaurant Controls, No, Restaurant FE, No)

	qui: reghdfe n_same_type_score `v'                                        ///
	if post == 1 & inspect_type  == 1 & inspector_cnt > 50,                      ///
	a(INSPDATE next_same_type_date ZIPCODE chain cuisine service venue) cluster(InspectorID ZIPCODE)
	outreg2 using `v'_next.tex, append tex(frag) label ctitle("OLS") nor2        ///
	addtext(Restaurant Controls, Yes, Restaurant FE, No)
	/*
	qui: reghdfe n_same_type_score `v'                                            ///
	if post == 1 & inspect_type  == 1 & inspector_cnt > 50,                          ///
	a(INSPDATE next_same_type_date CAMIS) cluster(InspectorID ZIPCODE)
	outreg2 using `v'_next.tex, append tex(frag) label ctitle("OLS") nor2        ///
	addtext(Restaurant Controls, No, Restaurant FE, Yes) */

	qui: reghdfe n_same_type_score (`v' = LO_SCORE2)                                ///
	if post == 1 & inspect_type  == 1 & inspector_cnt > 50,                      ///
	a(INSPDATE next_same_type_date) cluster(InspectorID ZIPCODE)
	outreg2 using `v'_next.tex, append tex(frag) label ctitle("IV") nor2        ///
	addtext(Restaurant Controls, No, Restaurant FE, No)

	qui: reghdfe n_same_type_score (`v' = LO_SCORE2)                           ///
	if post == 1 & inspect_type  == 1 & inspector_cnt > 50,                      ///
	a(INSPDATE next_same_type_date ZIPCODE chain cuisine service venue) ///
	cluster(InspectorID ZIPCODE)
	outreg2 using `v'_next.tex, append tex(frag) label ctitle("IV") nor2        ///
	addtext(Restaurant Controls, Yes, Restaurant FE, No)
	/*
	qui: reghdfe n_same_type_score (`v' = LO_SCORE2)                                           ///
	if post == 1 & inspect_type  == 1 & inspector_cnt > 50,                          ///
	a(INSPDATE next_same_type_date CAMIS) cluster(InspectorID ZIPCODE)
	outreg2 using `v'_next.tex, append tex(frag) label ctitle("IV") nor2        ///
	addtext(Restaurant Controls, No, Restaurant FE, Yes) */

	/*********** NextL ************************/

	qui: reghdfe n_same_type_score `v'                                                ///
	if post == 1 & inspect_type  == 1 & SCORE <= 13 & inspector_cnt > 50,                          ///
	a(INSPDATE next_same_type_date) cluster(InspectorID ZIPCODE)
	outreg2 using `v'_nextL.tex, replace tex(frag) label ctitle("OLS") nor2        ///
	addtext(Restaurant Controls, No, Restaurant FE, No)

	qui: reghdfe n_same_type_score `v'                                                ///
	if post == 1 & inspect_type  == 1 & SCORE <= 13 & inspector_cnt > 50,                          ///
	a(INSPDATE next_same_type_date ZIPCODE chain cuisine service venue) ///
	cluster(InspectorID ZIPCODE)
	outreg2 using `v'_nextL.tex, append tex(frag) label ctitle("OLS") nor2          ///
	addtext(Restaurant Controls, Yes, Restaurant FE, No)
	/*
	qui: reghdfe n_same_type_score `v'                                            ///
	if post == 1 & inspect_type  == 1 & SCORE <= 13 & inspector_cnt > 50,                      ///
	a(INSPDATE CAMIS next_same_type_date) cluster(InspectorID ZIPCODE)
	outreg2 using `v'_nextL.tex, append tex(frag) label ctitle("OLS") nor2         ///
	addtext(Restaurant Controls, No, Restaurant FE, Yes) */

	qui: reghdfe n_same_type_score (`v' = LO_SCORE2) ///
	if post == 1 & inspect_type  == 1 & SCORE <= 13 & inspector_cnt > 50, ///
	a(INSPDATE next_same_type_date) cluster(InspectorID ZIPCODE )
	outreg2 using `v'_nextL.tex, append tex(frag) label ctitle("IV") nor2 ///
	addtext(Restaurant Controls, No, Restaurant FE, No)

	qui: reghdfe n_same_type_score (`v' = LO_SCORE2) ///
	if post == 1 & inspect_type  == 1 & SCORE <= 13 & inspector_cnt > 50, ///
	a(INSPDATE next_same_type_date ZIPCODE chain cuisine service venue) cluster(InspectorID ZIPCODE)
	outreg2 using `v'_nextL.tex, append tex(frag) label ctitle("IV") nor2 ///
	addtext(Restaurant Controls, Yes, Restaurant FE, No)
	/*
	qui: reghdfe n_same_type_score (`v' = LO_SCORE2) ///
	if post == 1 & inspect_type  == 1 & SCORE <= 13 & inspector_cnt > 50, ///
	a(INSPDATE CAMIS next_same_type_date) cluster(InspectorID ZIPCODE )
	outreg2 using `v'_nextL.tex, append tex(frag) label ctitle("IV") nor2 ///
	addtext(Restaurant Controls, No, Restaurant FE, Yes) */

	/***************** NextH ********************************************/
	qui: reghdfe n_same_type_score `v' next_score                                         ///
	if post == 1 & inspect_type  == 1 & SCORE > 13 & inspector_cnt > 50 & next_type == 2,                          ///
	a(INSPDATE next_same_type_date) cluster(InspectorID ZIPCODE)
	outreg2 using `v'_nextH.tex, replace tex(frag) label ctitle("OLS") nor2        ///
	addtext(Restaurant Controls, No, Restaurant FE, No)

	qui: reghdfe n_same_type_score `v' next_score                                        ///
	if post == 1 & inspect_type  == 1 & SCORE > 13 & inspector_cnt > 50 & next_type == 2,                          ///
	a(INSPDATE next_same_type_date ZIPCODE chain cuisine service venue) cluster(InspectorID ZIPCODE)
	outreg2 using `v'_nextH.tex, append tex(frag) label ctitle("OLS") nor2        ///
	addtext(Restaurant Controls, Yes, Restaurant FE, No)
	/*
	qui: reghdfe n_same_type_score `v'                                            ///
	if post == 1 & inspect_type  == 1 & SCORE > 13 & inspector_cnt > 50,                          ///
	a(INSPDATE next_same_type_date CAMIS) cluster(InspectorID ZIPCODE)
	outreg2 using `v'_nextH.tex, append tex(frag) label ctitle("OLS") nor2        ///
	addtext(Restaurant Controls, No, Restaurant FE, Yes)  */

	qui: reghdfe n_same_type_score (`v' next_score = LO_SCORE2 next_LO2)                                           ///
	if post == 1 & inspect_type  == 1 & SCORE > 13 & inspector_cnt > 50 & next_type == 2,                          ///
	a(INSPDATE next_same_type_date) cluster(InspectorID ZIPCODE)
	outreg2 using `v'_nextH.tex, append tex(frag) label ctitle("IV") nor2        ///
	addtext(Restaurant Controls, No, Restaurant FE, No)

	qui: reghdfe n_same_type_score (`v' next_score = LO_SCORE2 next_LO2)                                           ///
	if post == 1 & inspect_type  == 1 & SCORE > 13 & inspector_cnt > 50 & next_type == 2,                        ///
	a(INSPDATE next_same_type_date ZIPCODE chain cuisine service venue) cluster(InspectorID ZIPCODE)
	outreg2 using `v'_nextH.tex, append tex(frag) label ctitle("IV") nor2        ///
	addtext(Restaurant Controls, Yes, Restaurant FE, No)
	/*
	qui: reghdfe n_same_type_score (`v' = LO_SCORE2)                                           ///
	if post == 1 & inspect_type  == 1 & SCORE > 13 & inspector_cnt > 50,                         ///
	a(INSPDATE next_same_type_date CAMIS) cluster(InspectorID ZIPCODE)
	outreg2 using `v'_nextH.tex, append tex(frag) label ctitle("IV") nor2        ///
	addtext(Restaurant Controls, No, Restaurant FE, Yes)  */
}

                                       
reghdfe n_same_type_score (SCORE = LO_*)                                    ///
if post == 1 & inspect_type  == 1 & SCORE < 13 & inspector_cnt > 50,                          ///
a(INSPDATE next_same_type_date) cluster(InspectorID ZIPCODE)

/*
/***********I2I************************/

qui: reghdfe next_score SCORE                                                ///
if post == 1 & inspect_type  == 1 & next_type == 1 & inspector_cnt > 50,                          ///
a(INSPDATE next) cluster(InspectorID ZIPCODE )
outreg2 using I2I.tex, replace tex(frag) label ctitle("I2I OLS") nor2        ///
addtext(Restaurant Controls, No, Restaurant FE, No)

qui: reghdfe next_score SCORE                                                ///
if post == 1 & inspect_type  == 1 & next_type == 1 & inspector_cnt > 50,                          ///
a(INSPDATE next ZIPCODE chain cuisine service venue) cluster(InspectorID ZIPCODE)
outreg2 using I2I.tex, append tex(frag) label ctitle("I2I OLS") nor2          ///
addtext(Restaurant Controls, Yes, Restaurant FE, No)

qui: reghdfe next_score SCORE                                             ///
if post == 1 & inspect_type  == 1 & next_type == 1 & inspector_cnt > 50,                      ///
a(INSPDATE CAMIS next) cluster(InspectorID ZIPCODE )
outreg2 using I2I.tex, append tex(frag) label ctitle("I2I OLS") nor2         ///
addtext(Restaurant Controls, No, Restaurant FE, Yes)

qui: reghdfe next_score (SCORE = LO_SCORE2 ) ///
if post == 1 & inspect_type  == 1 & next_type == 1 & inspector_cnt > 50, ///
a(INSPDATE next) cluster(InspectorID ZIPCODE )
outreg2 using I2I.tex, append tex(frag) label ctitle("I2I IV") nor2 ///
addtext(Restaurant Controls, No, Restaurant FE, No)

qui: reghdfe next_score (SCORE = LO_SCORE2 ) ///
if post == 1 & inspect_type  == 1 & next_type == 1 & inspector_cnt > 50, ///
a(INSPDATE next ZIPCODE chain cuisine service venue) cluster(InspectorID ZIPCODE)
outreg2 using I2I.tex, append tex(frag) label ctitle("I2I IV") nor2 ///
addtext(Restaurant Controls, Yes, Restaurant FE, No)

qui: reghdfe next_score (SCORE = LO_SCORE2 ) ///
if post == 1 & inspect_type  == 1 & next_type == 1 & inspector_cnt > 50, ///
a(INSPDATE CAMIS next) cluster(InspectorID ZIPCODE )
outreg2 using I2I.tex, append tex(frag) label ctitle("I2I IV") nor2 ///
addtext(Restaurant Controls, No, Restaurant FE, Yes)
*/

/*
/************* I2R ******************/
qui: reghdfe next_score SCORE ///
if post == 1 & inspect_type == 1 & next_type == 2 & inspector_cnt > 50, ///
a(INSPDATE next) cluster(InspectorID ZIPCODE) 
outreg2 using I2R.tex, replace tex(frag) label ctitle("I2R OLS") nor2 ///
addtext(Restaurant Controls, No, Restaurant FE, No)

qui: reghdfe next_score SCORE  ///
if post == 1 & inspect_type == 1 & next_type == 2 & inspector_cnt > 50, ///
a(INSPDATE next ZIPCODE chain cuisine service venue) cluster(InspectorID ZIPCODE) 
outreg2 using I2R.tex, append tex(frag) label ctitle("I2R OLS") nor2 ///
addtext(Restaurant Controls, Yes, Restaurant FE, No)

qui: reghdfe next_score SCORE  ///
if post == 1 & inspect_type == 1 & next_type == 2 & inspector_cnt > 50, ///
a(INSPDATE CAMIS next) cluster(InspectorID ZIPCODE) 
outreg2 using I2R.tex, append tex(frag) label ctitle("I2R OLS") nor2 ///
addtext(Restaurant Controls, No, Restaurant FE, Yes)

qui: reghdfe next_score (SCORE = LO_SCORE) ///
if post == 1 & inspect_type == 1 & next_type == 2 & inspector_cnt > 50, ///
a(INSPDATE next) cluster(InspectorID ZIPCODE) 
outreg2 using I2R.tex, append tex(frag) label ctitle("I2R IV") nor2 ///
addtext(Restaurant Controls, No, Restaurant FE, No)

qui: reghdfe next_score (SCORE = LO_SCORE2 ) ///
if post == 1 & inspect_type == 1 & next_type == 2 & inspector_cnt > 50, ///
a(INSPDATE next ZIPCODE chain cuisine service venue) cluster(InspectorID ZIPCODE) 
outreg2 using I2R.tex, append tex(frag) label ctitle("I2R IV") nor2 ///
addtext(Restaurant Controls, Yes, Restaurant FE, No)

qui: reghdfe next_score (SCORE = LO_SCORE2 ) ///
if post == 1 & inspect_type == 1 & next_type == 2 & inspector_cnt > 50, ///
a(INSPDATE CAMIS next) cluster(InspectorID ZIPCODE) 
outreg2 using I2R.tex, append tex(frag) label ctitle("I2R IV") nor2 ///
addtext(Restaurant Controls, No, Restaurant FE, Yes)

/*********** R2I *****************/
qui: reghdfe next_score SCORE  ///
if post == 1 & inspect_type == 2 & next_type == 1 & inspector_cnt > 50, ///
a(INSPDATE next) cluster(InspectorID ZIPCODE ) 
outreg2 using R2I.tex, replace tex(frag) label ctitle("R2I OLS") nor2 ///
addtext(Restaurant Controls, No, Restaurant FE, No)

reghdfe next_score SCORE  ///
if post == 1 & inspect_type == 2 & next_type == 1 & inspector_cnt > 50, ///
a(INSPDATE next ZIPCODE chain cuisine service venue) cluster(InspectorID ZIPCODE) 
outreg2 using R2I.tex, append tex(frag) label ctitle("R2I OLS") nor2 ///
addtext(Restaurant Controls, Yes, Restaurant FE, NO)

qui: reghdfe next_score SCORE  ///
if post == 1 & inspect_type == 2 & next_type == 1 & inspector_cnt > 50, ///
a(INSPDATE CAMIS next) cluster(InspectorID ZIPCODE ) 
outreg2 using R2I.tex, append tex(frag) label ctitle("R2I OLS") nor2 ///
addtext(Restaurant Controls, No, Restaurant FE, Yes)

qui: reghdfe next_score (SCORE = LO_SCORE2) ///
if post == 1 & inspect_type == 2 & next_type == 1 & inspector_cnt > 50, ///
absorb(INSPDATE next) cluster(InspectorID ZIPCODE ) 
outreg2 using R2I.tex, append tex(frag) label ctitle("R2I IV") nor2 ///
addtext(Restaurant Controls, No, Restaurant FE, No)

reghdfe next_score (SCORE = LO_SCORE2) ///
if post == 1 & inspect_type == 2 & next_type == 1 & inspector_cnt > 50, ///
a(INSPDATE next ZIPCODE chain cuisine service venue) cluster(InspectorID ZIPCODE) 
outreg2 using R2I.tex, append tex(frag) label ctitle("R2I IV") nor2 ///
addtext(Restaurant Controls, Yes, Restaurant FE, No)

qui: reghdfe next_score (SCORE = LO_SCORE2) ///
if post == 1 & inspect_type == 2 & next_type == 1 & inspector_cnt > 50, ///
a(INSPDATE CAMIS next) cluster(InspectorID ZIPCODE) 
outreg2 using R2I.tex, append tex(frag) label ctitle("R2I IV") nor2 ///
addtext(Restaurant Controls, No, Restaurant FE, Yes)
*/

/************** Complaint analysis *******************/
/*
cd "~/Desktop/NYC Food Inspection/Data/DTA"

sort CAMIS

merge CAMIS using single_add_camis.dta
keep if _merge == 3
drop _merge

sort CAMIS
merge CAMIS using calls_matched.dta
drop if _merge == 2

by CAMIS INSPDATE, sort: gen inspect_id = _n == 1

egen complaints = sum(Created_Date != . & INSPDATE <= Created_Date & ///
INSPDATE + 365 >= Created_Date & inspect_id == 1), by(CAMIS INSPDATE)

gen complaint_bin = min(1,complaint)

reghdfe complaint_bin SCORE  ///
if post == 1 & inspect_type  == 1 & inspect_id == 1, ///
absorb(INSPDATE ZIPCODE cuisine service venue ) cluster(InspectorID ZIPCODE) 

reghdfe complaint_bin (SCORE = LO_SCORE) ///
if post == 1 & inspect_type  == 1 & inspect_id == 1, ///
absorb(INSPDATE ZIPCODE cuisine service venue) cluster(InspectorID ZIPCODE) 

reghdfe open i.grade  ///
if post == 1 & inspect_type  == 2 & inspect_id == 1, ///
absorb(INSPDATE CAMIS) cluster(InspectorID ZIPCODE) 

reghdfe open (SCORE = LO_SCORE) ///
if post == 1 & inspect_type  == 1 & inspect_id == 1, ///
absorb(INSPDATE ZIPCODE cuisine service venue) cluster(InspectorID ZIPCODE) 
*/

/*** Judge Success ***/
/*
gen SCORE_2 = SCORE * SCORE
gen SCORE_LO_SCORE = SCORE * LO_SCORE
gen post_LO_SCORE = post * LO_SCORE
gen post_SCORE = post * SCORE
reghdfe open (SCORE_scale = LO_SCORE_scale)  ///
if inspect_type == 2 & year < 2015 & post == 1,  ///
ab(INSPDATE CAMIS) cluster(InspectorID ZIPCODE ) 
outreg2 using R2I.tex, append tex(frag) label ctitle("R2I IV") ///
addtext(Restaurant FE, NO)
*/
