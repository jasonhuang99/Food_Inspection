set more off

cd "~/Desktop/NYC Food Inspection/Data/DTA"
use code.dta, clear
cd "~/Desktop/NYC Food Inspection/Script/Stata"
run pre_process.do

local vars Food_Protection Facility_Design  Facility_Maintenance ///
Vermin_Garbage Personal_Hygiene General_Food_Source ///
Critical_Food_Source Food_Temperature 

cd "~/Desktop/NYC Food Inspection/Figures/Task_Bunch"
local graphs ""
foreach v of varlist `vars' {
	local lab: variable label `v'
	quietly: eststo `v': reghdfe `v' ib13.SCORE ///
	if SCORE <= 35 & SCORE >= 5 & inspect_type == 2 & post == 1, ///
	absorb(INSPDATE ZIPCODE) cluster(CAMIS InspectorID)
	local graphs "`graphs' `v'.gph"
	coefplot, vertical xlabel(, angle(vertical)) xline(8.5) xline(22.5) ///
	keep(*.SCORE) ///
	title("`lab'") legend(off) recast(line)  ///
	 saving(`v', replace) ylabel(none) 
	graph export `v'.png, replace
}

graph combine Facility_Maintenance.gph Food_Protection.gph Personal_Hygiene.gph ///
Food_Temperature.gph, col(2) ///
title("Probability of Violation Citation By Scores") 
graph export tasks_scores.png, replace

graph combine Vermin_Garbage.gph General_Food_Source.gph Facility_Design.gph  ///
Critical_Food_Source.gph, col(2) ///
title("Probability of Violation Citation By Scores") 
graph export tasks_scores.png, replace




// saving(`v'.png, replace)
/*
label(2 "Food Protection") label(2 "Facility Design") ///
	label(3 "Facility Maintenance") label(4 "Vermin Garbage") ///
	label(5 "Personal Hygiene") label(6 "General Food Source") ///
	label(7 "Critical Food Source") label(8 "Food Temperature") ///*/
