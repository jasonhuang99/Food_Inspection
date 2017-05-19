set more off

cd "~/Desktop/NYC Food Inspection/Data/DTA"
use inspect_processed.dta, clear

//cd "~/Desktop/NYC Food Inspection/Data/RegOutput"
cd "~/Dropbox/Research Ideas/Food Inspection Scores/New York/Tex/Tables"

/********** 1st Stage **************/
label variable LO_SCORE2 "Z"

foreach condition in "" "& inspect_type == 1" "& inspect_type == 2" {
	if "`condition'" == "" {
		local title "Full"
		local file "F"
	}
	if "`condition'" == "& inspect_type == 1" {
		local title "Initial Inspections"
		local file "I"
	}
	if "`condition'" == "& inspect_type == 2" {
		local title "Re-inspection"
		local file "R"
	}

	qui: reghdfe SCORE LO_SCORE2 ///
	if post == 1 & inspector_cnt > 50 `condition', ///
	absorb(INSPDATE) cluster(InspectorID ZIPCODE)
	
	outreg2 using FirstStage_`file'.tex, replace tex(frag) label ///
	addtext(Restaurant Controls, NO, Restaurant FE, NO) ///
	addstat("F Statistics", e(F)) 
	
	qui: reghdfe SCORE LO_SCORE2 ///
	if post == 1 & inspector_cnt > 50 `condition', ///
	absorb(INSPDATE ZIPCODE chain cuisine service venue) ///
	cluster(InspectorID ZIPCODE)
	outreg2 using FirstStage_`file'.tex, append tex(frag) label ///
	addtext(Restaurant Controls, YES, Restaurant FE, NO) ///
	addstat("F Statistics", e(F)) 
	
	qui: reghdfe SCORE LO_SCORE2 ///
	if post == 1 & inspector_cnt > 50 `condition', ///
	absorb(INSPDATE CAMIS) cluster(InspectorID ZIPCODE)
	outreg2 using FirstStage_`file'.tex, append tex(frag) label ///
	addtext(Restaurant Controls, NO, Restaurant FE, YES) ///
	addstat("F Statistics", e(F))
}
