set more off

cd "~/Desktop/NYC Food Inspection/Data/DTA"
use inspect_processed.dta, clear

local vars Food_Protection Vermin_Garbage Facility_Design ///
Food_Temperature Facility_Maintenance Personal_Hygiene General_Food_Source ///
Critical_Food_Source 

label variable Food_Protection "Food Protection"
label variable LO_Food_Protection "Food Protection"
label variable Facility_Design "Facility Design"
label variable LO_Facility_Design "Facility Design"
label variable Facility_Maintenance "Facility Maintenance"
label variable LO_Facility_Maintenance "Facility Maintenance"
label variable Vermin_Garbage "Vermin/Garbage"
label variable LO_Vermin_Garbage "Vermin/Garbage"
label variable Food_Temperature "Food Temperature"
label variable LO_Food_Temperature "Food Temperature"
label variable Personal_Hygiene "Personal Hygiene"
label variable LO_Personal_Hygiene "Personal Hygiene"
label variable General_Food_Source "Gen. Food Source"
label variable LO_General_Food_Source "Gen. Food Source"
label variable Critical_Food_Source "Crit. Food Source"
label variable LO_Critical_Food_Source "Crit. Food Source"

//file open myfile using "task_reg_coef.txt", write replace
//file open se_file using "task_reg_se.txt", write replace

local vars Facility_Maintenance Food_Protection Personal_Hygiene ///
Food_Temperature Vermin_Garbage General_Food_Source Facility_Design ///
Critical_Food_Source 

local vars_cnt Facility_Maintenance_cnt Food_Protection_cnt Personal_Hygiene_cnt ///
Food_Temperature_cnt Vermin_Garbage_cnt General_Food_Source_cnt Facility_Design_cnt ///
Critical_Food_Source_cnt

local inst LO_Facility_Maintenance LO_Food_Protection LO_Personal_Hygiene ///
LO_Food_Temperature LO_Vermin_Garbage LO_General_Food_Source LO_Facility_Design ///
LO_Critical_Food_Source 

local inst_cnt LO_Facility_Maintenance_cnt LO_Food_Protection_cnt ///
LO_Personal_Hygiene_cnt ///
LO_Food_Temperature_cnt LO_Vermin_Garbage_cnt LO_General_Food_Source_cnt ///
LO_Facility_Design_cnt LO_Critical_Food_Source_cnt

cd "~/Desktop/NYC Food Inspection/Data/RegOutput"

/*
local beta = _b[LO_Food_Temperature]
local se = _se[LO_Food_Temperature]
file write myfile "`beta'"
file write myfile "\t"
file write se_file "`se'"
file write se_file "\t"	
foreach v of varlist `vars' {
	local beta = _b[LO_`v']
	local se = _se[LO_`v']
	file write myfile "`beta'"
	file write myfile "\t"
	file write se_file "`se'"
	file write se_file "\t"		
}
*/
//file write myfile "\n"
foreach v of varlist `vars'{
	local lab: variable label `v'
	if "`v'" == "Facility_Maintenance" {
		disp "`v'"
		local change "replace"
	} 
	else {
		local change "append"
	}
	quietly: reghdfe `v' `inst' ///
	if post == 1 & inspector_cnt > 50, ab(INSPDATE ZIPCODE chain cuisine service venue) ///
	cluster(ZIPCODE InspectorID)
	outreg2 using task.tex, `change' tex(frag) label ///
	addtext(Time FE, YES) 
	reghdfe `v'_cnt `inst_cnt' ///
	if post == 1 & inspector_cnt > 50, ab(INSPDATE ZIPCODE chain cuisine service venue) ///
	cluster(ZIPCODE InspectorID)
	outreg2 using task_cnt.tex, `change' tex(frag) label ///
	addtext(Time FE, YES) 
	//#matrix list e(b)
	//local beta = _b[LO_Food_Temperature]
	//local se = _se[LO_Food_Temperature]
	/*  Test whether more stringent inspectors are more stringent across 
	different dimensions: 
	quietly: reghdfe `v' LO_SCORE2 ///
	if post == 1 & inspector_cnt > 50, ab(INSPDATE ZIPCODE chain cuisine service venue) ///
	cluster(ZIPCODE InspectorID)
	//#matrix list e(b)
	outreg2 using mono.tex, `change' tex(frag) label ///
	addtext(Time FE, YES)  */
	qui: reghdfe n_`v' (`vars' = `inst')              ///
	if post == 1 & inspect_type  == 1 & inspector_cnt > 50,                      ///
	a(INSPDATE next_same_type_date ZIPCODE chain cuisine service venue) ///
	cluster(InspectorID ZIPCODE)
	qui: estadd ysumm
	outreg2 using tasks_IV.tex, `change' tex(frag) label ctitle("`lab'") ///
	nor2 addstat("dependent mean", e(ymean)) 

	qui: reghdfe n_`v'_cnt (`vars' = `inst_cnt')              ///
	if post == 1 & inspect_type  == 1 & inspector_cnt > 50,                      ///
	a(INSPDATE next_same_type_date ZIPCODE chain cuisine service venue) ///
	cluster(InspectorID ZIPCODE)
	qui: estadd ysumm
	outreg2 using tasks_IV_cnt.tex, `change' tex(frag) label ctitle("`lab'") ///
	nor2 addstat("dependent mean", e(ymean)) 

	/*
	file write myfile "`beta'"
	file write myfile "\t"
	file write se_file "`se'"
	file write se_file "\t"	
	foreach v of varlist `vars' {
		local beta = _b[LO_`v']
		local se = _se[LO_`v']
		file write myfile "`beta'"
		file write myfile "\t"
		file write se_file "`se'"
		file write se_file "\t"
	}
	//file write myfile "\n"*/
}
//file close myfile
//file close se_file
disp "end"
//log close

/*************** Unused **********************/

/*
foreach v of varlist `vars'{
	foreach d of varlist `vars' {
		disp "`v'" 	" "	"`d'"

		quietly: reghdfe `v' LO_`d' if post == 1, ab(INSPDATE CAMIS) ///
		cluster(ZIPCODE InspectorID)
		disp _b[LO_`d']
		disp _se[LO_`d']
	}
}
*/
//outreg2 using task.tex, replace tex(frag) label ///
//addtext(Restaurant FE, YES)
/*
disp "start"
disp _b[LO_Food_Temperature]
disp _b[LO_Food_Protection]
disp _b[LO_Facility_Design]  
disp _b[LO_Facility_Maintenance] 
disp _b[LO_Vermin_Garbage]
disp _b[LO_Personal_Hygiene]
disp _b[LO_General_Food_Source]
disp _b[LO_Critical_Food_Source]
disp _se[LO_Food_Temperature]
disp _se[LO_Food_Protection]
disp _se[LO_Facility_Design]  
disp _se[LO_Facility_Maintenance] 
disp _se[LO_Vermin_Garbage]
disp _se[LO_Personal_Hygiene]
disp _se[LO_General_Food_Source]
*/
//disp _se[LO_Critical_Food_Source]
/*
disp _b[LO_Facility_Design]  
disp _b[LO_Facility_Maintenance] 
disp _b[LO_Vermin_Garbage]
disp _b[LO_Personal_Hygiene]
disp _b[LO_General_Food_Source]
disp _b[LO_Critical_Food_Source]
disp _se[LO_Food_Temperature]
disp _se[LO_Food_Protection]
disp _se[LO_Facility_Design]  
disp _se[LO_Facility_Maintenance] 
disp _se[LO_Vermin_Garbage]
disp _se[LO_Personal_Hygiene]
disp _se[LO_General_Food_Source]
disp _se[LO_Critical_Food_Source]
//outreg2 using task.tex, append tex(frag) label ///
//addtext(Restaurant FE, YES)
*/
