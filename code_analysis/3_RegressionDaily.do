********************************************************************************
********************************************************************************
**** State vs Local Tax Enforcement Effectiveness: Evidence from Airbnb Price Data 
**** By: Justin Ross, Whitney Afonso, Luis Navarro 
**** Last Update: Navarro, Luis 
**** Date: January 14, 2023
**** Script: Regression Analysis - Daily Data 
********************************************************************************
********************************************************************************

// Regression Analysis - Daily Data
use "${ai}/DailyDataCleanComplete.dta", clear

/// Final Preps for Regression 
/// Generate the Outcome Variable 
gen logprice = ln(1 + priceusd)
label variable logprice "Log Price"

/// Dummy Variable in case we don't have observations for the main dep and indep variables 
generate modelmiss = 0 
replace modelmiss = 1 if logprice == . | citytaxrate == . 

/// Main Regression Specification: Linear Regression with Fixed Effects 
/// Outcomes: logprice
/// Independent variables: homerule_salestax citytaxrate HomeRule airbnbag excisetax
/// Model Options 
global conditional modelmiss == 0 & msa_miss == 0
global regopts absorb(id date) vce(cluster city)
global outcome logprice
global model homerule_salestax citytaxrate HomeRule airbnbag excisetax

/// Export Options 
global regsaveopts detail(all) table(base, format(%9.4f) parentheses(stderr) asterisk(10 5 1) order(regvars r2 N)) replace 
global tables keep(${model}) se label replace noobs compress 

/// Estimate the Linear Regression Model 
/// All Prices
reghdfe ${outcome} ${model} if ${conditional}, ${regopts}
qui estimates store modresults1
qui estadd ysumm, replace
qui tempfile modresults1
regsave using `modresults1', ${regsaveopts}
/// Format Results to Export 
preserve 
qui use `modresults1', clear 
qui gen id = _n 
qui rename base allprices
drop if id >= 16
replace var = subinstr(var, "o.", "", .)
qui tempfile resfile1
qui save `resfile1', replace 
restore 

/// Status = 3: Rented Prices 
reghdfe ${outcome} ${model} if ${conditional} & status == 3, ${regopts}
qui estimates store modresults2
qui estadd ysumm, replace
qui tempfile modresults2
regsave using `modresults2', ${regsaveopts}
/// Format Results to Export 
preserve 
qui use `modresults2', clear 
qui gen id = _n 
qui rename base rentedprices
drop if id >= 16
replace var = subinstr(var, "o.", "", .)
qui tempfile resfile2
qui save `resfile2', replace 
restore 


*******************************************************************************

use `resfile1', clear 
merge 1:1 var using `resfile2', keep(match master) nogen
order var allprices rentedprices
save "${ao}/MainResults2_Prices.dta", replace 

*** Formatting Commands 
use "${ao}/MainResults2_Prices.dta", clear 
// Drop the Intercept from Table 
drop if var == "_cons_coef" | var == "_cons_stderr"
* Clean variable names
replace var = subinstr(var,"_coef","",1)
replace var = "" if strpos(var,"_stderr")
replace id = 14 if var == "ymean"
replace id = 15 if var == "N"
sort id 
drop id 
* texsave will output these labels as column headers
label var allprices "Listed Prices"
label var rentedprices "Rented Prices"


* Display R^2 in LaTeX math mode
replace var = "\(R^2\)" if var=="r2"
replace var = "Mean of Dep. Variable" if var=="ymean"

** Specific VarNames 
cap replace var = "Local Enforcement x Sales Tax"   if var=="homerule_salestax"
cap replace var = "Sales Tax Rate"                  if var=="citytaxrate"
cap replace var = "Local Enforcement"               if var=="HomeRule"
cap replace var = "Airbnb Collection Agreement"     if var=="airbnbag"
cap replace var = "Other Taxes"                     if var=="excisetax"
cap replace var = "Other Taxes x Local Enforcement" if var=="excisetaxhr"
list

*** Export the Table 
local title "Local Enforcement Effect on Reservations and Prices"
local fn "Notes: Columns (1) and (2) report estimates of \(\beta\) from equation Equation (\ref{eqn:Model}) for the prices at which a unit was listed or booked. These estimates were obtained from running Equation (\ref{eqn:Model}) on the data set with daily pricing data. Robust standard errors are reported in parentheses. A */**/*** indicates significance at the 10/5/1\% levels."
texsave using "${ao}/MainResults2_Prices.tex", autonumber varlabels hlines(-2) nofix replace marker(tab:MainResults2_Prices) title("`title'") footnote("`fn'")

exit 
