cd "~/Desktop/NYC Food Inspection/Data/DTA"
use inspect_processed.dta, clear

//cd "~/Desktop/NYC Food Inspection/Data/RegOutput"
cd "~/Dropbox/Research Ideas/Food Inspection Scores/New York/Tex/Tables"

gen re_inspect = inspect_type == 2
gen re_open = inspect_type == 6

by CAMIS post, sort: gen camis_post = _n == 1
gen fast_food = venue == 13 | venue == 14
gen bar = venue == 5 | venue == 6

eststo summary_rest: estpost su chain fast_food bar *serv ///
if post == 1 & camis_post == 1 ///
, detail

eststo summary_inspect: estpost su chain fast_food bar *serv ///
if post == 1 ///
, detail

esttab summary_rest summary_inspect using summary_rest.tex, replace ///
cells((mean(fmt(2)) sd(fmt(2)) ) ) ///
label nonumber noobs mtitle("Restaurant Sample" "Inspection Sample")

label variable re_open "re-opening inspection"
label variable re_inspect "re-inspection"
eststo summary: estpost su MOD_TOTALSCORE SCORE temp_closed re_inspect ///
re_open if post == 1 ///
, detail

esttab summary using summary.tex, replace ///
cells((mean(fmt(2)) sd(fmt(2)) sd(fmt(2)) p25(fmt(0)) p50(fmt(0)) p75(fmt(0)) ///
count(fmt(%9.0gc )) ) ) ///
label nonumber noobs nomtitle
//esttab summary using summary.tex, append cells(sd)
