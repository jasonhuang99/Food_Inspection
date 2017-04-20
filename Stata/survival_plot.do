
set more off

cd "~/Desktop/NYC Food Inspection/Data/DTA"
use code.dta, clear
cd "~/Desktop/NYC Food Inspection/Script/Stata"
run pre_process.do

egen open_year = min(open), by(CAMIS year)
gen mod_grade2 = mod_grade
replace mod_grade2 = 1 if inspect_type == 1
egen best_grade = min(mod_grade2), by(CAMIS year)


by CAMIS year, sort: gen camis_year_uniq = _n == 1

eststo A: reg open_year i.year if ///
year >= 2009 & year < 2016 & camis_year_uniq == 1 & best_grade == 1, ///
r noconstant

eststo B: reg open_year i.year if ///
 year >= 2009 & year < 2016 & camis_year_uniq == 1 & best_grade == 2, ///
r noconstant

eststo C: reg open_year i.year if ///
 year >= 2009 & year < 2016 & camis_year_uniq == 1 & best_grade == 3, ///
r noconstant

coefplot A B C, vertical xlabel(,angle(vertical)) ///
title("Probability of Survival") keep(*.year) legend(col(3)) recast(line)

reghdfe open_year i.best_grade ///
if post == 1 & camis_year_uniq == 1, ///
a(CAMIS year) cluster(ZIPCODE InspectorID)
