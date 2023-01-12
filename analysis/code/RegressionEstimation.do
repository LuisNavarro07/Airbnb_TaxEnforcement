********************************************************************************
********************************************************************************
**** State vs Local Tax Enforcement Effectiveness: Evidence from Airbnb Price Data 
**** By: Justin Ross, Whitney Afonso, Luis Navarro 
**** Last Update: Navarro, Luis 
********************************************************************************
********************************************************************************
global regsaveopts table(base, format(%9.4f) parentheses(stderr) asterisk(10 5 1) order(regvars r2 N)) replace 
global conditional modelmiss == 0 & msa_miss == 0
global regopts absorb(propertyid listingtype monthlydate) vce(cluster city)
/// Outcomes 
global outcome revenueperday totaldays reservationdays 
*global outcome revenueperday 
label variable HomeRule "Local Collection"
label variable homerule_salestax "Local Collection x Sales Tax"
//// Regression where the outcome variable is the number of days 
// Definitions
* Reservation Days: count of days with a reservation in the month 
* Available Days: count of available days that did not have a booking 
* Blocked Days: count of days blocked from accepting reservations in the month. 
/// Regression: Fixed Effects Poission Regression Outcomes in Levels 
local varlist $outcome 
foreach var of local varlist {
/// Model Definition 
/// Model 1 No Excise Taxes 
global model `var' $taxes 
ppmlhdfe $model if ${conditional}, ${regopts}
estimates store `var'1
regsave using "${aorm}/`var'_t1poisson${mod}.dta", ${regsaveopts}
/// Model 2. No Interaction 
global model `var' $taxes excisetax
ppmlhdfe $model if ${conditional}, ${regopts}
estimates store `var'2
regsave using "${aorm}/`var'_t2poisson${mod}.dta", ${regsaveopts}
/// Model 3. City and Property Fixed Effects 
global model `var' $taxes excisetax excisetaxhr
ppmlhdfe $model if ${conditional}, ${regopts}
estimates store `var'3
regsave using "${aorm}/`var'_t3poisson${mod}.dta", ${regsaveopts}
esttab `var'2 `var'1  `var'3 using "${aorm}/`var'_coefpoisson${mod}.tex", mtitles("Baseline" "No Excise Taxes" "Excise Interaction") ${tables}

} 

*******************************************************************************
/// Regressions: Outcomes are Logged y = log(1+y)
local varlist $outcome 
foreach var of local varlist {
/// Create the Logged outcome 
generate log`var' = ln(1 + `var')
/// Model Definition 
global model log`var' $taxes 
reghdfe $model if ${conditional}, ${regopts}
estimates store `var'1log
regsave using "${aorm}/`var'_t1${mod}.dta", ${regsaveopts}
/// Model 2. No Interaction 
global model log`var' $taxes excisetax
reghdfe $model if ${conditional}, ${regopts}
estimates store `var'2log
regsave using "${aorm}/`var'_t2${mod}.dta", ${regsaveopts}
/// Model 3. City and Property Fixed Effects 
global model log`var' $taxes excisetax excisetaxhr
reghdfe $model if ${conditional}, ${regopts}
estimates store `var'3log
regsave using "${aorm}/`var'_t3${mod}.dta", ${regsaveopts}
esttab `var'2log `var'1log `var'3log, mtitles("Baseline" "No Excise Taxes" "Excise Interaction") ${tables}
drop log`var'
} 

label variable homerule_salestax "Local Collection x Sales Tax"
global coefopts1 recast(bar) citop ciopts(recast(rcap lowerlimit upperlimit barposition) lcolor(dknavy*1.2)) color(dknavy%70)
global coefopts2 recast(bar) citop ciopts(recast(rcap lowerlimit upperlimit barposition) lcolor(gray*1.2)) color(gray%70)
global coefopts3 recast(bar) citop ciopts(recast(rcap lowerlimit upperlimit barposition) lcolor(ebblue*1.2)) color(ebblue%70)

global options_plot xline(0) xlabel(#10,angle(0) labsize(small) grid) ylabel(,labsize(vsmall)) legend(on order(1 "Avg Daily Revenue" 3 "Listed Days" 5 "Rented Days") rows(1) cols(4) size(vsmall)) ytitle("") graphregion(margin(r+5)) graphregion(color(white)) 

coefplot (totaldays2log, $coefopts2 barwidth(0.22)) ///
	(reservationdays2log, $coefopts3 barwidth(0.22)), drop(_cons) ${options_plot} name(mainres, replace)
graph export "${aorm}/MainResults_${mod}.png", $export 


global options_plot xline(0) xlabel(#10,angle(0) labsize(small) grid) ylabel(,labsize(vsmall)) legend(off order(1 "Avg Daily Revenue" 3 "Listed Days" 5 "Rented Days") rows(1) cols(4) size(vsmall)) ytitle("") graphregion(margin(r+5)) graphregion(color(white)) 
coefplot (revenueperday2log, $coefopts3 barwidth(0.35)), drop(_cons) ${options_plot} name(mainresprices1, replace) title(Avg Daily Revenue, pos(11) size(small))
graph export "${aorm}/MainResultsPrice1_${mod}.png", $export 
 


********************************************************************************
global options_plot xline(0) xlabel(#10,angle(0) labsize(small) grid) ylabel(,labsize(vsmall)) legend(on order(1 "Baseline" 3 "No Excise Taxes" 5 "No Excise Taxes") rows(1) cols(4) size(vsmall)) ytitle("") graphregion(margin(r+5)) graphregion(color(white)) 
/// Graph 1. Revenue Per Day 
coefplot (revenueperday2log, $coefopts1 barwidth(0.2)) ///
	(revenueperday1log, $coefopts2 barwidth(0.2)) ///
	(revenueperday3log, $coefopts3 barwidth(0.2)), keep(homerule_salestax) ${options_plot} name(revenueperday, replace) title("Avg Daily Revenue", pos(11) size(medsmall) color(black))
/// Graph 2. Total Days
coefplot (totaldays2log, $coefopts1 barwidth(0.2)) ///
	(totaldays1log, $coefopts2 barwidth(0.2)) ///
	(totaldays3log, $coefopts3 barwidth(0.2)), keep(homerule_salestax) ${options_plot} name(totaldays, replace) title("Listed Days", pos(11) size(medsmall) color(black))
/// Graph 3. Reservation Days 
coefplot (reservationdays2log, $coefopts1 barwidth(0.2)) ///
	(reservationdays1log, $coefopts2 barwidth(0.2)) ///
	(reservationdays3log, $coefopts3 barwidth(0.2)), keep(homerule_salestax) ${options_plot} name(reservationdays, replace) title("Booked Days", pos(11) size(medsmall) color(black))
	
grc1leg revenueperday totaldays reservationdays, legendfrom(revenueperday) xcommon rows(3)
graph export "${aorm}/Coefplot_models_${mod}.png", $export 

**********************************************************************************
/// Export Results to Tex Save
preserve 
local varlist $outcome 
foreach var of local varlist {
forvalues i=1(1)3{
use "${aorm}/`var'_t`i'${mod}.dta", clear 
rename base `var'`i'
save "${aorm}/`var'_tt`i'${mod}.dta", replace 
}

use "${aorm}/`var'_tt1${mod}.dta", clear 
forvalues i=2(1)3{
merge 1:1 var using "${aorm}/`var'_tt`i'${mod}.dta", keep(match) nogen 	
}
keep if var == "homerule_salestax_coef" | var == "homerule_salestax_stderr" 

replace var = "`var'" if var == "homerule_salestax_coef"
replace var = "" if var == "homerule_salestax_stderr"

rename `var'1 NoExciseTaxes
rename `var'2 Baseline
rename `var'3 ExciseInteraction

save "${aorm}/`var'_ttotal${mod}.dta", replace 

}

use "${aorm}/revenueperday_ttotal${mod}.dta", clear 
global outcome totaldays reservationdays
local varlist $outcome 
foreach var of local varlist {
	append using "${aorm}/`var'_ttotal${mod}.dta" 
}

order var Baseline NoExciseTaxes ExciseInteraction

global sig_note "*indicates statistical significance at the 10\% level; **indicates significance at the 5\% level; ***indicates significance at the 1\% level."
global clust_note "Standard errors are clustered by city."
global robust_note "Standard errors are robust."
global dep_note "Dependent variables are in logarithms."

replace var = "Avg Daily Revenue" if var == "revenueperday"
replace var = "Listed Days" if var == "totaldays"
replace var = "Booked Days" if var == "reservationdays"

texsave using "${aorm}/Coefficients_${mod}.tex", replace frag nofix ///
	footnote("$clust_note $sig_note $dep_note")

save "${aorm}/Coefficients_${mod}.dta", replace 

restore 

