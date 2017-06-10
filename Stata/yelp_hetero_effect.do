set more off

cd "~/Desktop/NYC Food Inspection/Data/DTA"
use inspect_processed.dta, clear
sort CAMIS
merge m:1 CAMIS using inspect_yelp_comb.dta

gen exposure = review_count/age
cd "~/Dropbox/Research Ideas/Food Inspection Scores/New York/Tex/Tables"

gen plus_4 = rating >= 4 & rating != .

gen high_exposure = exposure >= 0.05 & exposure != .

gen SCORE_plus4 = SCORE * plus_4
gen SCORE_h_e = SCORE * high_exposure
gen SCORE_plus4_h_e = SCORE * plus_4 * high_exposure

gen LO_SCORE2_plus4 = LO_SCORE2 * plus_4
gen LO_SCORE2_h_e = LO_SCORE2 * high_exposure
gen LO_SCORE2_plus4_h_e = LO_SCORE2 * plus_4 * high_exposure

label variable SCORE_plus4 "Score X Plus_4"
label variable SCORE_h_e   "Score X High Exposure"
label variable SCORE_plus4_h_e "Score X Plus_4 X High Exposure"

reghdfe n_same_type_score                                                    ///
(SCORE SCORE_* = LO_SCORE2 LO_SCORE2_h_e LO_SCORE2_plus4*)                   ///
if post == 1 & inspect_type  == 1 & inspector_cnt > 50 & review_count != .,  ///
a(INSPDATE CAMIS next_same_type_date) cluster(InspectorID ZIPCODE) 
qui: estadd ysumm 
outreg2 using yelp_hetero.tex, replace tex(frag) label                     ///
ctitle("Score") addstat("dependent mean", e(ymean)) ///
nor2 addtext(Inspection Date FE, YES, Restaurant FE, YES) 


reghdfe n_same_type_shutdown                                                 ///
(SCORE SCORE_* = LO_SCORE2 LO_SCORE2_h_e LO_SCORE2_plus4*)                   ///
if post == 1 & inspect_type  == 1 & inspector_cnt > 50 & review_count != .,  ///
a(INSPDATE CAMIS next_same_type_date) cluster(InspectorID ZIPCODE) 
qui: estadd ysumm 
outreg2 using yelp_hetero.tex, append tex(frag) label                     ///
ctitle("Closure") addstat("dependent mean", e(ymean)) ///
nor2 addtext(Inspection Date FE, YES, Restaurant FE, YES) 

reghdfe n_same_type_A                                                        ///
(SCORE SCORE_* = LO_SCORE2 LO_SCORE2_h_e LO_SCORE2_plus4*)                   ///
if post == 1 & inspect_type  == 1 & inspector_cnt > 50 & review_count != .,  ///
a(INSPDATE CAMIS next_same_type_date) cluster(InspectorID ZIPCODE) 
qui: estadd ysumm 
outreg2 using yelp_hetero.tex, append tex(frag) label                     ///
ctitle("Grade A") addstat("dependent mean", e(ymean)) ///
nor2 addtext(Inspection Date FE, YES, Restaurant FE, YES) 
