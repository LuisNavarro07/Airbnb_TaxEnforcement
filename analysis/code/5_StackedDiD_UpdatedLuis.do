********************************************************************************
********************************************************************************
**** State vs Local Tax Enforcement Effectiveness: Evidence from Airbnb Price Data 
**** By: Justin Ross, Whitney Afonso, Luis Navarro 
**** Last Update: Navarro, Luis 
********************************************************************************
********************************************************************************
// Constant Elasticity Assumption
clear all 
global export replace width(1920) height(1080)


log using "${ao}/log5stacked.log", replace 
********************************************************************************
/// First identify the cities that had a tax rate change at some point in the sample. 
/// Load the Tax Dataset 
use "${bt}/ColoradoSalesTaxClean.dta", clear
// Generate Unique Ids for City County (this accounts for cities that are different counties)
egen citycounty = group(city FIPS)
duplicates report citycounty date 
/// Just keep tax rates 
collapse (mean) citytaxrate (first) city FIPS, by(citycounty date)
sort citycounty date 
xtset citycounty date 
/// Rectangularize the Dataset 
fillin citycounty date 
xfill city FIPS 
/// Identify missings and drop them 
bysort citycounty: egen filldum = mean(_fillin)
tab city if filldum > 0 
drop if filldum > 0 
/// Now this is strongly balanced
xtset citycounty date 
drop _fillin filldum 
/// We need to identify the cities that observed a change in their tax rate, so we took the standard deviation of the tax rates. In this case, if the sd > 0, then it must be the case that a change in the tax rate happened at some moment. 
bysort citycounty: egen sd = sd(citytaxrate)
gen sd_dum = sd > 0 
tab sd_dum 
/// We have 18 cities that had tax changes 
tab city if sd_dum == 1, sort 
/// Now identify in which moment they changed their taxrate 
table citycounty date if sd_dum == 1, stat(mean citytaxrate)
/// Calculate the tax change 
bysort citycounty: gen deltatax = citytaxrate[_n] - citytaxrate[_n-1]
replace deltatax = 0 if deltatax == . 
/// dummy equal to one when the tax change happens
gen delta_dum = deltatax > 0 
tab date delta_dum 
tab citycounty date if delta_dum == 1
tab date, gen(dated)
/// Create Treatment Variables for Each SubExperiment. In this case, expj_treated == 1 for any city that experienced a tax rate change in subexperiment j. 
forvalues j =3(1)5{
gen treat_tot = 0 
tab citycounty if dated`j' == 1 & delta_dum == 1, gen(treat)
global tot = r(r)
forvalues i=1(1)$tot {
	replace treat`i' = 0 if treat`i' == . 
	replace treat_tot = treat_tot + treat`i'
}
bysort citycounty: egen exp`j'_treated = mean(treat_tot)
bysort citycounty: replace exp`j'_treated = exp`j'_treated > 0 
tab citycounty exp`j'_treated
drop treat*
}
/// Save
drop dated* 
save "${bt}\taxrates_changes.dta", replace 

******************************************************
/// Loadl Monthly DataSet 
use "${ai}/ColoradoPropertyMonthlyMerge.dta", clear
label variable homerule_salestax "Local Sales Tax - HR Int"
label variable citytaxrate "Local Sales Tax"
label variable HomeRule "Home Rule"
label variable excisetax "Excise Taxes"
label variable excisetaxhr "Excise Taxes - HR Int"
label variable airbnbag "Airbnb Tax Collection Agreement"
sort id monthlydate
drop _merge 
drop cityid
/// Merge the Results 
merge m:1 city FIPS date using "${bt}\taxrates_changes.dta", keep(match master) nogen 
/// Missings are Zero (i.e. they do not experience a tax change)
replace sd_dum = 0 if sd_dum == . 
drop citycounty
gen citycounty = city + " - " + County 
encode citycounty, gen(cityid)
/// 310K obs (20%) of the sample observed a change in their tax rate 
tab sd_dum, sort 
//// Most of the variation comes from denver. (88%) 
tab cityid sd_dum, rowsort


*********************************************************************************
/// In this case, subexperiment refers to the set of cities that observed a tax change in a given period.
tab date, gen(dated)
forvalues j=3(1)5{
rename exp`j'_treated treat`j'
tab cityid treat`j' if dated`j' == 1, rowsort
}
/// Elasiticity is measured as the change in supply upon a change in the sales tax. Thus, the variation comes from places that had a change in their tax rate. Hence, we restrict the analysis to only cities that experienced a change in their tax rate. In this case, treat`j' == 1 
gen logdays = ln(1+reservationdays)
/// The simplest regression is to do a classic log q = tax rate regression for each subexperiment. Thus, we are estimating the elasticity in the subset of  
global regopts absorb(listingtype monthlydate propertyid) vce(cluster cityid)
forvalues j=3(1)5{
local conditional treat`j' == 1 
reghdfe logdays citytaxrate if `conditional' , $regopts 
estimates store elasiticity`j'
}
/// Evidence from this simple exercise suggests that the elasticities are different. But not that much, all are positive but different. 
esttab elasiticity*, keep(citytaxrate) se(%12.4fc) b(%12.4fc) mtitles("Exp1" "Exp2" "Exp3")

********************************************************************************
/// We want to test whether these estimates are statistically different from each other. So we have to stack this regressions in order to preserve the right error structure. To do so, we will use a stacked difference-in-difference type regression analysis. 

/*
Steps Defined by Coady
1. Define the Event Window 
2. Enumerate Sub Experiments 
3. Define Inclusion Criteria
4. Stack the Data
5. Specify an Estimating Equation
*/
label define treated 0 "Control" 1 "Tax Change"
********************************************************************************
/// Step1: Define the Event Window: 12 months before and after the change in the tax.  
/// For each experiment, I want the semester before and the semester after. 
/// For example, for experiment1 is keep dated1 dated2, dated3, and dated4 == 1
/// Step 2: Enumerate the SubExperiments. We have 3 subexperiments. 
/// First, create date dummies to track down the semesters 


local date3 = tm(2018m1)
local date4 = tm(2018m7)
local date5 = tm(2019m1)
forvalues j = 3(1)5{
local a = `j' - 2
local b = `j' - 1
local c = `j'
local d = `j' + 1
preserve 
keep if dated`a' == 1 | dated`b' == 1 | dated`c' == 1 | dated`d' == 1
tab monthlydate date
sort id monthlydate
format monthlydate %tm_Mon_CCYY
drop deltatax delta_dum
bysort id: gen deltatax = citytaxrate[_n] - citytaxrate[_n-1]
replace deltatax = 0 if deltatax == . 
gen taxdum = deltatax > 0 
tab monthlydate taxdum if treat`j' == 1
/// Create the et time variable. This will be the time index for the stacked diff-in-diff 
gen et = . 
/// Set the time counter equal to t=1 in the period after we observed the tax rate change 
sort id monthlydate
bysort id: replace et = 1 if monthlydate == `date`j''
// Leads 
local s = 0 
forvalues k = 1(1)11{
	bysort id: replace et = `s' if et[_n+`k'] == 1 
	local s = `s' - 1
}
// Lags 
local s = 2 
forvalues k = 1(1)11{
	bysort id: replace et = `s' if et[_n-`k'] == 1 
	local s = `s' + 1
}
tab et 
tab monthlydate et 
/// Step 3: Define the inclusion criteria: Valid time periods. 
/// Now keep only the observations within the window 
drop if et == . 
/// Identify Treatment and Control Observations 
tab et treat`j'
gen treated = treat`j'
save "${bt}\SubExperiment`j'.dta", replace 
restore 
}
log close

