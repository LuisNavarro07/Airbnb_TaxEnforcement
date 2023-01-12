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
label variable HomeRule "Local Collection"
label variable homerule_salestax "Local Collection x Sales Tax"

tab metropolitanstatisticalarea, gen(msa)
global msa = r(r)
/// Variables for MSA analysis 
gen msazone = 0 
replace msazone = 1 if msa1 == 1 | msa3 == 1 | msa4 == 1 | msa6 == 1 | msa15 == 1
replace msazone = 2 if msa2 == 1 | msa5 == 1 | msa7 == 1 | msa8 == 1 | msa11 == 1 | msa12 == 1 | msa14 == 1 | msa16 == 1
replace msazone = 3 if msa9 == 1 | msa10 == 1 | msa13 == 1 | msa17 == 1 
tab msazone if msazone > 0 
label variable homerule_salestax "Local Collection x Sales Tax"


*******************************************************************************
/// Regressions: Outcomes are Logged y = log(1+y)
local varlist $outcome 
foreach var of local varlist {
/// Create the Logged outcome 
generate log`var' = ln(1 + `var')
global conditional modelmiss == 0 & msa_miss == 0
global model log`var' $taxes excisetax
reghdfe $model if ${conditional}, ${regopts}
estimates store `var'2f

/// Zone Analysis 
forvalues i=1(1)3 {
global conditional modelmiss == 0 & msa_miss == 0 & msazone == `i' 
/// Model 2. No Interaction 
tab metropolitanstatisticalarea HomeRule if msazone == `i'
global model log`var' $taxes excisetax
reghdfe $model if ${conditional}, ${regopts}
estimates store `var'2`i'
}

esttab `var'2f `var'21 `var'22 `var'23, ${tables} mtitles("Baseline" "Zone1" "Zone2" "Zone3")
esttab `var'2f `var'21 `var'22 `var'23 using "${aorm}/`var'_MSA_RC.tex", ${tables} mtitles("Baseline" "Zone1" "Zone2" "Zone3")

/// Individual MSA Analysis 

local numlist 1 6 13
foreach i of local numlist {
global conditional modelmiss == 0 & msa_miss == 0 & msa`i' == 1 
tab metropolitanstatisticalarea HomeRule if msa`i' == 1 
global model log`var' $taxes excisetax
reghdfe $model if ${conditional}, ${regopts}
estimates store `var'msa`i'
}

esttab `var'2f `var'msa1 `var'msa6 `var'msa13, ${tables} mtitles("MSA" "Boulder" "Denver" "Greeley")
esttab `var'2f `var'msa1 `var'msa6 `var'msa13 using "${aorm}/`var'_MSA_RC.tex", ${tables} mtitles("MSA" "Boulder" "Denver" "Greeley")

drop log`var'
 
}

/*

generate logrevenueperday = ln(1 + revenueperday)
/// Table of MSA stats 
matrix define M=J(17,13,.)
forvalues i=1(1)17 {
matrix M[`i',1] = `i'
// Zone 
quietly sum msazone if msa`i' == 1
matrix M[`i',2] = r(mean)
/// Number of Cities with Home Rule 
quietly distinct city if msa_miss == 0 
local msacity = r(ndistinct)
quietly distinct city if msa`i' == 1 & HomeRule == 1
matrix M[`i',3]= 100*(r(ndistinct) / `msacity')
quietly distinct city if msa`i' == 1 & HomeRule == 0 
matrix M[`i',4]= 100*(r(ndistinct) / `msacity')
///Number of Properties 
quietly distinct id if msa_miss == 0 
local msaid = r(ndistinct)
quietly distinct id if msa`i' == 1 & HomeRule == 1
matrix M[`i',5]= 100*(r(ndistinct) / `msaid')
quietly distinct id if msa`i' == 1 & HomeRule == 0 
matrix M[`i',6]= 100*(r(ndistinct) / `msaid')
/// Sales Tax Rate 
quietly sum citytaxrate if msa`i' == 1 & HomeRule == 1
matrix M[`i',7]= r(mean)
quietly sum citytaxrate if msa`i' == 1 & HomeRule == 0
matrix M[`i',8]= r(mean)
/// Average Price 
quietly sum revenueperday if msa`i' == 1 & HomeRule == 1
matrix M[`i',9]= r(mean)
quietly sum revenueperday if msa`i' == 1 & HomeRule == 0 
matrix M[`i',10]= r(mean)
}
/// Regression 
local numlist 1 2 3 4 6 7 8 9 10 11 12 13 15 16 17
foreach i of local numlist {
global conditional modelmiss == 0 & msa_miss == 0 & msa`i' == 1 
global model logrevenueperday $taxes excisetax
display `i'
reghdfe $model if ${conditional}, ${regopts}
estimates store msa`i'
matrix M[`i',11]= _b[homerule_salestax]
matrix M[`i',11]= _se[homerule_salestax]
matrix M[`i',13] = r(table)[4,1]	
}



matrix M[`i',11] = _b[homerule_salestax]
matrix M[`i',12] = _se[homerule_salestax]
matrix M[`i',13] = r(table)[4,1]

mata : st_matrix("M", sort(st_matrix("M"), 2))
matrix colnames M = "MSA" "Zone" "Cities Local" "Cities State" "Prop Local" "Prop State" "Tax Local" "Tax State" "Price Local" "Price State" "Beta" "SE" "Pval"

matrix rownames M =  "Cañon City "  "Pueblo "  "Colorado Springs "  "Boulder "  "Denver-Aurora-Lakewood "  "Craig "  "Steamboat Springs "  "Edwards "  "Glenwood Springs "  "Grand Junction "  "Montrose "  "Durango "  "Breckenridge "  "Fort Collins "  "Greeley "  "Fort Morgan "  "Sterling "
esttab matrix(M, fmt(0 0 2 2 2 2 2 2 0 0 4 4 4)), compress replace 
/*
forvalues i=1(1)17{
forvalues j=3(1)6{
matrix M[`i',`j']= 100*M[`i',`j']
}
}
*/

esttab matrix(M, fmt(0 0 2 2 2 2 2 2 0 0)) using "${aodm}/MSA_stats.tex", compress replace 
esttab matrix(M, fmt(0 0 2 2 2 2 2 2 0 0)), compress replace 

*/

/*

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

*/

