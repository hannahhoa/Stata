** Author: Hannah Nguyen				**
** Email: hannah.works.au@gmail.com		**
** Copy right 2025						**
******************************************

** About data: HILDA
* Raw data file name "Combined_v220u" (Wave 22). Variables:
* id: person's id
* alcohol: how much of weekly expenses were spent on alcohol?
* cigs: how much of weekly expenses were spent on cigarettes and other tobacco products?
* children: How many children do you have? Please only include natural and adopted children; not step or foster children.
* genderD
* age: age last birthday at June 30 2022
* hh_wk_inc: household current weekly gross wages and salary from all jobs. lnhh_wk_inc is hh_wk_inc in logarithm.
* healthissueD: whether having any long term health condition, disability or imparement
* workedD: At any time at all during the last 7 days, did you do any work in a job, business or farm?


clear all
set more off
set maxvar 10000

*** 1. Import and clean data
{
	local dir `c(pwd)'
	use Combined_v220u.dta

	keep xwaveid vxpalca vxpciga vscgndr vhiwsces vhglth vhgage vtchave vesjlw vhhstate

	rename (xwaveid vxpalca vxpciga vscgndr vhiwsces vhglth vhgage vtchave vesjlw vhhstate) (id alcohol cigs genderD hh_wk_inc healthissueD age children workedD state)

	replace genderD=0 if genderD==2
	replace genderD=. if genderD<0 | genderD>2

	replace healthissueD=0 if healthissueD==2
	replace healthissueD=. if healthissueD<0

	replace workedD=0 if workedD==2
	replace workedD=. if workedD<0

	replace children=. if children<0
	replace alcohol=. if alcohol<0
	replace cigs=. if cigs<0

	drop if hh_wk_inc==. | age==. | healthissueD==. | workedD==. | children==. | alcohol==. | cigs==. | genderD==.

	foreach v in hh_wk_inc alcohol cigs {
		gen ln`v'=ln(`v'+0.000000000001)
	}
	gen age2 = age*age

	save cigs_alc_children.dta, replace
}

	
	
*** 2. Summary statistics
* Sample: 44% men, 50 years old on average,27% having long term health condition,  38% not working in the last 7 days, 1.7 children on average. Average weekly income is $1933 with $33 on alcohol and $17 on cigs.

foreach v in genderD workedD healthissueD state {
	tab `v'
}

sum age hh_wk_inc alcohol cigs


*** 3. Regressions
use cigs_alc_children.dta, replace

gl y1list lnalcohol
gl y2list lncigs
gl xlist children age age2 i.genderD i.workedD i.healthissueD lnhh_wk_inc i.state

* Create temporary files to store outputs
tempfile ols_y1 ols_y2 sur_out combined


* OLS
reg $y1list $xlist, r
parmest, label saving("`ols_y1'", replace)
reg $y2list $xlist, r
parmest, label saving("`ols_y2'", replace)

* SUR
sureg ($y1list $xlist) ($y2list $xlist), corr vce(r)
parmest, label saving("`sur_out'", replace)

* Test cross-equation constraints
test [$y1list]children= [$y2list]children

* Combine all regression results
use `ols_y1', clear
gen model = "OLS: lnalcohol"
append using `ols_y2'
replace model = "OLS: lncigs" if model == ""
append using `sur_out'
replace model = "SUR" if model == ""

format estimate %9.3f

* Save the combined dataset
save combined_results.dta, replace


*** End