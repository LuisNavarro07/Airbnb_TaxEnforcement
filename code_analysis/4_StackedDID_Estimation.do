********************************************************************************
********************************************************************************
**** State vs Local Tax Enforcement Effectiveness: Evidence from Airbnb Price Data 
**** By: Justin Ross, Whitney Afonso, Luis Navarro 
**** Last Update: Navarro, Luis 
**** Date: January 20, 2023
**** Script: Model Estimation 
********************************************************************************
********************************************************************************

*log using "${ao}/LogStackedDIDModel.log", replace 
use "${at}/rcstackdid.dta", clear  

/// Generate Variable that Uniquely Identifies Unit by Subexperiment 
tab subexp treated, row 
/// In our experiment, the comparsion is not that balanced across treatment and controls.
/// 92% control group and 8% treatment group 
/// Unique Id in the stacked dataset 

/// Create id variable 
egen stacked_id = group(subexp id)
/// Now the Dataset should be uniquely identified by unit-subexperiment and time relative to intervention 
xtset stacked_id et
/// Generate the DID Variable treat times post 
qui gen did = ${independent}*post 

/// Generate Interaction Term with Home Rule Status 
gen didlocal = did*HomeRule
label variable didlocal "Local Enforcement * Tax Change"

/// Subexp Dummies: these are for cohort-specific effects 
forvalues i = 3(1)5{
qui gen subexp`i' = 0 
qui replace subexp`i' = 1 if subexp == `i'
/// Generate Interaction Terms 
gen did`i' = ${independent}*post*subexp`i'
}


/// Estimate the Stacked Difference in Difference Model
global conditional modelmiss == 0 & msa_miss == 0
/// SubExperiment Fixed Effects too 
global regopts absorb(id et subexp) vce(cluster city)
global outcomes reservationdays
/// Change the Structure of the Econnometric Specification 
/// Leaving Out Did5 as Reference Category 
global modeldid didlocal did HomeRule excisetax airbnbag

/// Export Options 
global regsaveopts detail(scalars) table(base, format(%9.4f) parentheses(stderr) asterisk(10 5 1) order(regvars r2 N)) replace 
global tables keep(${modeldid}) se label replace noobs compress 

/// Generate Outcomes in Inverse Hyperbolic Sine Transformation 
foreach y in $outcomes {
gen log`y' = asinh(`y')
copydesc `y' log`y'	
}

///Global events 
global modelevent lead12 lead11 lead10 lead9 lead8 lead7 lead6 lead5 lead4 lead3 lead2 lead1 lead0 lag1 lag2 lag3 lag4 lag5 lag6 lag7 lag8 lag9 lag10 lag11 lag12
global pretrends lead12 lead11 lead10 lead9 lead8 lead7 lead6 lead5 lead4 lead3 lead2 lead1

/// Create Event Interactions with HomeRule 
local varlist $modelevent
foreach var of local varlist {
qui replace `var' = `var'*HomeRule
}

local i = 1
foreach y in $outcomes  {
/// Estimate the Linear Regression Model: Outcome is log y 
eststo stackedlin`i': reghdfe log`y' ${modeldid} if ${conditional}, ${regopts}  
qui estadd ysumm, replace
qui tempfile stackedlin`i'
regsave using `stackedlin`i'', ${regsaveopts}

/// Hypothesis Test. All Coefficients are equal. We should not reject the NULL. 
/// We want a Big Pvalue 
test didlocal

/// Estimate the Event Study Specification 
/// Linear 
eststo eventlin`i': reghdfe log`y' ${modelevent} if ${conditional}, ${regopts}  
qui estadd ysumm, replace
qui tempfile eventlin`i'
regsave using `eventlin`i'', ${regsaveopts}
// Parallel trends Assumption 
test $pretrends

********************************************************************************
/// Estimate Poisson Regression Model 
eststo stackedpoiss`i': ppmlhdfe `y' ${modeldid} if ${conditional}, ${regopts}  
qui estadd ysumm, replace
qui tempfile stackedpoiss`i'
regsave using `stackedpoiss`i'', ${regsaveopts}

/// Hypothesis Test. All Coefficients are equal. We should not reject the NULL. 
/// We want a Big Pvalue 
test didlocal 

/// Event Study Poission 
eststo eventpois`i': ppmlhdfe `y' ${modelevent} if ${conditional}, ${regopts}  
qui estadd ysumm, replace
qui tempfile eventpois`i'
regsave using `eventpois`i'', ${regsaveopts}
// Parallel trends Assumption 
test $pretrends

**** Another lap to the loop: the next outcome 
local i = `i' + 1
}

global line1 recast(connected) lcolor(black) lwidth(medthin) mcolor(black) msize(vsmall) msymbol(circle) ciopts(recast(rcap) fcolor(gray) fintensity(inten10) lcolor(gray))
global line2 recast(connected) lcolor(maroon) lwidth(medthin) mcolor(maroon) msize(vsmall) msymbol(square) ciopts(recast(rcap) fcolor(cranberry) fintensity(inten10) lcolor(cranberry))

global coefopts vertical yline(0,lcolor(black) lpattern(solid) lwidth(vthin)) xline(12,lcolor(black) lpattern(dash) lwidth(vthin)) ylabel(#10, labsize(small) angle(0) nogrid) xlabel(,angle(90) labsize(small) nogrid) 

/// Coefplots 
coefplot (eventlin1, $line1), name(eventlin,replace) $coefopts title("Linear - Reservation Days", pos(11) size(small)) baselevels omitted keep($modelevent) 

coefplot (eventpois1, $line2), name(eventpois,replace) $coefopts title("Poisson - Reservation Days", pos(11) size(small)) baselevels omitted keep($modelevent) 

*coefplot (eventlin1, $line1) (eventpois1, $line2), name(event_combined,replace) $coefopts title("Event Study - Reservation Days", pos(11) size(medsmall)) baselevels omitted keep($modelevent) legend(on order(2 "Linear" 4 "Poisson") size(medsmall) rows(1))

graph combine eventlin eventpois, rows(2) xcommon name(event_combined, replace) xsize(16) ysize(8) 
graph export "${ao}/RC_StackedDid_Events.png", $export 


*log close

********************************************************************************
**** Intensive Margin Models 

/// Export the Results 
use `stackedlin1', clear 
rename base linear 
gen id = _n 
tempfile stackedlin1
save `stackedlin1',replace 

use `stackedpoiss1', clear 
gen id = _n 
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
qui rename base poisson
/// Save File 
tempfile stackedpoiss1
save `stackedpoiss1',replace 

********************************************************************************
/// Merge the Results 
use `stackedlin1', clear 
merge 1:1 var using `stackedpoiss1', keep(match master) nogen
sort id 
save "${ao}/RC_StackedDID_Quantities.dta", replace 

use "${ao}/RC_StackedDID_Quantities.dta", clear  
keep if var == "HomeRule_coef" | var == "HomeRule_stderr" | ///
	var == "did_coef" | var == "did_stderr" | ///
	var == "didlocal_coef" | var == "didlocal_stderr"  | ///
	var == "excisetax_coef" | var == "excisetax_stderr" | ///
	var == "N" | var == "ymean" | var == "r2"
* Clean variable names
replace var = subinstr(var,"_coef","",1)
replace var = "" if strpos(var,"_stderr")
/// Drop Unnecessary Statistics 
sort id 
drop id
* texsave will output these labels as column headers
label var linear "Linear"
label var poisson "Poisson"

* Display R^2 in LaTeX math mode
cap replace var = "\(R^2\)" if var=="r2"
cap replace var = "Mean of Dep. Variable" if var=="ymean"
cap replace var = "Observations" if var=="N"
** Specific VarNames 
cap replace var = "Local Enforcement x DID"   if var=="didlocal"
cap replace var = "Treat x Post"                  if var=="did"
cap replace var = "Local Enforcement"               if var=="HomeRule"
cap replace var = "Airbnb Collection Agreement"     if var=="airbnbag"
cap replace var = "Other Taxes"                     if var=="excisetax"
cap replace var = "Other Taxes x Local Enforcement" if var=="excisetaxhr"
list

*** Export the Table 
local title "Stacked DID Model: Local Enforcement on Airbnb Supply"
local fn "Notes: Column (1) shows the results of estimating the Stacked DID model using a fixed effects estimator. The outcome variable is expressed as the inverse hyperbolic sine of the number of reservation days. Column (2) shows the results from using a fixed-effects Poisson estimator. We report transformed coefficients using the following formula $100*exp(\hat{\beta} -1)$. Clustered standard errors at the city level are reported in parentheses. A */**/*** indicates significance at the 10/5/1\% levels."
texsave using "${ao}/RC_StackedDID_Quantities.tex", autonumber varlabels hlines(-3) nofix replace marker(tab:RC_StackedDID_Quantities) title("`title'") footnote("`fn'")

exit 
