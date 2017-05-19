set more off

cd "~/Desktop/NYC Food Inspection/Data/DTA"
use inspect_processed.dta, clear

gen venue_copy = venue
gen service_copy = service
tab venue
replace venue = 22 if venue == 4 | venue == 7 |    ///
venue == 8  | venue == 9  | venue == 10 | venue == 13 | venue == 16 |        ///
venue == 17 | venue == 18 | venue == 19 | venue == 20 | venue == 21 |        ///
venue == 25 | venue == 26 | venue == 27 
replace venue = 23 if venue == 12

replace venue = 23 if venue == 24 | venue == 2 | venue == 5 | venue == 6
//replace venue = 5 if venue == 6
replace venue = 14 if venue == 15
replace venue = 10 if venue == 11 | venue == 3
replace venue = 10 if venue == 1

replace service = 10 if service == 11
gen bar = (venue == 5) | venue == 6
gen fast_food = venue == 14
gen restaurant = venue == 23

replace service = 14 if service == 8 | service == 9
/*
label define venue_label 99 "other/missing", add
label values venue venue_label 
*/

/******* Prepare Regression Outputs *******************************************/
cd "~/Dropbox/Research Ideas/Food Inspection Scores/New York/Tex/Tables/"
reghdfe SCORE last_score i.last_grade last_LO  ///
chain_restaurant  *_cuis ib22.venue *_serv                                   ///
if post ==1 & BORO != 0 & inspector_cnt > 50 &                               /// 
(inspect_type == 1 | inspect_type == 2) & service != 1,                      ///
absorb(INSPDATE ZIPCODE inspect_type) cluster(InspectorID ZIPCODE) 
outreg2 using random.tex, replace tex(frag) label                            ///
addstat("F Statistics", e(F)) sideway nor2 ctitle("Score")

reghdfe LO_SCORE2 last_score i.last_grade last_LO                            ///
chain_restaurant *_cuis ib22.venue *_serv                                    ///
if post ==1 & BORO != 0 & inspector_cnt > 50 &                               /// 
(inspect_type == 1 | inspect_type == 2) & service != 1,                      ///
absorb(INSPDATE ZIPCODE inspect_type) cluster(InspectorID ZIPCODE) 
outreg2 using random.tex, append tex(frag) label ctitle("> 50 Inspections")  ///
addstat("F Statistics", e(F)) sideway nor2

reghdfe LO_SCORE2 last_score i.last_grade last_LO                            ///
chain_restaurant *_cuis ib22.venue *_serv                                    ///
if post ==1 & BORO != 0 & inspector_cnt > 650 &                              /// 
(inspect_type == 1 | inspect_type == 2) & service != 1,                      ///
absorb(INSPDATE ZIPCODE inspect_type) cluster(InspectorID ZIPCODE) 
outreg2 using random.tex, append tex(frag) label ctitle("> 650 Inspections") ///
addstat("F Statistics", e(F)) sideway nor2

/************* Iterate Through All Groups ***********************************/
cd "~/Desktop/NYC Food Inspection/Figures/First_Stage"

set scheme s2color
lpoly SCORE LO_SCORE2 if inspector_cnt >= 50 & ///
post == 1 & LO_SCORE <= 40 , noscatter ci bw(2) level(99) ///
xlabel(0(10)40) xscale(range(0 10) noextend)                                 ///
if inrange(LO_SCORE, 0, 40)                                                  ///
title("First Stage Graph") xtitle("Inspector Specific Score")                 ///
ytitle("Score") yaxis(1) ///
addplot(hist Inspector_avg_score ///
        if InspectorID_uniq == 1 & inspector_cnt >= 50 ///
		& post == 1 & Inspector_avg_score <= 40, width(0.5) yaxis(2) ///
		fcolor(none) lcolor(black)) legend(off) note("") ///
		graphregion(color(white))
graph export first_stage_score.png, replace

local vars Food_Protection Facility_Design Facility_Maintenance ///
Vermin_Garbage Personal_Hygiene General_Food_Source Food_Temperature

foreach v of varlist `vars' {
	local lab: variable label `v'
	lpoly `v' LO_`v' if ///
	inspect_type  == 1 & next_type == 2 & ///
	post == 1, noscatter ci bw(0.05) level(99) ///
	title("`lab'") xtitle("Inspector Specific Score") ytitle("Pr of Detection") ///
	addplot(hist LO_`v' ///
			if post == 1, width(0.025) yaxis(2) ///
			fcolor(none) lcolor(black)) nodraw saving(`v', replace) ///
			legend(off) note("")
}
graph combine Food_Protection.gph                        ///
Personal_Hygiene.gph General_Food_Source.gph Facility_Maintenance.gph        ///
Vermin_Garbage.gph Food_Temperature.gph, col(3) ///
title("1st Stage Graphs across Dimensions") saving(first_stage_multi.png, replace)

/*

reghdfe time_since_last last_score chain_restaurant                          ///
ib22.venue ib14.service                                          ///
if post ==1 & BORO != 0 & inspect_cnt > 100 & inspect_type == 1 &             /// 
(inspect_type == 1 | inspect_type == 2) &                                    ///
service != 1,                                                                ///
absorb(INSPDATE ZIPCODE inspect_type last_grade) cluster(InspectorID ZIPCODE) 

foreach v of varlist `vars' {
	disp "`v'"
	reghdfe `v' last_score                    ///
	 inspect_type chain_restaurant                 ///
	i.last_grade                                 ///                                        ///
	if post ==1 & BORO != 0 & inspect_cnt > 100 &                            /// 
	(inspect_type == 1 | inspect_type == 2) &  service != 1,                                                            ///
	absorb(INSPDATE ZIPCODE venue service) cluster(InspectorID CAMIS) 
	reghdfe LO_`v' last_score                    ///
	last_f_* inspect_type chain_restaurant                 ///
	i.last_grade                                 ///                                        ///
	if post ==1 & BORO != 0 & inspect_cnt > 100 &                            /// 
	(inspect_type == 1 | inspect_type == 2) &  service != 1,                                                            ///
	absorb(INSPDA ZIPCODE venue service) cluster(InspectorID CAMIS) 
	/*
	quietly: test last_f_Critical_Food_Source last_f_Facility_Design ///
	last_f_Facility_Maintenance last_f_Food_Protection ///
	last_f_General_Food_Source last_f_Personal_Hygiene ///
	last_f_Vermin_Garbage last_score
	disp r(p)
	*/
	/*
	quietly: test last_LO_Critical_Food_Source last_LO_Facility_Design ///
	last_LO_Facility_Maintenance last_LO_Food_Protection ///
	last_LO_General_Food_Source last_LO_Personal_Hygiene ///
	last_LO_Vermin_Garbage last_score  
	disp r(p)
	*/
}
*/
//(inspect_type == 1 | inspect_type == 2)

