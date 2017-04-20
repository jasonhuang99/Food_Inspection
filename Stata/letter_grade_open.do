/***************** Calculate Administrative Costs *****************/

set more off

cd "~/Desktop/NYC Food Inspection/Data/DTA"

//use nyc_inspect_shift.dta, clear
use code.dta, clear

cd "~/Desktop/NYC Food Inspection/Script/Stata"

do pre_process.do

egen open_next = min(open), by(CAMIS year)

by CAMIS year, sort: gen camis_year = _n == 1
by CAMIS year inspect_type, sort: gen camis_year_cnt = _N

egen closed = max((ACTION == 6) & open == 0), by(CAMIS)

egen re_inspected = sum(next_type == 2), by(CAMIS year)
replace re_inspected = min(re_inspected,3)
egen camis_year_initial = sum(inspect_type == 1), by(CAMIS year)

reghdfe LO_1 last_score i.last_grade last_LO ///
chain_restaurant  *_cuis            ///
ib22.venue *_serv                                        ///
if post ==1 & BORO != 0 & inspect_cnt > 100 &                                /// 
(inspect_type == 1 | inspect_type == 2) &                                    ///
service != 1,                        ///
absorb(INSPDATE ZIPCODE inspect_type) cluster(InspectorID CAMIS) 

egen first_grade = sum(grade*(inspect_type == 1)*(seq == 1)), by(CAMIS year)
egen first_inspector = sum(InspectorID*(inspect_type == 1)*(seq == 1)), by(CAMIS year)
egen first_SCORE = sum(SCORE*(inspect_type == 1)*(seq == 1)), by(CAMIS year)
egen first_mod_SCORE = sum(max(MOD_TOTALSCORE - 13,0)*(inspect_type == 1)*(seq == 1)), by(CAMIS year)
egen worst_grade = max(mod_grade), by(CAMIS year)

gen A_grade = mod_grade == 1
gen B_grade = mod_grade == 2
gen C_grade = mod_grade == 3

egen avg_A = mean(A_grade), by(CAMIS year)
egen avg_B = mean(B_grade), by(CAMIS year)
egen avg_C = mean(C_grade), by(CAMIS year)

replace A_grade = . if inspect_type == 1 & SCORE > 13
replace B_grade = . if inspect_type == 1 & SCORE > 13
replace C_grade = . if inspect_type == 1 & SCORE > 13

foreach n in 1 2 3 {
	gen LO_`n'_a = LO_`n'
	replace LO_`n'_a = . if inspect_type == 1 & SCORE > 13
	egen avg_LO_`n' = mean(LO_`n'_a), by(CAMIS year)
}

egen avg_Aa = mean(A_grade), by(CAMIS year)
egen avg_Ba = mean(B_grade), by(CAMIS year)
egen avg_Ca = mean(C_grade), by(CAMIS year)

gen w_A_mod = worst_grade == 1
gen w_B_mod = worst_grade == 2
gen w_C_mod = worst_grade == 3

gen re_inspect = min(re_inspected,1)

gen first_fail = first_grade > 1

/**** Label Variables *******************************/
label variable open_next "Survived to Next Year"
label variable first_fail "No A in Initial Inspect"
label variable re_inspect "Re-inspected"

cd "~/Desktop/NYC Food Inspection/Data/RegOutput/Adjudication"

egen LO_SCORE2_avg = mean(LO_SCORE2), by(CAMIS year)
egen SCORE_avg = mean(SCORE), by(CAMIS year)
egen MOD_SCORE_avg = mean(MOD_TOTALSCORE), by(CAMIS year)

label variable LO_SCORE2_avg "Avg. Yearly Inspector Score"
label variable SCORE_avg "Avg. Yearly Score"
label variable MOD_SCORE_avg "Avg. Yearly Modified Score"

reghdfe open_next SCORE_avg ///
if camis_year == 1  & closed_dept == 0 & ///
year < 2015 & year >= 2011 & inspector_cnt_1 > 50, ///
absorb(CAMIS year) cluster(ZIPCODE)
outreg2 using open_score.tex, replace nor2 tex(frag) label ctitle("OLS")

reghdfe open_next (SCORE_avg = LO_SCORE2_avg) ///
if camis_year == 1  & closed_dept == 0 & ///
year < 2015 & year >= 2011 & inspector_cnt_1 > 50, ///
absorb(CAMIS year) cluster(ZIPCODE)
outreg2 using open_score.tex, append nor2 tex(frag) label ctitle("IV")

reghdfe open_next MOD_SCORE_avg ///
if camis_year == 1  & ///
year < 2015 & year >= 2011 & inspector_cnt_1 > 50,  ///
absorb(CAMIS year) cluster(ZIPCODE)
outreg2 using open_score.tex, append nor2 tex(frag) label ctitle("OLS")

reghdfe open_next (MOD_SCORE_avg = LO_SCORE2_avg) ///
if camis_year == 1  & ///
year < 2015 & year >= 2011 & inspector_cnt_1 > 50,  ///
absorb(CAMIS year) cluster(ZIPCODE)
outreg2 using open_score.tex, append nor2 tex(frag) label ctitle("IV")

/*
reghdfe mod_2_annual LO_2_annual LO_3_annual ///
if post == 1 & camis_year == 1, ///
absorb(CAMIS year) cluster(ZIPCODE)
*/
/**** Look Over ********************/
cd "~/Desktop/NYC Food Inspection/Data/RegOutput"
label variable mod_1_annual "A"
label variable mod_3_annual "C"

reghdfe open_next avg_Aa avg_Ca ///
if camis_year == 1 & year >= 2011 & year < 2015 & closed == 0, ///
a(CAMIS year) cluster(ZIPCODE)

reghdfe open_next (avg_Aa = avg_LO_1) ///
if camis_year == 1 & year >= 2011 & year < 2015 & closed == 0, ///
a(CAMIS year) cluster(ZIPCODE)

reghdfe open_next mod_1_annual mod_3_annual  ///
if camis_year == 1 & year >= 2011 & year < 2015 & closed == 0, ///
a(CAMIS year) cluster(ZIPCODE)

reghdfe open_next mod_1_annual mod_3_annual  ///
if camis_year == 1 & year >= 2011 & year < 2015 & closed == 0, ///
a(CAMIS year) cluster(ZIPCODE)

outreg2 using open_grade.tex, replace nor2 tex(frag) label ctitle("OLS")

reghdfe open_next (mod_1_annual mod_3_annual = LO_1_annual LO_3_annual) ///
if camis_year == 1 & year >= 2011 & year < 2015 & closed == 0, ///
a(CAMIS year) cluster(ZIPCODE)
outreg2 using open_grade.tex, append nor2 tex(frag) label ctitle("IV")

/*** Create Summary Table for Survival **************/
label define year_val 2007 "2007" 2008 "2008" 2009 "2009" 2010 "2010" ///
2011 "2011" 2012 "2012" 2013 "2013" 2014 "2014" 2015 "2015" 2016 "2016"
label value year year_val

label define open_val 0 "closed" 1 "open"
label value open_next open_val

latab year open_next if camis_year == 1 & year >= 2008 & year <= 2014 & closed_dept == 0, ///
tf(survival) replace 
latab year open_next if camis_year == 1 & year >= 2008 & year <= 2014 & closed_dept == 0, ///
row dec(1) tf(survival) append 

lpoly re_inspect LO_SCORE2_1 if camis_year == 1 &  ///
post == 1 & inspector_cnt_1 > 50, noscatter ci bw(1.5) level(99) 

/*
reghdfe open_next first_mod_SCORE ///
if camis_year == 1 & first_grade != 0 ///
& year < 2015 & year >= 2011 & inspector_cnt_1 > 50, ///
absorb(CAMIS year) cluster(ZIPCODE first_inspector)

reghdfe open_next (first_mod_SCORE = LO_SCORE2_1) ///
if camis_year == 1 & first_grade != 0 ///
& year < 2015 & year >= 2011 & inspector_cnt_1 > 50, ///
absorb(CAMIS year) cluster(ZIPCODE first_inspector)

reghdfe open_next first_fail ///
if camis_year == 1 & first_grade != 0 ///
& year < 2015 & year >= 2011 & inspector_cnt_1 > 50, ///
absorb(CAMIS year) cluster(ZIPCODE first_inspector)
outreg2 using open.tex, replace nor2 tex(frag) label ///
addtext(Restaurant FE, Yes, Year FE, Yes) ctitle("OLS")

reghdfe open_next (first_fail = LO_SCORE2_1) ///
if camis_year == 1 & first_grade != 0 & ///
year < 2015 & year >= 2011 & inspector_cnt_1 > 50, ///
absorb(CAMIS year) cluster(ZIPCODE first_inspector)
outreg2 using open.tex, append nor2 tex(frag) label ///
addtext(Restaurant FE, Yes, Year FE, Yes) ctitle("IV")

reghdfe open_next re_inspect ///
if camis_year == 1 & first_grade != 0 & ///
year < 2015 & year >= 2011 & inspector_cnt_1 > 50 & ///
(first_grade == 1 | re_inspect > 0), ///
absorb(CAMIS year) cluster(ZIPCODE) 
outreg2 using open.tex, append nor2 tex(frag) label ///
addtext(Restaurant FE, Yes, Year FE, Yes) ctitle("OLS")

reghdfe open_next (re_inspect = LO_SCORE2_1) ///
if camis_year == 1 & first_grade != 0 & ///
year < 2015 & year >= 2011 & inspector_cnt_1 > 50 & ///
(first_grade == 1 | re_inspect > 0), ///
absorb(CAMIS year) cluster(ZIPCODE first_inspector)
outreg2 using open.tex, append nor2 tex(frag) label ///
addtext(Restaurant FE, Yes, Year FE, Yes) ctitle("IV")

gen first_S2 = first_SCORE*first_SCORE
reghdfe open_next (first_SCORE = LO_SCORE2_1) ///
if camis_year == 1 & first_grade != 0 & ///
year < 2015 & year >= 2011 & inspector_cnt_1 > 50, ///
absorb(CAMIS year) cluster(ZIPCODE first_inspector)
*/
