set more off

cd "~/Desktop/NYC Food Inspection/Data/DTA"
use inspect_processed.dta, clear

cd "~/Dropbox/Research Ideas/Food Inspection Scores/New York/Tex/Tables/Tasks/"

local vars Food_Protection Vermin_Garbage Facility_Design ///
Food_Temperature Facility_Maintenance Personal_Hygiene General_Food_Source ///
Critical_Food_Source 

local vars Facility_Maintenance Food_Protection Personal_Hygiene             ///
Food_Temperature Vermin_Garbage General_Food_Source Facility_Design          ///
Critical_Food_Source 

// Current Count
local vars_cnt Facility_Maintenance_cnt Food_Protection_cnt                  ///
Personal_Hygiene_cnt Food_Temperature_cnt Vermin_Garbage_cnt                 ///
General_Food_Source_cnt Facility_Design_cnt Critical_Food_Source_cnt

// Group Citation Indicator Instrument
local inst LO_Facility_Maintenance LO_Food_Protection LO_Personal_Hygiene    ///
LO_Food_Temperature LO_Vermin_Garbage LO_General_Food_Source                 ///
LO_Facility_Design LO_Critical_Food_Source 

// Group Citation Count Instrument
local inst_cnt LO_Facility_Maintenance_cnt LO_Food_Protection_cnt            ///
LO_Personal_Hygiene_cnt LO_Food_Temperature_cnt LO_Vermin_Garbage_cnt        ///
LO_General_Food_Source_cnt LO_Facility_Design_cnt LO_Critical_Food_Source_cnt

foreach v of varlist `vars'{
	local lab: variable label `v'
	if "`v'" == "Facility_Maintenance" {
		disp "`v'"
		local change "replace"
	} 
	else {
		local change "append"
	}
	
	/********** Citation Indicator ********************************************/
	
	// First Stage
	qui: reghdfe `v' `inst'                                                  ///
	if post == 1 & inspect_type == 1 & inspector_cnt > 50,                   ///
	ab(INSPDATE ZIPCODE chain cuisine service venue)                         ///
	cluster(ZIPCODE InspectorID)
	qui: estadd ysumm
	outreg2 using task_first.tex, `change' tex(frag) label                   ///
	ctitle("`lab'") nor2 addstat("Dependent mean", e(ymean)) 
	
	// Second Stage
	qui: reghdfe n_`v' (`vars' = `inst')                                     ///
	if post == 1 & inspect_type  == 1 & inspector_cnt > 50,                  ///
	a(INSPDATE CAMIS next_same_type_date)                                    ///
	cluster(InspectorID ZIPCODE)
	qui: estadd ysumm
	outreg2 using tasks_IV.tex, `change' tex(frag) label                     ///
	ctitle("`lab'") nor2 addstat("Dependent mean", e(ymean)) 

	/******** Citation Counts *************************************************/
	
	// First Stage
	qui: reghdfe `v'_cnt `inst_cnt'                                          ///
	if post == 1 & inspect_type  == 1 & inspector_cnt > 50,                  ///
	a(INSPDATE CAMIS next_same_type_date)      ///
	cluster(InspectorID ZIPCODE)
	qui: estadd ysumm
	outreg2 using tasks_first_cnt.tex, `change' tex(frag) label              ///
	ctitle("`lab'") nor2 addstat("Dependent mean", e(ymean)) 

	// Second Stage
	qui: reghdfe n_`v'_cnt (`vars_cnt' = `inst_cnt')                         ///
	if post == 1 & inspect_type  == 1 & inspector_cnt > 50,                  ///
	a(INSPDATE CAMIS next_same_type_date)      ///
	cluster(InspectorID ZIPCODE)
	qui: estadd ysumm
	outreg2 using tasks_IV_cnt.tex, `change' tex(frag) label                 ///
	ctitle("`lab'") nor2 addstat("Dependent mean", e(ymean)) 
}
