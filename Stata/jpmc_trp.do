set more off

cd "~/Desktop/NYC Food Inspection/Data/DTA/JPMC"

use days_grade.dta, clear
sort id trans_date
save days_grade.dta, replace

use trp_100.dta, clear
append using trp_103.dta
append using trp_104.dta
append using trp_110.dta
append using trp_111.dta
append using trp_112.dta
append using trp_113.dta
append using trp_114.dta

sort id trans_date

joinby id trans_date using days_grade.dta

encode trans_type, gen(trans_type_enc)
drop trans_type
rename trans_type_enc trans_type

gen log_rev = log(daily_rev_x)
gen log_trans = log(daily_trans_x)

label variable log_rev "Revenue"
label variable log_trans "Transaction Volume"
gen grade = "A" if visible_score >= 0 & visible_score <= 13
replace grade = "P" if visible_score < 0
replace grade = "B" if visible_score >= 14 & visible_score <= 27
replace grade = "C" if visible_score > 27

encode grade, gen(grade_enc)
drop grade
rename grade_enc grade

local table_path ///
"~/Dropbox/Research Ideas/Food Inspection Scores/JPMC/Tex/Tables/"

foreach v of varlist log_rev log_trans {
	local title: variable label `v'
	qui: reghdfe `v' i.grade if trans_type == 3, ///
	absorb(id trans_date id#DayOWeek) cluster(zipcode)
	outreg2 using "`table_path'brand_loyalty`v'.tex", ///
	replace label ctitle("Full") tex(frag) title("`title'")

	qui: reghdfe `v' i.grade if trans_type == 1, ///
	absorb(id trans_date id#DayOWeek) cluster(zipcode)
	outreg2 using "`table_path'brand_loyalty`v'.tex", ///
	append label ctitle("Non-Loyalist (NL)") tex(frag)

	qui: reghdfe `v' i.grade if trans_type == 2, ///
	absorb(id trans_date id#DayOWeek) cluster(zipcode)
	outreg2 using "`table_path'brand_loyalty`v'.tex", ///
	append label ctitle("Transient (T)") tex(frag)

	qui: reghdfe `v' i.grade i.grade#ib3.trans_type ///
	if trans_type == 3 | trans_type == 1, ///
	absorb(id trans_date id#DayOWeek trans_type id#trans_type trans_type#trans_date) ///
	cluster(zipcode)
	outreg2 using "`table_path'brand_loyalty`v'.tex", ///
	append label ctitle("T DDD") tex(frag)

	qui: reghdfe `v' i.grade i.grade#ib3.trans_type ///
	if trans_type == 3 | trans_type == 2, ///
	absorb(id trans_date id#DayOWeek trans_type id#trans_type trans_type#trans_date) ///
	cluster(zipcode)
	outreg2 using "`table_path'brand_loyalty`v'.tex", ///
	append label ctitle("NL DDD") tex(frag)
}
