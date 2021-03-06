/*******
This file generates and encodes variables that multiple scripts use
********************/


/******* Generate Needed New Variables ****************************************/
gen post = INSPDATE > mdy(10,1,2010)

gen score_dif = SCORE - last_score
gen inspect_month = mdy(month(INSPDATE), 1, year(INSPDATE))

gen grade = "A"     if SCORE <= 13
replace grade = "B" if SCORE > 13 & SCORE <= 27
replace grade = "C" if SCORE > 27 
encode grade, gen(grade_enc)
drop grade
rename grade_enc grade

encode INSPTYPE , gen(inspect_type)
encode last_type, gen(last_type_enc)
drop last_type
rename last_type_enc last_type
encode next_type, gen(next_type_enc)
drop next_type
rename next_type_enc next_type

gen mod_grade = "A"     if MOD_TOTALSCORE <= 13
replace mod_grade = "B" if MOD_TOTALSCORE > 13 & MOD_TOTALSCORE <= 27
replace mod_grade = "C" if MOD_TOTALSCORE > 27 
encode mod_grade, gen(mod_grade_enc)
drop mod_grade
rename mod_grade_enc mod_grade
replace mod_grade = 1 if inspect_type == 1

gen age = INSPDATE - first 

encode ACTION, gen(ACTION_enc)
drop ACTION 
rename ACTION_enc ACTION

gen next_grade = "A" if next_score < 14
replace next_grade = "B" if next_score >= 14 & next_score <= 27
replace next_grade = "C" if next_score > 27

encode next_grade, gen(next_grade_enc)
drop next_grade
rename next_grade_enc next_grade

encode venue, gen(venue_enc)
drop venue
rename venue_enc venue

encode ServiceDescription, gen(service)
drop ServiceDescription

encode(cuisine), gen(cuisine_enc)
drop cuisine
rename cuisine_enc cuisine

/********************* Re-classify Cuisine Venue and Service Variables ********/
gen cuisine_reg = cuisine

replace cuisine = 58 if cuisine == 1 | cuisine == 2 | cuisine == 4 ///
| cuisine == 6 | cuisine == 9 | cuisine == 10 | cuisine == 11 | cuisine == 12 ///
| cuisine == 13 | cuisine == 16 | cuisine == 19 ///
| cuisine == 21 | cuisine ==  22 | cuisine ==  23 ///
| cuisine == 24 | cuisine == 25 | cuisine ==  26 | cuisine == 30 ///
| cuisine == 31 | cuisine == 32 | cuisine == 33 | cuisine == 39 ///
| cuisine == 44 ///
| cuisine == 45 ///
| cuisine == 56 ///
| cuisine == 57 | cuisine == 64 | cuisine == 70 | cuisine == 73 ///
| cuisine == 77

replace cuisine = 40 if cuisine == 41

replace cuisine = 8 if cuisine == 7
//gen american_cuis = cuisine == 3
gen sea_food_cuis = cuisine == 71
gen chinese_cuis = cuisine == 20
gen pizza_italian_cuis = cuisine == 62
gen coffee_tea_cuis = cuisine == 14
gen latin_cuis = cuisine == 51 
gen spanish_cuis = cuisine == 76
gen carribean_cuis = cuisine == 17
gen sandwich_cuis = cuisine == 58 | cuisine == 59

gen buffet_serv = service == 2 | service == 3 | service == 4
gen cater_serv = service == 6
gen counter_serv = service == 3 | service == 7 | service == 13
gen take_out_serv = service == 10 | service == 11 
gen wait_serv = service == 4|service==13|service==14
gen cafeteria_serv = service == 5

gen time_since_last = INSPDATE - last
gen time2next = next - INSPDATE

// Lag terms
sort CAMIS INSPDATE, stable
by CAMIS: gen last_LO = LO_SCORE[_n-1]
sort CAMIS INSPDATE, stable
by CAMIS: gen last_grade = grade[_n-1]
sort CAMIS INSPDATE, stable
by CAMIS: gen last_mod_grade = mod_grade[_n-1]


sort CAMIS inspect_type INSPDATE, stable
by CAMIS inspect_type, sort: gen n_same_type_score = SCORE[_n + 1]
sort CAMIS inspect_type INSPDATE, stable
by CAMIS inspect_type, sort: gen next_same_type_date = INSPDATE[_n + 1]
gen time2nextInit = next_same_type_date - INSPDATE

local vars Facility_Maintenance Food_Protection Personal_Hygiene ///
Food_Temperature Vermin_Garbage General_Food_Source Facility_Design ///
Critical_Food_Source 

by InspectorID post inspect_type, sort: gen inspector_cnt = _N
by InspectorID post inspect_type CAMIS, sort: gen inspect_camis_cnt = _N

egen inspector_score = sum(SCORE), by(InspectorID post inspect_type)
egen inspector_camis_score = sum(SCORE), ///
by(InspectorID post inspect_type CAMIS)
gen LO_SCORE2 = ///
(inspector_score - inspector_camis_score)/(inspector_cnt - inspect_camis_cnt)

gen post_date = max(INSPDATE, CASE_DECISION_DATE)
replace post_date = INSPDATE if inspect_type == 1
gen post_year = year(post_date)
sort CAMIS INSPDATE, stable
by CAMIS: gen last_post_date = post_date[_n - 1]
gen time2next_cap = min(time2next,mdy(12,31,year(post_date)) - post_date)
gen interim = max(CASE_DECISION_DATE - INSPDATE, 0)
replace interim = 0 if inspect_type == 1
gen carry_over = 0
replace carry_over = INSPDATE - mdy(1,1,year(INSPDATE)) ///
if year(last_post_date) < year(INSPDATE)
gen weight = carry_over + time2next_cap
egen weight_check = sum(weight), by(CAMIS year)
sort CAMIS year INSPDATE
sort CAMIS year inspect_type, stable
by CAMIS year inspect_type: gen seq = _n

foreach g in 1 2 3 {
	/*Loop creates Leave One Out Variables for Inspector Propensity to give out
	 *Letter Grade A, B, or C  */
	disp "`g'"
	gen mod_`g' = mod_grade == `g'
	gen grade_`g' = grade == `g'
	gen last_mod_`g' = last_mod_grade == `g'
	egen inspect_`g' = sum(grade == `g'), by(InspectorID post inspect_type)
	egen inspect_camis_`g'= sum(grade == `g'), ///
	by(InspectorID post inspect_type CAMIS)
	gen LO_`g' = ///
	(inspect_`g' - inspect_camis_`g')/(inspector_cnt - inspect_camis_cnt)
	sort CAMIS INSPDATE, stable
	by CAMIS: gen last_LO_`g' = LO_`g'[_n - 1]
	//gen mod_`g'_w = weight*mod_`g'
	//gen LO_`g'_w = weight*LO_`g'
	
	gen mod_`g'_w = time2next_cap*mod_`g' + carry_over*last_mod_`g' 
	gen LO_`g'_w = time2next_cap*LO_`g' + carry_over*last_LO_`g'
	
	egen LO_`g'_initial = sum(LO_`g' * (inspect_type == 1)), by(CAMIS year)
	egen mod_`g'_annual = sum(mod_`g'_w), by(CAMIS year)
	replace mod_`g'_annual = mod_`g'_annual/weight_check
	egen LO_`g'_annual = sum(LO_`g'_w), by(CAMIS year)
	replace LO_`g'_annual = LO_`g'_annual/weight_check
	foreach t in 1 2 3 {
		egen LO_`g'_`t' = sum(LO_`g' * (seq == `t') * (inspect_type == 1)), ///
		by(CAMIS year)
	}
}

foreach t in 1 2 3 {
	egen LO_SCORE2_`t' = sum(LO_SCORE2 * (seq == `t') * (inspect_type == 1)), ///
	by(CAMIS year)	
	egen inspector_cnt_`t' = ///
	sum(inspector_cnt * (seq == `t') * (inspect_type == 1)), by(CAMIS year)	
}

foreach v of varlist `vars' {
	sort CAMIS inspect_type INSPDATE, stable
	by CAMIS inspect_type, sort: gen n_`v' = `v'[_n + 1]
	sort CAMIS INSPDATE
	sort CAMIS, stable
	by CAMIS: gen last_LO_`v' = LO_`v'[_n-1]
	sort CAMIS INSPDATE
	sort CAMIS, stable
	by CAMIS: gen last_f_`v' = `v'[_n-1]
}
// Inspector Specific Metrics
egen Inspector_avg_score = mean(SCORE), by(InspectorID post) 
by InspectorID post inspect_type, sort: gen InspectorID_uniq = _n == 1

/**** Label variables ******/
label variable SCORE                 "Score"
label variable MOD_TOTALSCORE        "Modified Score"
label variable next_score            "next score"
label variable inspect_type          "re-inspection"
label variable age                   "age (in days)"
label variable last_LO               "last inspector propensity"
label variable inspect_type          "re-inspection"
label variable chain_restaurant      "chain"
label variable last_score            "last score"
label variable LO_SCORE              "Inspector Propensity"

label variable Vermin_Garbage        "Vermin/Garbage"
label variable Food_Protection       "Food Protection"
label variable Food_Temperature      "Food Temperature"
label variable Facility_Maintenance  "Facility Maintenance"
label variable Facility_Design       "Facility Design"
label variable Personal_Hygiene      "Personal Hygiene"
label variable Critical_Food_Source  "Crit. Food Source"
label variable General_Food_Source   "Gen. Food Source"

//label variable american_cuis "American"
label variable chinese_cuis          "Chinese"
label variable pizza_italian_cuis    "Pizza/Italian"
label variable coffee_tea_cuis       "Coffee/Tea"
label variable latin_cuis            "Latin" 
label variable spanish_cuis          "Spanish"
label variable carribean_cuis        "Carribean"
label variable sandwich_cuis         "Sandwich"
label variable sea_food_cuis         "Sea Food"

foreach v of varlist `vars' {
	local lab: variable label `v'
	label variable last_LO_`v' "last `lab'"
}
