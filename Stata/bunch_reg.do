set more off

cd "~/Desktop/NYC Food Inspection/Data/DTA/"
use nyc_inspect_shift.dta, clear

gen _12 = SCORE == 12
gen _13 = SCORE == 13
gen _14 = SCORE == 14
gen _15 = SCORE == 15

gen post = INSPDATE > mdy(8,1,2010)

by SCORE INSPTYPE post, sort: gen score_CNT = _N 
by SCORE INSPTYPE post, sort: gen score_uniq = _n 

gen SCORE_2 = SCORE*SCORE
gen SCORE_3 = SCORE_2*SCORE
gen SCORE_4 = SCORE_3*SCORE
gen SCORE_5 = SCORE_4*SCORE
gen SCORE_6 = SCORE_5*SCORE

reg score_CNT SCORE* if ///
INSPTYPE == "A" & post == 1 & score_uniq == 1  ///
& (SCORE < 12 | SCORE > 22), r

predict reg_hat2, xb
gen reg_hat = _b[_cons] + SCORE*_b[SCORE] + _b[SCORE_2]*SCORE_2 ///
+_b[SCORE_3]*SCORE_3 + _b[SCORE_4]*SCORE_4 + _b[SCORE_5]*SCORE_5

twoway  ///
(scatter score_CNT SCORE if INSPTYPE == "A" & post == 1 & score_uniq == 1 & SCORE <= 60 ///
& SCORE > 0) ///
(line reg_hat2 SCORE if INSPTYPE == "A" & post == 1 & score_uniq == 1 & SCORE <= 60 ///
& SCORE > 0)
/*
lpoly score_CNT SCORE if ///
INSPTYPE == "A" & post == 1 & score_uniq == 1 & SCORE > 0 ///
& (SCORE < 12 | SCORE > 15), bw(5) gen(hat) at(SCORE)

twoway (hist SCORE if INSPTYPE == "A" & post == 1 & SCORE <= 60 & SCORE > 0, ///
width(1) freq) ///
(line hat SCORE if INSPTYPE == "A" & post == 1 & score_uniq == 1 & SCORE <= 60 ///
& SCORE > 0)
*/

