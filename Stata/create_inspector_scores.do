set more off

cd "~/Desktop/NYC Food Inspection/Data/DTA"
use code.dta, clear

gen post = INSPDATE > mdy(10,1,2010)

encode INSPTYPE, gen(inspect_type)
by InspectorID post inspect_type, sort: gen inspector_cnt = _N

by InspectorID post inspect_type CAMIS, sort: gen inspect_camis_cnt = _N

egen inspector_score = sum(SCORE), by(InspectorID post inspect_type)
egen inspector_camis_score = sum(SCORE), ///
by(InspectorID post inspect_type CAMIS)
gen LO_SCORE2 = ///
(inspector_score - inspector_camis_score)/(inspector_cnt - inspect_camis_cnt)

keep CAMIS InspectorID LO_SCORE2 post inspector_cnt

by CAMIS InspectorID post, sort: gen keep_n = _n == 1
keep if keep_n == 1

keep if post == 1
sort CAMIS InspectorID
save inspector_score.dta, replace
