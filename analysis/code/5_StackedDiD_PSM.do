
/// Treatment ids dummy. This variable = 1 if the id experienced a tax rate change and zero otherwise. 
 

label values treated_all treated 




/// Now we need to form the date blocks. We should have three big date blocks. Changes in 2017q4, 2018q2, 2018q4
/// As we can see we have some ids with sd > 0 but observing changes in other periods. This could only be explained by unbalanced panel problems. Example, if you stop being listed for x months and appear after a tax rate change, sd > 0 but we will be missing such observations. 
tab monthlydate if et == 0, sort 
/// The previous thing should not happen. We must have only observations at december or june. Not at the other months.   
table monthlydate et if et < 10 
/// Assumption 1: exclude the ones from which we have an unbalanced panel 
gen exc = . 
replace exc = 0 if sd > 0  
replace exc = 1 if monthlydate == tm(2017m12) & et == 0 & sd > 0 
replace exc = 1 if monthlydate == tm(2018m6) & et == 0 & sd > 0 
replace exc = 1 if monthlydate == tm(2018m12) & et == 0 & sd > 0 
bysort id: egen excmean = mean(exc)  
/// Drop ids with tax changes that do not align with the tax calendar -- 5097 obs 
drop if excmean == 0  
/// Now the DataSet is more balanced 
tab monthlydate if et == 0 
tab et if et < 10
/// Assumption: Only keep observations within the window analysis 
drop if et == 10
********************************************************************************

********************************************************************************
/// Create Treatment Groups for Stacking 
/// 1. Create dummies for each date. 
tab monthlydate if et == 0, gen(treatgroup)
/// most of the observations come from december 2018 (this should be the time when denver changed)
forvalues i=1(1)3{
bysort id: egen treat`i' = mean(treatgroup`i')
drop treatgroup`i'	
}
/// Split the datasets. 
/// First the Treatment Groups 
forvalues i=1(1)3{
preserve
keep if treat`i' == 1 
save "${at}/StackedDID_Treatment`i'.dta", replace
restore 
}
/// Now we will create the control groups 
/// Time Periods Definitions 
/// Group 1 (Dec2017) = -5,5 --> Jul2017 - May2018
/// Group 2 (Jun2018) = -5,5 --> Jan2018 - Nov2018
/// Group 3 (Dec2018) = -5,5 --> Jul2018 - May2019
/// Keep only control units 
drop if treated_all == 1 
replace dltr = 0 
/// All control units during the analysis horizon 
replace treat1 = 0 if monthlydate > tm(2017m6) & monthlydate < tm(2018m6)
replace treat2 = 0 if monthlydate > tm(2017m12) & monthlydate < tm(2018m12)
replace treat3 = 0 if monthlydate > tm(2018m6) & monthlydate < tm(2019m6)
/// Control Groups Definitions 
global control1 monthlydate == tm(2018m1) 
global control2 monthlydate == tm(2018m7) 
global control3 monthlydate == tm(2019m1) 
/// Create the Control Groups for all three treatment groups 
forvalues i=1(1)3{
preserve
keep if treat`i' == 0
bysort id: replace et = 1 if ${control`i'}
// Leads 
bysort id: replace et = 0 if et[_n+1] == 1
bysort id: replace et = -1 if et[_n+2] == 1 
bysort id: replace et = -2 if et[_n+3] == 1
bysort id: replace et = -3 if et[_n+4] == 1 
bysort id: replace et = -4 if et[_n+5] == 1 
bysort id: replace et = -5 if et[_n+6] == 1
// Lags
bysort id: replace et = 2 if et[_n-1] == 1 
bysort id: replace et = 3 if et[_n-2] == 1
bysort id: replace et = 4 if et[_n-3] == 1 
bysort id: replace et = 5 if et[_n-4] == 1 
drop if et == . 
table monthlydate et 
save "${at}/StackedDID_Control`i'.dta", replace
restore 
}

********************************************************************************
/// Now do the analysis 
/// First at each group 
forvalues i=1(1)1{
use "${at}/StackedDID_Treatment`i'.dta", clear
append using "${at}/StackedDID_Control`i'.dta"
order id et monthlydate treated_all treat`i' citytaxrate 
sort id et 
xtset id et 
tab et treat`i'
gen post = 0 
replace post = 1 if et > 0 
bysort id: egen treatment`i' = max(dltraux)
gen didint`i' = treatment`i'*post 	
bysort id: gen treat_dum`i' = 0 
bysort id: replace treat_dum`i' = 1 if treatment`i' != 0  
gen did`i' = treat_dum`i'*post 
save "${at}/StackedDID_TreatControl`i'.dta", replace 
/// Merge Controls for Propensity Score 
merge m:1 propertyid using "${bt}/propertyid_synthcontrols.dta", keep(match master) nogen
mdesc treat_dum`i' 
tab treat_dum`i' 
encode airbnbsuperhost, gen(superhost)
/// Treated All is a binary outcome that equals one if unit_i was in a city that experienced a tax rate change 
/// We want to estimate the probability of that, conditional on unit characteristics. 
//// Estimate Propensity Score 
logit treat_dum`i' bedrooms maxguests numberofphotos superhost, robust
estimates store pscorelogit`i' 
predict phat
generate inverse=1/phat
drop if missing(phat)
/// Keep Donors and Treated 
preserve 
keep if treated_all == 0 
save "${bt}/PSM_Donors`i'.dta", replace 
restore 
/// Treated 
preserve 
keep if treated_all == 1 
generate n=_n
save "${bt}/PSM_Treated`i'.dta", replace 
restore
// use treated dataset 
use "${bt}/PSM_Treated`i'.dta", clear 
/*
/// Nearest Neighbor Matching
global obs = _N
forvalues j=1(1)$obs {
	preserve 
	drop if n!=`j' 
	drop n
	append using "${bt}/PSM_Donors`i'.dta"
	generate absdiff=abs(phat-phat[1])
	egen diffrank=rank(absdiff), unique
	drop if diffrank>6
	keep propid phat
	save "${bt}/PSM`i'_pmatch`j'.dta", replace
	restore
}
*/
save "${at}/StackedDID_TreatControl`i'.dta", replace 
// Donors 
/* Nearest Neighbor Matching 
preserve 
use "${bt}/PSM_Treated`i'.dta", clear
*sample size is 1604
forvalues j=1(1)$obs{
	preserve 
	drop if n!=`j' 
	drop n
	append using "${bt}/PSM_Donors`i'.dta"
	generate absdiff=abs(phat-phat[1])
	egen diffrank=rank(absdiff), unique
	drop if diffrank>6
	keep propid phat
	save "${bt}/StackedDID`i'_pmatch`j'.dta", replace
	restore
}
restore 
*/
}

********************************************************************************
/*start substacks loop
foreach city 1 to n in treatment 1.dta{
	preserve
	drop if cityid not equal i & treat1==1
	generate substackid
	save substackgroup
	restore
}
REPEAT FOR TREAT GROUPS 2 and 3
Append all substacks
add dummy for each substack (substack fe)
*/

************************************************************************************
global regopts absorb(id et) vce(cluster city1)
global outcome totaldays reservationdays 
global events event1 event2 event3 event4 event5 event7 event8 event9 event10 event11
global pretrends event1 event2 event3 event4 event5
global events_int event_int1 event_int2 event_int3 event_int4 event_int5 event_int7 event_int8 event_int9 event_int10 event_int11
global pretrends_int event_int1 event_int2 event_int3 event_int4 event_int5
global event_opts vertical yline(0, lpattern(dash) lcolor(maroon)) ylabel(#8, labsize(small) angle(0)) xlabel(, labsize(small) angle(0)) xtitle("Months Before the Tax Change", size(small)) xline(5.5, lcolor(maroon) lpattern(dash) lwidth(thin)) mcolor(black) msize(small) msymbol(circle) lcolor(black) lwidth(thin) lpattern(solid) ciopts(lcolor(black) recast(rcap))

global title1 "December 2017"
global title2 "June 2018"
global title3 "December 2018"
// For Each Group 
forvalues j=1(1)3{
use "${at}/StackedDID_TreatControl`j'.dta", clear 
/// Event Study Variable Creation
tab et, gen(timedum)
local t = -5
forvalues i=1(1)11{
	gen event`i' = (timedum`i'*treat_dum`j') if modelmiss == 0 
	gen event_int`i' = timedum`i'*treatment`j' if modelmiss == 0 
	label variable event`i' "`t'"
	label variable event_int`i' "`t'"
	local t = `t' + 1
}
/// Model Definition 
local varlist $outcome 
foreach var of local varlist {
gen log`var'=ln(`var')
/// Generalized DiD for Test
*reghdfe log`var' did`j' excisetax if modelmiss == 0 , ${regopts}
*estimates store `var'_did`j' 
/// Event Study - Binary Treatment 
reghdfe log`var' $events excisetax if modelmiss == 0 , ${regopts}
estimates store `var'_es`j'	
test $pretrends
global `var'`j'a = round(r(p),0.0001)
/// Event Study - Continuous Treatment 
reghdfe log`var' $events_int excisetax if modelmiss == 0 , ${regopts}
estimates store `var'_es_int`j'	
test $pretrends_int
global `var'`j'b = round(r(p),0.0001)
drop log`var'
}
/// Binary Treatment 
coefplot totaldays_es`j', $event_opts keep($events) title("Listed Days - ${title`j'}", pos(11) size(small)) name(totaldays_es`j', replace) 
coefplot reservationdays_es`j', $event_opts keep($events) title("Booked Days -  ${title`j'}", pos(11) size(small)) name(reservationdays_es`j', replace) 
/// Continuous Treatment 
coefplot totaldays_es_int`j', $event_opts keep($events_int) title("Listed Days - ${title`j'}", pos(11) size(small)) name(totaldays_es_int`j', replace) 
coefplot reservationdays_es_int`j', $event_opts keep($events_int) title("Booked Days - ${title`j'}", pos(11) size(small)) name(reservationdays_es_int`j', replace) 
}

graph combine totaldays_es_int1 totaldays_es_int2 totaldays_es_int3 reservationdays_es_int1 reservationdays_es_int2 reservationdays_es_int3, rows(2) cols(3) xcommon name(combinedevents, replace)
graph export "${ao}/EventsCombined.png", ${export}

*******************************************************************************

/// STACKED DID 
/// Create Dataset 
use "${at}/StackedDID_TreatControl1.dta", clear 
forvalues j=2(1)3{
append using "${at}/StackedDID_TreatControl`j'.dta" 
}
/// New DID Variables 
/// Stacked Treatment Variable 
mdesc treat_dum*
forvalues i=1(1)3{
	tab treat_dum`i'
}
gen treat_all = .
replace treat_all = 0 if treat_dum1 == 0 | treat_dum2 == 0 | treat_dum3 == 0 
replace treat_all = 1 if treat_dum1 == 1 | treat_dum2 == 1 | treat_dum3 == 1 
tab treat_all 
mdesc treat_all
/// Continuous
gen treat_int_all = 0
replace treat_int_all = dltraux if treat_dum1 == 1 | treat_dum2 == 1 | treat_dum3 == 1 
tab treat_int_all 
/// Substack Fixed Effects 
gen expgroup = 0 
forvalues i=1(1)3{
replace expgroup = `i' if treat_dum`i' != . 
}
tab expgroup
/// Create Event Study Variables
tab et, gen(timedum)
local t = -5
forvalues i=1(1)11{
	gen event`i' = (timedum`i'*treat_all) if modelmiss == 0 
	gen event_int`i' = timedum`i'*treat_int_all if modelmiss == 0 
	label variable event`i' "`t'"
	label variable event_int`i' "`t'"
	local t = `t' + 1
}
/// Run Regression 
global regopts absorb(id et expgroup) vce(cluster city1)
local varlist $outcome 
foreach var of local varlist {
gen log`var'=ln(`var')
/// Generalized DiD for Test
/// Event Study - Binary Treatment 
reghdfe log`var' $events excisetax if modelmiss == 0 , ${regopts}
estimates store `var'_es_all
test $pretrends
global `var'`j'a = round(r(p),0.0001)
/// Event Study - Continuous Treatment 
reghdfe log`var' $events_int excisetax if modelmiss == 0 , ${regopts}
estimates store `var'_es_int_all
test $pretrends_int
global `var'`j'b = round(r(p),0.0001)
drop log`var'
}

forvalues j=1(1)3{
/// Binary Treatment 
coefplot totaldays_es`j', $event_opts keep($events) title("Listed Days -  ${title`j'}", pos(11) size(small)) name(totaldays_es`j', replace) 
coefplot reservationdays_es`j', $event_opts keep($events) title("Booked Days -  ${title`j'}", pos(11) size(small)) name(reservationdays_es`j', replace) 
/// Continuous Treatment 
coefplot totaldays_es_int`j', $event_opts keep($events_int) title("Listed Days -  ${title`j'}", pos(11) size(small)) name(totaldays_es_int`j', replace) 
coefplot reservationdays_es_int`j', $event_opts keep($events_int) title("Booked Days - ${title`j'}", pos(11) size(small)) name(reservationdays_es_int`j', replace) 
}


coefplot totaldays_es_all, $event_opts keep($events)  title("Listed Days - Binary", pos(11) size(small)) name(totaldays_es_all, replace) 
coefplot reservationdays_es_all, $event_opts keep($events)  title("Booked Days - Binary", pos(11) size(small)) name(reservationdays_es_all, replace) 

/// Continuous Treatment 
coefplot totaldays_es_int_all, $event_opts keep($events_int)  title("Listed Days - Continuous", pos(11) size(small)) name(totaldays_es_int_all, replace) 
coefplot reservationdays_es_int_all, $event_opts keep($events_int)  title("Booked Days - Continuous", pos(11) size(small)) name(reservationdays_es_int_all, replace) 

/// Export Stacked 
graph combine totaldays_es_all reservationdays_es_all, rows(2) name(event_binary, replace) xcommon
graph export "${ao}/Stacked_Event_Combined_Binary.png", ${export}

graph combine totaldays_es_int_all reservationdays_es_int_all, rows(2) name(event_continuous, replace) xcommon
graph export "${ao}/Stacked_Event_Combined_Continous.png", ${export}

graph combine totaldays_es_all reservationdays_es_all totaldays_es_int_all reservationdays_es_int_all, rows(2) cols(2) name(event_combined, replace) xcommon
graph export "${ao}/Stacked_Event_Combined_All.png", ${export}



// Export all Graphs 
graph combine totaldays_es1 totaldays_es2 totaldays_es3 totaldays_es_all, rows(2) cols(2) name(totaldays_combined, replace)
graph export "${ao}/Stacked_Event_TotalDays.png", ${export}

graph combine reservationdays_es1 reservationdays_es2 reservationdays_es3 reservationdays_es_all, rows(2) cols(2) name(reservationdays_combined, replace)
graph export "${ao}/Stacked_Event_ReservationDays.png", ${export}



graph combine totaldays_es_int1 totaldays_es_int2 totaldays_es_int3 totaldays_es_int_all, rows(2) cols(2) name(totaldays_int_combined, replace)
graph export "${ao}/Stacked_Event_Int_TotalDays.png", ${export}

graph combine reservationdays_es_int1 reservationdays_es_int2 reservationdays_es_int3 reservationdays_es_int_all, rows(2) cols(2) name(reservationdays_int_combined, replace)
graph export "${ao}/Stacked_Event_Int_ReservationDays.png", ${export}

