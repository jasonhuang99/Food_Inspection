set more off

cd "~/Desktop/NYC Food Inspection/Data/DTA/JPMC"

use days_grade.dta, clear
sort id trans_date
save days_grade.dta, replace

use 100.dta, clear
append using 103.dta
append using 104.dta
append using 110.dta
append using 111.dta
append using 112.dta
append using 113.dta
append using 114.dta

sort id trans_date

merge id trans_date using days_grade.dta
//drop if daily_rev_x == .

gen grade = "A" if visible_score >= 0 & visible_score <= 13
replace grade = "P" if visible_score < 0
replace grade = "B" if visible_score >= 14 & visible_score <= 27
replace grade = "C" if visible_score > 27 & visible_score != .


encode grade, gen(grade_enc)
drop grade
rename grade_enc grade

sort id trans_date, stable
by id: replace grade = grade[_n - 1] if grade == .

gen log_rev = log(daily_rev_x)
gen log_trans = log(daily_trans_x)

local table_path ///
"~/Dropbox/Research Ideas/Food Inspection Scores/JPMC/Tex/Tables/"

qui: reghdfe log_rev i.grade, absorb(id trans_date DayOWeek id#DayOWeek) cluster(zipcode)

outreg2 using "`table_path'grade.tex", ///
replace label ctitle("log(daily revenue)") tex(frag)

qui: reghdfe log_trans i.grade, absorb(id trans_date DayOWeek id#DayOWeek) cluster(zipcode)
outreg2 using "`table_path'grade.tex", append label ///
ctitle("log(daily transaction volume)") tex(frag)

foreach g in 2 3 4 {
	local label_`g' ///
	`g'.grade_lag_5 = "t - 5" `g'.grade_lag_10 = "t - 10" ///
	`g'.grade_lag_15 = "t - 15" `g'.grade_lag_20 = "t - 20" ///
	`g'.grade_lag_25 = "t - 25" `g'.grade_lag_30 = "t - 30" ///
	`g'.grade_lag_60 = "t - 60" `g'.grade_lag_90 = "t - 90" ///
	`g'.grade = "0" ///
	`g'.grade_lead_5 = "t + 5" `g'.grade_lead_10 = "t + 10" ///
	`g'.grade_lead_15 = "t + 15" `g'.grade_lead_20 = "t + 20" ///
	`g'.grade_lead_25 = "t + 25" `g'.grade_lead_30 = "t + 30" ///
	`g'.grade_lead_60 = "t + 60" `g'.grade_lead_90 = "t + 90" 
}

local figure_path ///
"~/Dropbox/Research Ideas/Food Inspection Scores/JPMC/Tex/Figures/"

sort id trans_date, stable

label define grade_val 1 "A" 2 "B" 3 "C" 4 "P"
foreach l in 5 10 15 20 25 30 60 90 {
	by id: gen grade_lag_`l' = grade[_n - `l']
	label variable grade_lag_`l' "t - `l'"
	label value grade_lag_`l' grade_val
	by id: gen grade_lead_`l' = grade[_n + `l']
	label variable grade_lead_`l' "t + `l'"
	label value grade_lead_`l' grade_val
}

qui: reghdfe log_rev ///
i.grade_lead_30 i.grade_lead_25 i.grade_lead_20 i.grade_lead_15 i.grade_lead_10 i.grade_lead_5 ///
i.grade ///
i.grade_lag_5 i.grade_lag_10 i.grade_lag_15 i.grade_lag_20 i.grade_lag_25 i.grade_lag_30, ///
absorb(id trans_date) cluster(zipcode)

foreach g in 2 3 4 {
	if `g' == 2 {
		local grade "B"
	}
	if `g' == 3 {
		local grade "C"
	}
	if `g' == 4 {
		local grade "P"
	}
	coefplot, vertical keep(`g'.*) coeflabel(`label_`g'') ///
	xlabel(,angle(vertical)) title("Dynamic Impact of `grade' on Log(Daily Revenue)") ///
	graphregion(color(white))
	graph export "`figure_path'log_rev`grade'.png", replace
}

qui: reghdfe log_trans ///
i.grade_lead_30 i.grade_lead_25 i.grade_lead_20 i.grade_lead_15 i.grade_lead_10 i.grade_lead_5 ///
i.grade ///
i.grade_lag_5 i.grade_lag_10 i.grade_lag_15 i.grade_lag_20 i.grade_lag_25 i.grade_lag_30, ///
absorb(id trans_date) cluster(zipcode)

foreach g in 2 3 4 {
	if `g' == 2 {
		local grade "B"
	}
	if `g' == 3 {
		local grade "C"
	}
	if `g' == 4 {
		local grade "P"
	}
	coefplot, vertical keep(`g'.*) coeflabel(`label_`g'') ///
	xlabel(,angle(vertical)) title("Dynamic Impact of `grade' on Log(Transaction Volume)") ///
	graphregion(color(white))
	graph export "`figure_path'log_trans`grade'.png", replace
}

qui: reghdfe log_trans ///
i.grade_lead_90 i.grade_lead_60 i.grade_lead_30  ///
i.grade ///
i.grade_lag_30 i.grade_lag_60 i.grade_lag_90, ///
absorb(id trans_date) cluster(zipcode)
	
foreach g in 2 3 4 {
	if `g' == 2 {
		local grade "B"
	}
	if `g' == 3 {
		local grade "C"
	}
	if `g' == 4 {
		local grade "P"
	}
	coefplot, vertical keep(`g'.*) coeflabel(`label_`g'') ///
	xlabel(,angle(vertical)) title("Dynamic Impact of `grade' on Log(Transaction Volume)") ///
	graphregion(color(white))
	graph export "`figure_path'log_trans`grade'_long.png", replace
}

qui: reghdfe log_rev ///
i.grade_lead_90 i.grade_lead_60 i.grade_lead_30  ///
i.grade ///
i.grade_lag_30 i.grade_lag_60 i.grade_lag_90, ///
absorb(id trans_date) cluster(zipcode)

foreach g in 2 3 4 {
	if `g' == 2 {
		local grade "B"
	}
	if `g' == 3 {
		local grade "C"
	}
	if `g' == 4 {
		local grade "P"
	}
	coefplot, vertical keep(`g'.*) coeflabel(`label_`g'') ///
	xlabel(,angle(vertical)) title("Dynamic Impact of `grade' on Log(Revenue)") ///
	graphregion(color(white))
	graph export "`figure_path'log_rev`grade'_long.png", replace
}

