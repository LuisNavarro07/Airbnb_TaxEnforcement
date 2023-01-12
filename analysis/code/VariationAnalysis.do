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

/// Create Treatment Groups for Stacking 
/// 1. Create dummies for each date. 
tab monthlydate if et == 0, gen(treatgroup)
/// most of the observations come from december 2018 (this should be the time when denver changed)
forvalues i=1(1)3{
bysort id: egen treat`i' = mean(treatgroup`i')	
}

/// Split the datasets. 
/// First the Treatment Groups 
forvalues i=1(1)3{
preserve
keep if treat`i' == 1
drop if et == 10 
save "${at}/StackedDID_Treatment`i'.dta", replace
restore 
}

/// Time Periods Definitions 
/// Group 1 (Dec2017) = -5,5 --> Jul2017 - May2018
/// Group 2 (Jun2018) = -5,5 --> Jan2018 - Nov2018
/// Group 3 (Dec2018) = -5,5 --> Jul2018 - May2019

/// Treatment Variable Filling 



bysort id: egen mtax = mean(dltr) if et == 1

gen eventdum = et < 10
bysort id: carryforward mtax if eventdum == 1, replace 
bysort id: replace mtax = 0 if et < 1 
drop dltr 
rename mtax dltr 

table city1 et if et < 10, statistic(mean citytaxrate)



// Dummy equal to one for variables with tax rate change 
global conditional eventdum == 1 & modelmiss == 0
tab et if $conditional
tab et if $conditional, gen(timedum)
local t = -5
forvalues i=1(1)11{
	gen event`i' = (timedum`i'*dltr*HomeRule) if eventdum == 1 & modelmiss == 0 
	label variable event`i' "`t'"
	local t = `t' + 1
}


/// Model Definition 
global regopts absorb(propertyid listingtype monthlydate) vce(cluster city)
global outcome revenueperday totaldays reservationdays 
global events event1 event2 event3 event4 event5 event7 event8 event9 event10 event11

local varlist $outcome 
foreach var of local varlist {
gen log`var'=ln(`var')
global model log`var' $events HomeRule airbnbag excisetax
reghdfe $model if ${conditional}, ${regopts}
estimates store `var'	
drop log`var'
}

coefplot revenueperday, vertical keep($events) xline(0, lpattern(dash) lcolor(black)) yline(0, lpattern(dash) lcolor(black)) title("Average Daily Revenue", pos(11) size(small)) name(revenueperday, replace)
