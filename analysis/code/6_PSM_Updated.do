/// 6_ Propensity Score Matching and Stacking the Datasets 
/// Controls for PSM
/* 
preserve 
import delimited "${bi}/us_Property_Match_2020-02-11.csv", varnames(1) clear 
keep propertyid propertytype bedrooms bathrooms maxguests airbnbsuperhost homeawaypremierpartner cancellationpolicy securitydepositusd cleaningfeeusd extrapeoplefeeusd publishednightlyrateusd minimumstay numberofreviews numberofphotos overallrating instantbookenabled airbnbhostid
save "${bt}/propertyid_synthcontrols.dta", replace 
restore 
*/

/// Estimate the Propensity Score For Each Sub Experiment 
forvalues j=3(1)5{
use "${bt}\SubExperiment`j'.dta", clear 
merge m:1 propertyid using "${bt}/propertyid_synthcontrols.dta", keep(match master) nogen
//// Estimate Propensity Score 
encode airbnbsuperhost, gen(superhost)
tab treated
logit treated bedrooms maxguests numberofphotos i.listingtype i.superhost, robust
estimates store pscorelogit
predict phat
generate pweight =1/phat
drop if missing(phat)
gen experiment = `j'
save "${bt}\SubExperimentPSM`j'.dta", replace 
}

/// Step 4. Stack the data 
use "${bt}\SubExperimentPSM3.dta", clear 
append using "${bt}\SubExperimentPSM4.dta"
append using "${bt}\SubExperimentPSM5.dta"
/// We create a fake id to do an xtset  
egen expid = group(id experiment)
tab et treated

xtset expid et 
gen post = 1 if et > 0 
replace post = 0 if post == . 
tab et post 
** Event Study -- Stacked DID 
tab treated post 
gen treatment = treated*citytaxrate
/// Treatment is equal to zero in the pre-treatment period 
replace treatment = 0 if post == 0
label variable treatment "0"
sort expid et
/// Lags
forvalues k = 1(1)11 {
sort expid et
gen lag`k' = L`k'.treatment
replace lag`k' = 0 if lag`k' == .
label variable lag`k' "`k'"
}

/// Reference Group
gen lead1 = 0
label variable lead1 "-1"
/// Leads 
sort expid et
forvalues k = 2(1)11 {
sort expid et
gen lead`k' = F`k'.treatment
replace lead`k' = 0 if lead`k' == .
label variable lead`k' "-`k'"
}

clonevar lead0 = treatment
global events lead11 lead10 lead9 lead8 lead7 lead6 lead5 lead4 lead3 lead2 lead1 lead0 lag1 lag2 lag3 lag4 lag5 lag6 lag7 lag8 lag9 lag10 lag11
global pretrends lead11 lead10 lead9 lead8 lead7 lead6 lead5 lead4 lead3 lead2 lead1

// Event Study 
reghdfe logdays $events [pweight = pweight], vce(cluster id) absorb(et expid experiment)
estimates store event 
test $pretrends
global fval = round(r(p),0.0001)

global title title(,pos(11) size(3) color(black))
global back plotregion(color()) graphregion(color() margin(4 4 4 4)) plotregion(lcolor(black)) 
global graph_options ytitle(, size(vsmall)) ylabel(#8, nogrid labsize(vsmall) angle(0)) xtitle(, size(small)) xlabel(, labsize(vsmall) angle(90) nogrid) title(, size(small) pos(11) color(black)) xsca(titlegap(*-.5)) ysca(titlegap(*-3)) plotregion(lcolor()) xtitle("") ytitle("") $back
global line1 lcolor("105 3 4") lwidth(medthin) mcolor("105 3 4") msize(vsmall)
global coefopts vertical drop(_cons) recast(connected) $line1 ylabel(#10, labsize(vsmall) angle(0) nogrid) yline(0,lcolor(black) lpattern(dash) lwidth(vthin)) xline(11,lcolor(black) lpattern(dash) lwidth(vthin)) ciopts(recast(rcap) color("105 3 4") fintensity(inten20)) xlabel(,angle(90)) $graph_options

coefplot event, $coefopts name(LogDays, replace) title("Event Study - Log Reservation Days") base omitted text(-0.0015 13.0 "Pre-Trends F-Test: ${fval}", place(e) size(vsmall) color(black)) $title
graph export "${ao}\EventStudyStacked_Days.png", $export 

save "${bt}\SubExperimentPSMall.dta", replace 
