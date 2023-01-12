********************************************************************************
********************************************************************************
**** State vs Local Tax Enforcement Effectiveness: Evidence from Airbnb Price Data 
**** By: Justin Ross, Whitney Afonso, Luis Navarro 
**** Last Update: Navarro, Luis 
********************************************************************************
********************************************************************************
// Regression Analysis - Monthly Data 
// Define the right subset for the analysis 
*- Exlcude 2020 from the analysis. We do not have LocalTaxRate Data for That. 
clear all 
global export replace width(1920) height(1080)
/// Loadl Monthly DataSet 
use "${ai}/ColoradoPropertyMonthlyMerge.dta", clear
label variable homerule_salestax "Local Sales Tax - HR Int"
label variable citytaxrate "Local Sales Tax"
label variable HomeRule "Home Rule"
label variable excisetax "Excise Taxes"
label variable excisetaxhr "Excise Taxes - HR Int"
label variable airbnbag "Airbnb Tax Collection Agreement"
sort id monthlydate
bysort id: egen sd = sd(citytaxrate) 
encode city, gen(city1)
table city1 date if sd > 0 , stat(mean citytaxrate) nformat(%12.2fc)
/// Gen Event Study Variables 
xtset id monthlydate 
sort id monthlydate
format monthlydate %tm_Mon_CCYY
/// Create Tax Rate Variable 
gen dltr = . 
/// Take the Difference in the Tax Rate if sd > 0 (i.e. if we noticed a change). This will create a vector if 0s with a positive number in the period when we observed the tax rate change 
bysort id: replace dltr = citytaxrate[_n] - citytaxrate[_n -1] if sd >0
/// Replace with zeros if we have missings in the initial spot 
replace dltr = 0 if dltr == . & sd > 0
/// Create an aux variable that is positive when we have a taxrate change 
bysort id: egen dltraux = mean(dltr) 
bysort id: replace dltraux = 0 if dltraux == . 
/// Create the et time variable. This will be the time index for the stacked dif-in-dif 
gen et = . 
/// Set the time counter equal to t=1 in the period after we observed the tax rate change 
bysort id: replace et = 1 if dltraux != 0 & dltr != 0 & sd > 0 
// Leads 
bysort id: replace et = 0 if et[_n+1] == 1 & sd > 0 
bysort id: replace et = -1 if et[_n+2] == 1 & sd > 0 
bysort id: replace et = -2 if et[_n+3] == 1 & sd > 0 
bysort id: replace et = -3 if et[_n+4] == 1 & sd > 0 
bysort id: replace et = -4 if et[_n+5] == 1 & sd > 0 
bysort id: replace et = -5 if et[_n+6] == 1 & sd > 0 
// Lags
bysort id: replace et = 2 if et[_n-1] == 1 & sd > 0 
bysort id: replace et = 3 if et[_n-2] == 1 & sd > 0 
bysort id: replace et = 4 if et[_n-3] == 1 & sd > 0 
bysort id: replace et = 5 if et[_n-4] == 1 & sd > 0 
// Fill missings for ids with tax rate changes. et = 10 means that you are a treated unit but outside the analysis horizon
bysort id: replace et = 10 if et == . & sd > 0 
/// Treatment ids dummy. This variable = 1 if the id experienced a tax rate change and zero otherwise. 
gen treated_all = . 
replace treated_all = 0 if et == . 
replace treated_all =1 if et != . 
label define treated 0 "Control" 1 "Treated"
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
table monthlydate et if et < 10 
********************************************************************************
/// Controls for PSM 
preserve 
import delimited "${bi}/us_Property_Match_2020-02-11.csv", varnames(1) clear 
keep propertyid propertytype bedrooms bathrooms maxguests airbnbsuperhost homeawaypremierpartner cancellationpolicy securitydepositusd cleaningfeeusd extrapeoplefeeusd publishednightlyrateusd minimumstay numberofreviews numberofphotos overallrating instantbookenabled airbnbhostid
save "${bt}/propertyid_synthcontrols.dta", replace 
restore 

********************************************************************************
/// Create Treatment Groups for Stacking 
/// 1. Create dummies for each date. 
tab monthlydate if et == 0, gen(treatgroup)
/// most of the observations come from december 2018 (this should be the time when denver changed)
forvalues i=1(1)3{
bysort id: egen treat`i' = mean(treatgroup`i')	
}

tabulate city1 treat1 
tabulate city1 treat2 
tabulate city1 treat3 

/// Split the datasets. 
/// First the Treatment Groups 
forvalues i=1(1)3{
preserve
keep if treat`i' == 1
drop if et == 10 
save "${at}/StackedDID_Treatment`i'.dta", replace
restore 
}

/// Now we will create the control groups 
/// Time Periods Definitions 
/// Group 1 (Dec2017) = -5,5 --> Jul2017 - May2018
/// Group 2 (Jun2018) = -5,5 --> Jan2018 - Nov2018
/// Group 3 (Dec2018) = -5,5 --> Jul2018 - May2019

tabulate city1 if treat1 == 1 | treat2 == 1 | treat3 == 1, sort
tabulate city1 if treat1 == 0 | treat2 == 0 | treat3 == 0, sort  

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


/// Now do the analysis 
/// First at each group 
forvalues i=1(1)3{
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
}



/*
/// Merge Controls 
use "${at}/StackedDID_Treatment1.dta", clear
append using "${at}/StackedDID_Control1.dta"
order id et monthlydate treated_all treat1 citytaxrate 
sort id et 
xtset id et 
tab et treat1
gen post = 0 
replace post = 1 if et > 0 
bysort id: egen treatment1 = max(dltraux)
gen didint1 = treatment1*post 	
bysort id: gen treat_dum1 = 0 
bysort id: replace treat_dum1 = 1 if treatment1 != 0  
gen did1 = treat_dum1*post 
/// Merge Controls for Propensity Score 
merge m:1 propertyid using "${bt}/propertyid_synthcontrols.dta", keep(match master) nogen
mdesc treat_dum1 
tab treat_dum1 
encode airbnbsuperhost, gen(superhost)
/// Treated All is a binary outcome that equals one if unit_i was in a city that experienced a tax rate change 
/// We want to estimate the probability of that, conditional on unit characteristics. 
//// Estimate Propensity Score 
logit treat_dum1 bedrooms bathrooms maxguests numberofphotos superhost, robust
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

save "${at}/StackedDID_TreatControl`i'.dta", replace 





// Donors 


preserve 
use "${bt}/PSM_Treated.dta", clear
*sample size is 1604
forval i = 1/1604 {
	preserve 
	drop if n!=`i' 
	drop n
	append using "${bt}/PSM_Donors.dta"
	generate absdiff=abs(phat-phat[1])
	egen diffrank=rank(absdiff), unique
	drop if diffrank>6
	keep propid phat
	save "${bt}/StackedDIDpmatch`i'.dta", replace
	restore
}
restore 


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
*/
************************************************************************************
global regopts absorb(id et) vce(cluster city1)
global outcome totaldays reservationdays 
global events event1 event2 event3 event4 event5 event7 event8 event9 event10 event11
global pretrends event1 event2 event3 event4 event5
global events_int event_int1 event_int2 event_int3 event_int4 event_int5 event_int7 event_int8 event_int9 event_int10 event_int11
global pretrends_int event_int1 event_int2 event_int3 event_int4 event_int5
global event_opts vertical yline(0, lpattern(dash) lcolor(maroon)) ylabel(#8, labsize(small) angle(0)) xlabel(, labsize(small) angle(0)) xtitle("Months Before the Tax Change", size(small)) xline(5.5, lcolor(maroon) lpattern(dash) lwidth(thin)) mcolor(black) msize(small) msymbol(circle) lcolor(black) lwidth(thin) lpattern(solid) ciopts(lcolor(black) recast(rcap))

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
coefplot totaldays_es`j', $event_opts keep($events) title("Listed Days - Experiment `j'", pos(11) size(small)) name(totaldays_es`j', replace) 
*text(-0.8 8.0 "Pre-Trends F-Test: ${totaldays`j'a}", place(e) size(small))
coefplot reservationdays_es`j', $event_opts keep($events) title("Booked Days - Experiment `j'", pos(11) size(small)) name(reservationdays_es`j', replace) 
*text(-0.08 8.0 "Pre-Trends F-Test: ${reservationdays`j'a}", place(e) size(small))
/// Continuous Treatment 
coefplot totaldays_es_int`j', $event_opts keep($events_int) title("Listed Days - Continuous Treatment - Experiment `j'", pos(11) size(small)) name(totaldays_es_int`j', replace) 
coefplot reservationdays_es_int`j', $event_opts keep($events_int) title("Booked Days - Continuous Treatment - Experiment `j'", pos(11) size(small)) name(reservationdays_es_int`j', replace) 
}
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
coefplot totaldays_es`j', $event_opts keep($events) title("Listed Days - Experiment `j'", pos(11) size(small)) name(totaldays_es`j', replace) 
coefplot reservationdays_es`j', $event_opts keep($events) title("Booked Days - Experiment `j'", pos(11) size(small)) name(reservationdays_es`j', replace) 
/// Continuous Treatment 
coefplot totaldays_es_int`j', $event_opts keep($events_int) title("Listed Days - Continuous Treatment - Experiment `j'", pos(11) size(small)) name(totaldays_es_int`j', replace) 
coefplot reservationdays_es_int`j', $event_opts keep($events_int) title("Booked Days - Continuous Treatment - Experiment `j'", pos(11) size(small)) name(reservationdays_es_int`j', replace) 
}


coefplot totaldays_es_all, $event_opts keep($events)  title("Listed Days", pos(11) size(small)) name(totaldays_es_all, replace) 
coefplot reservationdays_es_all, $event_opts keep($events)  title("Booked Days", pos(11) size(small)) name(reservationdays_es_all, replace) 

graph combine totaldays_es1 totaldays_es2 totaldays_es3 totaldays_es_all, rows(2) cols(2) name(totaldays_combined, replace)
graph export "${ao}/Stacked_Event_TotalDays.png", ${export}

graph combine reservationdays_es1 reservationdays_es2 reservationdays_es3 reservationdays_es_all, rows(2) cols(2) name(reservationdays_combined, replace)
graph export "${ao}/Stacked_Event_ReservationDays.png", ${export}

/// Continuous Treatment 
coefplot totaldays_es_int_all, $event_opts keep($events_int)  title("Listed Days", pos(11) size(small)) name(totaldays_es_int_all, replace) 
graph export "${ao}/Stacked_Event_ListedDays.png", ${export}

coefplot reservationdays_es_int_all, $event_opts keep($events_int)  title("Booked Days", pos(11) size(small)) name(reservationdays_es_int_all, replace) 
graph export "${ao}/Stacked_Event_BookedDays.png", ${export}


graph combine totaldays_es_int1 totaldays_es_int2 totaldays_es_int3 totaldays_es_int_all, rows(2) cols(2) name(totaldays_int_combined, replace)
graph export "${ao}/Stacked_Event_Int_TotalDays.png", ${export}

graph combine reservationdays_es_int1 reservationdays_es_int2 reservationdays_es_int3 reservationdays_es_int_all, rows(2) cols(2) name(reservationdays_int_combined, replace)
graph export "${ao}/Stacked_Event_Int_ReservationDays.png", ${export}

graph combine totaldays_es_all reservationdays_es_all, rows(2) name(event_binary, replace) xcommon
graph export "${ao}/Stacked_Event_Combined_Binary.png", ${export}

graph combine totaldays_es_int_all reservationdays_es_int_all, rows(2) name(event_continuous, replace) xcommon
graph export "${ao}/Stacked_Event_Combined_Continous.png", ${export}
