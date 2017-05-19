set more off

cd "~/Desktop/NYC Food Inspection/Data/DTA"

use code.dta, clear

cd "~/Desktop/NYC Food Inspection/Script/Stata"

run pre_process2.do

egen AB_In = sum(post == 1 & SCORE >= 12 & SCORE <= 15 & inspect_type == 1), ///
by(InspectorID )

egen A_In = sum(post == 1 & SCORE >= 12 & SCORE <=13 & inspect_type == 1), ///
by(InspectorID )

gen A_bunch_In = A_In/AB_In

egen AB_Re = sum(post == 1 & SCORE >= 12 & SCORE <= 15 & inspect_type == 2), ///
by(InspectorID )

egen A_Re = sum(post == 1 & SCORE >= 12 & SCORE <=13 & inspect_type == 2), ///
by(InspectorID )

gen A_bunch_Re = A_Re/AB_Re

egen BC_Re = sum(post == 1 & SCORE >= 26 & SCORE <= 29 & inspect_type == 2), ///
by(InspectorID )

egen B_Re = sum(post == 1 & SCORE >= 26 & SCORE <=27 & inspect_type == 2), ///
by(InspectorID )

gen B_bunch_Re = B_Re/BC_Re

egen re_cnt = sum(post == 1 & inspect_type == 2), by(InspectorID)
egen in_cnt = sum(post == 1 & inspect_type == 1), by(InspectorID)

gen AB_in_margin_prob = AB_In/in_cnt
gen AB_re_margin_prob = AB_Re/re_cnt
gen BC_re_margin_prob = BC_Re/re_cnt

gen A = grade == 1
gen B = grade == 2
/*** How predictive are inspector  bunching preference to probability of 
getting bumped up *********/
reghdfe A A_bunch_In LO_SCORE ///
if post == 1 & SCORE <= 15 & SCORE >= 12 & inspect_type == 1, ///
absorb(CAMIS INSPDATE ) cluster(InspectorID CAMIS )

capture drop c
reghdfe A i.year ///
if post == 1 & SCORE <= 15 & SCORE >= 12 & inspect_type == 1, ///
absorb(c = CAMIS) cluster(InspectorID CAMIS )

capture drop resid
predict resid, residual
lpoly resid age if post == 1 & SCORE <= 15 & SCORE >= 12 & inspect_type == 1 ///
& age <= 3000, bw(200) noscatter ci title("Likelihood to Bunch into A") ///
legend(off) note("")

cd "~/Desktop/NYC Food Inspection/Figures/First_Stage"

graph export A_bunch_age.png, replace

reghdfe A i.year ///
if post == 1 & SCORE <= 15 & SCORE >= 12 & inspect_type == 1 & inspect_cnt > 50, ///
absorb(c_b = CAMIS) cluster(InspectorID CAMIS )
drop resid
predict resid, residual

lpoly resid age if post == 1 & SCORE <= 29 & SCORE >= 26 & inspect_type == 2 ///
& age <= 3000, bw(200) noscatter ci title("Likelihood to Go over ")

sort InspectorID INSPDATE , stable
by InspectorID : gen experience = _n

lpoly resid age if post == 1 & SCORE <= 15 & SCORE >= 12 & inspect_type == 1 ///
& inspect_cnt > 50 & age <= 3000, noscatter ci title("Likelihood to Go over ")

reghdfe A A_bunch_In LO_SCORE ///
if post == 1  & inspect_type == 1, ///
absorb(ZIPCODE venue INSPDATE ) cluster(InspectorID CAMIS )

reghdfe A A_bunch_Re LO_SCORE ///
if post == 1 & SCORE <= 15 & SCORE >= 12 & inspect_type == 2, ///
absorb(CAMIS INSPDATE ) cluster(InspectorID CAMIS )

reghdfe B B_bunch_Re LO_SCORE ///
if post == 1 & SCORE <= 29 & SCORE >= 26 & inspect_type == 2, ///
absorb(CAMIS INSPDATE ) cluster(InspectorID CAMIS )


