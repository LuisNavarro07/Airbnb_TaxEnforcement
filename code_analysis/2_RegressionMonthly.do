********************************************************************************
********************************************************************************
**** State vs Local Tax Enforcement Effectiveness: Evidence from Airbnb Price Data 
**** By: Justin Ross, Whitney Afonso, Luis Navarro 
**** Last Update: Navarro, Luis 
**** Date: January 20, 2023
**** Script: Regression Analysis - Monthly Data 
********************************************************************************
********************************************************************************
// Define the right subset for the analysis 
clear all 
/// Open DataSet
use "${ai}/ColoradoPropertyMonthlyMerge.dta", clear

/// Main Regression Specification: Linear Regression with Fixed Effects 
/// Outcomes: reservation days 
/// Independent variables: homerule_salestax citytaxrate HomeRule airbnbag excisetax
/// Model Options 
global conditional modelmiss == 0 & msa_miss == 0
global regopts absorb(id monthlydate) vce(cluster city)
global outcomes reservationdays
global model homerule_salestax citytaxrate HomeRule airbnbag excisetax

/// Export Options 
global regsaveopts detail(scalars) table(base, format(%9.4f) parentheses(stderr) asterisk(10 5 1) order(regvars r2 N)) replace 
global tables keep(${model}) se label replace noobs compress 

/// Generate Outcomes in Logarithms y = ln(1+x)
foreach y in $outcomes {
gen log`y' = ln(`y')
copydesc `y' log`y'	
}

local i = 1
foreach y in $outcomes  {
/// Estimate the Linear Regression Model: Outcome is log y 
eststo modlinear`i': reghdfe log`y' ${model} if ${conditional}, ${regopts}  
qui estadd ysumm, replace
qui tempfile modlinear`i'
regsave using `modlinear`i'', ${regsaveopts}

/// Estimate Poisson Regression Model 
eststo modpoiss`i': ppmlhdfe `y' ${model} if ${conditional}, ${regopts}  
qui estadd ysumm, replace
qui tempfile modpoiss`i'
regsave using `modpoiss`i'', ${regsaveopts}

**** Another lap to the loop: the next outcome 
local i = `i' + 1
}


/// Estimate the Linear Probability Model 
********************************************************************************
/// Rectangularize the Dataset 
qui fillin id reportingmonth 
qui keep id reportingmonth monthlydate revenueperday totaldays _fillin fips city metropolitanstatisticalarea listingtype 
qui gen year = real(substr(reportingmonth,1,4))
qui gen month_scrape = real(substr(reportingmonth,6,2))
qui gen semester = .
qui replace semester = 1 if month_scrape <= 6 
qui replace semester = 2 if month_scrape > 6
qui xtset id 
qui xfill $controls city fips listingtype metropolitanstatisticalarea, i(id)
global dimensions semester year fips city 
qui merge m:1 $dimensions using "${bt}/ColoradoSalesTaxClean.dta", keep(match master)
qui drop if _merge == 1
qui drop _merge 

// Step 3. Generate the Binary Outcome 
generate listed = . 
replace listed = 0 if _fillin == 1 
replace listed = 1 if _fillin == 0 

// run the model with xtlogit 
/// Generate MonthlyDate
qui gen date2 = date(reportingmonth, "YMD")
qui format date2 %td
qui drop monthlydate 
qui gen monthlydate = mofd(date2)
qui format monthlydate %tm
/// Panel Dimensions for Fixed Effects Estamation 
xtset id monthlydate 

/// Step 3. Do the Regressions 
/// Linear Probability Model 
reghdfe listed $model, $regopts
estimates store listed_lpm
qui estadd ysumm, replace
qui tempfile listed_lpm
qui regsave using`listed_lpm', ${regsaveopts}

/// Fixed Effects Logit Regression 
xtlogit listed $model, fe 
qui estimates store listed_logit
qui estadd ysumm, replace
qui tempfile listed_logit
qui regsave using `listed_logit', ${regsaveopts}

/// Compute the Marginal Effects 
margins, dydx(*) atmeans 

********************************************************************************
/// Export Results 

*******************************************************************************
/// Table 1. Main Results Evidence From Quantities 
/// Columns: Outcome variables: listed days, rented days, any day LPM, any day logit 
/// Models: monthly data and then rectangularize the dataset to run the Probability Models 

**** Intensive Margin Models 
local i = 1
foreach y in $outcomes {
/// Format Results to Export 
/// Linear Model 
preserve 
qui use `modlinear`i'', clear 
qui gen id = _n 
qui rename base `y'
*qui drop if id >= 16
qui replace var = subinstr(var, "o.", "", .)
qui tempfile resfile`i'
qui save `resfile`i'', replace 
restore 

/// Poisson Regression 
preserve 
qui use `modpoiss`i'', clear 
qui gen id = _n 
/// Clean to Transform Coefficients
qui gen val = subinstr(base, "***", "", .)
qui replace val = subinstr(val, "**", "", .)
qui replace val = subinstr(val, "*", "", .)
qui replace val = subinstr(val, ",", "", .)
qui replace val = subinstr(val, "(", "", .)
qui replace val = subinstr(val, ")", "", .)
qui destring val, replace
/// Transform the Coefficient 
/// We Report 100*(exp(beta) -1)
qui gen expcoef = 100*(exp(val) - 1)
qui tostring expcoef, replace force
qui gen point_pos = strpos(expcoef,".")
qui replace expcoef = substr(expcoef,1,point_pos + 4) 
qui replace expcoef = "0" + expcoef if strpos(expcoef,".") == 1
/// Stars and Significance 
qui gen nstar =  (length(base) - length(subinstr(base, "*", "", .))) 
qui replace expcoef = expcoef + "*" if nstar == 1
qui replace expcoef = expcoef + "**" if nstar == 2
qui replace expcoef = expcoef + "***" if nstar == 3
/// Replace Coefficients for Tranformations 
qui replace base = expcoef if strpos(var,"_coef") > 0
/// Drop all the variables we created 
qui drop val point_pos nstar expcoef 
qui rename base `y'_poiss
/// Save File 
qui tempfile res_poiss`i'
qui save `res_poiss`i'', replace 
restore 
**** Another lap to the loop: the next outcome 
local i = `i' + 1
}

*** Extensive Margin Models 
/// Linear 
preserve 
qui use `listed_lpm', clear 
qui gen id = _n 
qui rename base listed_lpm
*qui drop if id >= 16
qui tempfile resfile3
qui save `resfile3', replace 
restore 

/// Logit 
preserve 
qui use `listed_logit', clear 
qui gen id = _n 
qui rename base listed_logit
*qui drop if id >= 13
qui replace var = subinstr(var, "listed:", "", .)
qui tempfile resfile4
qui save `resfile4', replace 
restore 

****** Merge the Clean Files 
use `resfile1', clear 
merge 1:1 var using `res_poiss1', keep(match master) nogen
merge 1:1 var using `resfile3', keep(match master) nogen
merge 1:1 var using `resfile4', keep(match master) nogen
order var reservationdays* listed_lpm listed_logit
save "${ao}/MainResults1_Quantities.dta", replace 

*** Formatting Commands 
use "${ao}/MainResults1_Quantities.dta", clear 
// Drop the Intercept from Table 
drop if var == "_cons_coef" | var == "_cons_stderr"
* Clean variable names
replace var = subinstr(var,"_coef","",1)
replace var = "" if strpos(var,"_stderr")
/// Drop Unnecessary Statistics 
drop if id > 15
sort id 
drop id
* texsave will output these labels as column headers
label var reservationdays "Linear"
label var reservationdays_poiss "Poisson"
label var listed_lpm "LPM"
label var listed_logit "Logit"

* Display R^2 in LaTeX math mode
replace var = "\(R^2\)" if var=="r2"
replace var = "Mean of Dep. Variable" if var=="ymean"
replace var = "Observations" if var=="N"
** Specific VarNames 
cap replace var = "Local Enforcement x Sales Tax"   if var=="homerule_salestax"
cap replace var = "Sales Tax Rate"                  if var=="citytaxrate"
cap replace var = "Local Enforcement"               if var=="HomeRule"
cap replace var = "Airbnb Collection Agreement"     if var=="airbnbag"
cap replace var = "Other Taxes"                     if var=="excisetax"
cap replace var = "Other Taxes x Local Enforcement" if var=="excisetaxhr"
list

*** Export the Table 
local title "Local Enforcement Effect on Reservation Days: Extensive and Intensive Margins"
local headerlines "& \multicolumn{2}{c}{Intensive Margin} & \multicolumn{2}{c}{Extensive Margin} " "\cmidrule(lr){2-3} \cmidrule(lr){4-5}"
local fn "Notes: Columns (1) and (2) report estimates of \(\beta\) from Equation (\ref{eqn:Model}) where the outcome variable is the count of days the property hold a reservation during the month. Column (1) shows the coefficients from estimating the model using linear regression. Column (2) shows the results from using a fixed-effects Poisson estimator. We report transformed coefficients using the following formula $100*exp(\hat{\beta} -1)$. Columns (3) and (4) report estimates of probability models with a linear and a logit link function, respectively. Clustered standard errors at the city level are reported in parentheses. A */**/*** indicates significance at the 10/5/1\% levels."
texsave using "${ao}/MainResults1_Quantities.tex", autonumber varlabels hlines(-3) nofix replace marker(tab:MainResults1_Quantities) title("`title'") headerlines("`headerlines'") footnote("`fn'")

exit 

