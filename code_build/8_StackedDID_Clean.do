********************************************************************************
********************************************************************************
**** State vs Local Tax Enforcement Effectiveness: Evidence from Airbnb Price Data 
**** By: Justin Ross, Whitney Afonso, Luis Navarro 
**** Last Update: Navarro, Luis 
**** Date: January 20, 2023
**** Script: Stacked DID - Data setup 
********************************************************************************
********************************************************************************
clear all 
********************************************************************************
/// First identify the cities that had a tax rate change at some point in the sample. 
/// Load the Tax Dataset 
qui use "${bt}/ColoradoSalesTaxClean.dta", clear
// Generate Unique Ids for City County (this accounts for cities that are different counties)
qui egen citycounty = group(city fips)
qui duplicates report citycounty date 
/// Just keep tax rates 
qui collapse (mean) citytaxrate (first) city fips, by(citycounty date)
qui xtset citycounty date 
/// Rectangularize the Dataset 
qui fillin citycounty date 
qui xfill city fips 
/// Assumption: Drop the cities from which we have missing data on the city sales tax rate 
qui bysort citycounty: egen filldum = mean(_fillin)
tab city if filldum > 0 
drop if filldum > 0 
qui drop _fillin filldum 
qui format date %tq
/// Assumption: We need to identify the cities that observed a change in their tax rate, so we took the standard deviation of the tax rates. In this case, if the sd > 0, then it must be the case that a change in the tax rate happened at some moment. 
qui sort citycounty date
xtset citycounty date 
qui bysort citycounty: egen sd = sd(citytaxrate)
/// sd_dum == 1 if city is treated (i.e. experienced a tax rate change)
qui bysort citycounty: gen sd_dum = sd > 0 
tab sd_dum 
/// We have 18 cities that had tax changes 
distinct citycounty if sd_dum == 1 
/// Now identify in which moment they changed their taxrate 
table citycounty date if sd_dum == 1, stat(mean citytaxrate)
/// Calculate the tax change 
qui sort citycounty date
qui bysort citycounty: gen deltatax = citytaxrate[_n] - citytaxrate[_n-1]
/// Replace Delta Tax = 0 for the initial period 
qui sum date 
local mindate = r(min) 
qui replace deltatax = 0 if date == `mindate'
/// Check for the type of tax changes 
sum deltatax
/// There is one city that experienced a negative tax change. 
/// Create a Variable equal to the tax change 
qui bysort citycounty:egen tax_change = mean(deltatax) if deltatax != 0 
qui bysort citycounty:egen tax_change1 = mean(tax_change) 
qui drop tax_change
qui rename tax_change1 tax_change
/// Fill out misings 
qui replace tax_change = 0 if tax_change == . 
*********************************************************************************
/// Assumption: Remove from the Sample Manitou Springs: the city that experienced a negative tax change. 
drop if tax_change < 0
********************************************************************************
/// dummy equal to one when the tax change happens
qui gen delta_dum = deltatax > 0 
/// Dummies for each semester 
qui tab date, gen(dated)
/// Create Treatment Variables for Each SubExperiment. In this case, expj_treated == 1 for any city that experienced a tax rate change in subexperiment j. 
forvalues j =3(1)5{
/// Variable that stores whether the unit was treated at any cohort 
qui gen treat_tot = 0 
/// Identify the cities that experienced a change in taxes, gen variable to denote treatment 
qui tab citycounty if dated`j' == 1 & delta_dum == 1, gen(treat)
global tot = r(r)
/// For each city treated 
forvalues i=1(1)$tot {
/// Replace to zero if missing 
qui replace treat`i' = 0 if treat`i' == . 
/// Identify the dummy that denotes treatment status and add it to the variable 
qui replace treat_tot = treat_tot + treat`i'
}
/// Create a treatment variable fixed across periods for each city  
qui bysort citycounty: egen exp`j'_treated = mean(treat_tot)
qui bysort citycounty: replace exp`j'_treated = exp`j'_treated > 0 
qui drop treat*
}
/// Save
qui drop dated* 
tempfile taxchanges
save `taxchanges', replace 
save "${bt}/taxrates_changes.dta", replace 

******************************************************
/// Loadl Monthly DataSet 
qui use "${ai}/ColoradoPropertyMonthlyMerge.dta", clear
qui sort id monthlydate
drop cityid
/// Merge the Results 
merge m:1 city fips date using `taxchanges', keep(match master)
tab _merge 
/// Assumption: Only Keep the Observations from which we certainly know the tax rate and when it changes. Thus the merge only keeps the matched observations. This only derives in losing a 0.33% of the sample. We are not concerned about this. 
drop if _merge == 1 
drop citycounty
qui gen citycounty = city + " - " + County 
qui encode citycounty, gen(cityid)
/// 310K obs (20%) of the sample observed a change in their tax rate 
tab sd_dum, sort 
//// Most of the variation comes from denver. (88%) 
tab cityid sd_dum, rowsort
/// In this case, subexperiment refers to the set of cities that observed a tax change in a given period.
tab date, gen(dated)
forvalues j=3(1)5{
qui rename exp`j'_treated treat`j'
tab cityid treat`j' if dated`j' == 1, rowsort
}
qui format date %tq
/// Stacked DID Estimation 
*********************************************************************************
********************************************************************************
/// We want to test whether these estimates are statistically different from each other. So we have to stack this regressions in order to preserve the right error structure. To do so, we will use a stacked difference-in-difference type regression analysis. The key part is to specify the regression with an interaction term that allows us to directly make the hypothesis test. 

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
/// Define the Main Independent Variable 
*global independent treated /// Binary Treatment 
global independent tax_change // Continuous Treatment (Treatment Intensity)
********************************************************************************
/// Step1: Define the Event Window: 12 months before and after the change in the tax.  
/// For each experiment, I want the semester before and the semester after. 
/// For example, for experiment1 is keep dated1 dated2, dated3, and dated4 == 1
/// Step 2: Enumerate the SubExperiments. We have 3 subexperiments. 
********************************************************************************
********************************************************************************
/// Create a template of the event time. This is done in order to avoid wrong leads and lags at unbalanced panel settings. The idea is to create a balanced panel, then convert from calendar time to experiment time. Then merge that template to each subexperiment. 
/// Create date dummies to track down the semesters 
local date3 = tm(2018m1)
local date4 = tm(2018m7)
local date5 = tm(2019m1)
/// For each sub exeperiment 
forvalues j = 3(1)5{ 
/// Local to denote the periods 
local a = `j' - 2
local b = `j' - 1
local c = `j'
local d = `j' + 1

/// Step 1. Transform from calendar time to experiment time. 
/// Keep only the two preceeding cohorts, the treatment cohort and the next period 

preserve 
keep if dated`a' == 1 | dated`b' == 1 | dated`c' == 1 | dated`d' == 1
keep id monthlydate treat`j' tax_change HomeRule
/// Rectangularize the dataset 
fillin id monthlydate
xtset id monthlydate 
/// Define Everything in Time relative to the tax change 
/// Create the et time variable. This will be the time index for the stacked diff-in-diff 
qui gen et = . 
/// ASSUMPTION: Set the time counter equal to t=1 in the period after we observed the tax rate change. Hence, the intervention occured at period et = 1
qui sort id monthlydate  
bysort id: replace et = 1 if monthlydate == `date`j''
// Leads 
local s = 0 
forvalues k = 1(1)12{
	qui bysort id: replace et = `s' if et[_n+`k'] == 1 
	local s = `s' - 1
}
// Lags 
local s = 2 
forvalues k = 1(1)11{
	qui bysort id: replace et = `s' if et[_n-`k'] == 1 
	local s = `s' + 1
}
drop _fillin 
tab monthlydate, sum(et) 
/// Step 2. Create the interactions in a balanced panel 
/// 2.1. Define the Treatment Variable 
/// Treated is a variable that represent treatment status across subexperiments. 
bysort id: egen treated = mean(treat`j')
/// For consistency, the tax change in case of continuous treatment should be zero. This is to ensure we are making comparisons of never treated with the sub-exp treatment group. 
replace tax_change = 0 if treated == 0 
bysort id: egen tax_change1 = mean(tax_change)
drop tax_change 
rename tax_change1 tax_change
/// Check the Panel 
xtset id et 
sort id et

/// 2.2 Define How Many Leads and Lags 
/// Leads - Pre Periods 
qui gen post = 0
/// Post Variable Equal to 1 for et >= 1 
qui replace post = 1 if et >= 1 
/// Number of Pre and Post Periods (leads first)
tab et if post == 0 
local pre = r(r) 

/// Lag - Post Periods 
tab et if post == 1 
local post = r(r)

/// 2.3 Create Lags (Pre-Periods)
/// Leads - Pre Periods 
forvalues k = 2(1)`pre' {
qui gen lead`k' = F`k'.${independent}
qui replace lead`k' = 0 if lead`k' == .
qui label variable lead`k' "-`k'"
}
/// 2.4 Create Leads (Post-Periods)
/// Reference Group - Observation one period before intervention 
gen lead1 = 0
/// Lead 0 == Intervention Time 
gen lead0 = ${independent}
/// Lags
forvalues k = 1(1)`post' {
qui gen lag`k' = L`k'.${independent}
sort id et
qui replace lag`k' = 0 if lag`k' == .
qui label variable lag`k' "+`k'"
}

label variable lead1 "-1"
label variable lead0 "0"

capture order id et lead12 lead11 lead10 lead9 lead8 lead7 lead6 lead5 lead4 lead3 lead2 lead1 lead0 lag1 lag2 lag3 lag4 lag5 lag6 lag7 lag8 lag9 lag10 lag11 lag12

/// Triple Interactions 
local varlist lead12 lead11 lead10 lead9 lead8 lead7 lead6 lead5 lead4 lead3 lead2 lead1 lead0 lag1 lag2 lag3 lag4 lag5 lag6 lag7 lag8 lag9 lag10 lag11 lag12
foreach var of local varlist {
gen `var'hr = `var'*HomeRule
copydesc `var' `var'hr
}


tempfile eventime`j'
save `eventime`j'', replace 
restore 


********************************************************************************
/// Step 2. Create the Event Interactions Also in a Balanced Panel 
preserve 
keep if dated`a' == 1 | dated`b' == 1 | dated`c' == 1 | dated`d' == 1
/// Drop Late/Early Adopters 
drop if sd_dum == 1 & treat`j' == 0
/// Merge with Event Time 
merge 1:1 id monthlydate using `eventime`j'', keep(match master) nogen
/// Save the SubExperiment
qui gen subexp = `j'
tempfile subexperiment`j'
save `subexperiment`j'', replace 
restore 
}
*********************************************************************************

********************************************************************************

/// Append the datasets for each cohort 
use `subexperiment3', clear 
append using `subexperiment4' 
append using `subexperiment5'
save "${at}/rcstackdid.dta", replace 
exit 
