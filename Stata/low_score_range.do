set more off

cd "~/Desktop/NYC Food Inspection/Data/DTA"
use inspect_processed.dta, clear

cd "~/Dropbox/Research Ideas/Food Inspection Scores/New York/Tex/Tables"

gen below_13 = SCORE <= 13
gen SCORE_b13 = SCORE*(SCORE <= 13)
gen LO_SCORE2_b13 = LO_SCORE2*(SCORE <= 13)

reghdfe n_same_type_A SCORE                               ///
if inspect_type  == 1 & inspector_cnt > 50,     ///
a(INSPDATE CAMIS next_same_type_date) cluster(InspectorID ZIPCODE)

reghdfe n_same_type_score ///
(SCORE SCORE_b13 = LO_SCORE2 c.LO_SCORE2_b13#c.LO_b13)       ///
if inspect_type  == 1 & inspector_cnt > 50 & post == 1,                      ///
a(INSPDATE CAMIS next_same_type_date) cluster(InspectorID ZIPCODE)

reghdfe n_same_type_shutdown ///
(SCORE SCORE_b13 = LO_SCORE2 c.LO_SCORE2_b13#c.LO_b13)     ///
if inspect_type  == 1 & inspector_cnt > 50 & post == 1 &                     ///
(SCORE <= 28 | l1_same_type_score <= 28 | l2_same_type_score <= 28),         ///
a(INSPDATE CAMIS next_same_type_date) cluster(InspectorID ZIPCODE)

reghdfe n_same_type_A ///
(SCORE SCORE_b13 = LO_SCORE2 c.LO_SCORE2_b13#c.LO_b13) ///
if inspect_type  == 1 & inspector_cnt > 50 & post == 1,                      ///
a(INSPDATE CAMIS next_same_type_date) ///
cluster(InspectorID ZIPCODE)


reghdfe n_same_type_score SCORE                               ///
if inspect_type  == 1 & inspector_cnt > 50 & SCORE <= 11,     ///
a(INSPDATE CAMIS next_same_type_date) cluster(InspectorID ZIPCODE)

