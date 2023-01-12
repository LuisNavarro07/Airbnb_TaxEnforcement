********************************************************************************
********************************************************************************
**** State vs Local Tax Enforcement Effectiveness: Evidence from Airbnb Price Data 
**** By: Justin Ross, Whitney Afonso, Luis Navarro 
**** Last Update: Navarro, Luis 
********************************************************************************
********************************************************************************
// Regression Analysis - Monthly Data 
// Define the right subset for the analysis 
clear all 
/// Open DataSet
use "${ai}/ColoradoPropertyMonthlyMerge.dta", clear

// For Robustness Check 2: Generate Quadratic and Cubic Variables for the citytax rate and excise taxes  
local varlist citytaxrate excisetax
foreach var of local varlist {
gen `var'2 = `var'^2
gen `var'3 = `var'^3
}

/// Estimate the Regression Models
/// First Scenario (Robustness Check 1): Exclude the Airbnb Tax Agreement 
global taxes homerule_salestax citytaxrate HomeRule
global coeff homerule_salestax citytaxrate HomeRule excisetax 
global tables keep(${coeff}) se label replace noobs compress 
global mod RC1
do "${ac}/RegressionEstimation.do"

/// Third Scenario (Robustness Check 2): Non Linear Relation in the Tax Rates 
global taxes homerule_salestax citytaxrate HomeRule airbnbag excisetax
global coeff homerule_salestax citytaxrate HomeRule excisetax airbnbag 
global tables keep(${coeff}) se label replace noobs compress 
global mod RC2
do "${ac}/NonLinearRegression.do" 

/// Robustness Checks 
global taxes homerule_salestax citytaxrate HomeRule airbnbag
global coeff homerule_salestax citytaxrate HomeRule excisetax airbnbag 
global tables keep(${coeff}) se label replace noobs compress 
global mod RC3
do "${ac}/RegressionEstimationRC.do" 

/// Robustness Check - Analysis by MSA  
global taxes homerule_salestax citytaxrate HomeRule airbnbag
global coeff homerule_salestax citytaxrate HomeRule excisetax airbnbag 
global tables keep(${coeff}) se label replace noobs compress 
global mod RCMSA
do "${ac}/RegressionEstimationMSA.do" 

/// Second Scenario (Baseline): Include the Airbnb Tax Agreement 
global taxes homerule_salestax citytaxrate HomeRule airbnbag
global coeff homerule_salestax citytaxrate HomeRule excisetax airbnbag 
global tables keep(${coeff}) se label replace noobs compress 
global mod BA1
do "${ac}/RegressionEstimation.do" 



********************************************************************************
********************************************************************************
//// Probability Model 
// Step 1. Get the Fillin and Xfill code working. 
global results _est_reservationdays3log _est_revenueperday1log _est_revenueperday3log _est_totaldays1log _est_totaldays3log _est_reservationdays1log _est_revenueperday2log _est_totaldays2log _est_reservationdays2log
drop _merge
fillin propertyid reportingmonth 
keep propertyid reportingmonth monthlydate revenueperday totaldays _fillin FIPS city metropolitanstatisticalarea listingtype 
gen year = real(substr(reportingmonth,1,4))
gen month_scrape = real(substr(reportingmonth,6,2))
gen semester = .
replace semester = 1 if month_scrape <= 6 
replace semester = 2 if month_scrape > 6
sort propertyid reportingmonth
egen id = group(propertyid)
xtset id 
xfill $controls city FIPS listingtype metropolitanstatisticalarea, i(id)
global dimensions semester year FIPS city 
merge m:1 $dimensions using "${bt}/ColoradoSalesTaxClean.dta", keep(match master)
// I NEED TO SEE WHY SOME OBSERVATIONS ARE NOT BEING MATCHED 
drop if _merge == 1
drop _merge 

// Step 3. Generate the Binary Outcome 
generate listed = . 
replace listed = 0 if _fillin == 1 
replace listed = 1 if _fillin == 0 

// run the model with xtlogit 
/// Generate MonthlyDate
gen date2 = date(reportingmonth, "YMD")
format date2 %td
drop monthlydate 
gen monthlydate = mofd(date2)
format monthlydate %tm
xtset id monthlydate 


/// Quadratic Variables for Robustness Checks 
// Generate Quadratic and Cubic Variables for the citytax rate and excise taxes  
local varlist citytaxrate excisetax
foreach var of local varlist {
gen `var'2 = `var'^2
gen `var'3 = `var'^3
}

global taxes homerule_salestax citytaxrate HomeRule airbnbag

/// Step 3. Do the Regressions 
/// Outcomes 

/// Model Definition 
/// Model 1 No Excise Taxes 
global model listed $taxes 
reghdfe $model, absorb(propertyid listingtype monthlydate) vce(cluster city)
estimates store lin1
xtlogit $model, fe 
estimates store log1
/// Model 2. Baseline (No Excise Interaction )
global model listed $taxes excisetax
reghdfe $model, absorb(propertyid listingtype monthlydate) vce(cluster city)
estimates store lin2
xtlogit $model, fe 
estimates store log2
/// Model 3. Interaction 
global model listed $taxes excisetax excisetaxhr
reghdfe $model, absorb(propertyid listingtype monthlydate) vce(cluster city)
estimates store lin3
xtlogit $model, fe 
estimates store log3
esttab lin1 lin2 lin3 using "${aorm}/BinaryLinear.tex", mtitles("No Excise Taxes" "Baseline" "Excise Interaction") ${tables}
esttab log1 log2 log3 using "${aorm}/BinaryLogit.tex", mtitles("No Excise Taxes" "Baseline" "Excise Interaction") ${tables}

********************************************************************************
/// MSA by Zone Analysis 
tab metropolitanstatisticalarea, gen(msa)
global msa = r(r)
/// Variables for MSA analysis 
gen msazone = 0 
replace msazone = 1 if msa1 == 1 | msa3 == 1 | msa4 == 1 | msa6 == 1 | msa15 == 1
replace msazone = 2 if msa2 == 1 | msa5 == 1 | msa7 == 1 | msa8 == 1 | msa11 == 1 | msa12 == 1 | msa14 == 1 | msa16 == 1
replace msazone = 3 if msa9 == 1 | msa10 == 1 | msa13 == 1 | msa17 == 1 
label variable homerule_salestax "Local Collection x Sales Tax"

gen msa_miss = 0 
replace msa_miss = 1 if metropolitanstatisticalarea == ""

global model listed $taxes excisetax
global regopts absorb(propertyid listingtype monthlydate) vce(cluster city)
/// Model All MSAs 
/*
global conditional msa_miss == 0
reghdfe $model if ${conditional}, ${regopts}
estimates store lin2msa
xtlogit $model if ${conditional}, fe 
estimates store log2msa

/// Models by Zone 
forvalues i=1(1)3 {
global conditional msa_miss == 0 & msazone == `i' 
reghdfe $model if ${conditional}, ${regopts}
estimates store lin2msa`i'
xtlogit $model if ${conditional}, fe 
estimates store log2msa`i'
}

/// Export the Results 
esttab lin2 lin2msa lin2msa1 lin2msa2 lin2msa3, ${tables} mtitles("Baseline" "MSAs" "Zone1" "Zone2" "Zone3")
esttab lin2 lin2msa lin2msa1 lin2msa2 lin2msa3 using "${aorm}/ListedLinear_MSA_RC.tex", ${tables} mtitles("Baseline"  "Zone1" "Zone2" "Zone3")

esttab log2 log2msa log2msa1 log2msa2 log2msa3, ${tables} mtitles("Baseline" "MSAs" "Zone1" "Zone2" "Zone3")
esttab log2 log2msa log2msa1 log2msa2 log2msa3 using "${aorm}/ListedLogit_MSA_RC.tex", ${tables} mtitles("Baseline"  "Zone1" "Zone2" "Zone3")
*/
/// Models by Specific Zone 
local numlist 1 6 13
foreach i of local numlist {
global conditional msa_miss == 0 & msa`i' == 1 
reghdfe $model if ${conditional}, ${regopts}
estimates store lin_indmsa`i'
xtlogit $model if ${conditional}, fe 
estimates store log_indmsa`i'
}

/// Export the Results 
esttab lin2 lin_indmsa1 lin_indmsa6 lin_indmsa13, ${tables} mtitles("Baseline" "Boulder" "Denver" "Greeley")
esttab lin2 lin_indmsa1 lin_indmsa6 lin_indmsa13 using "${aorm}/ListedLinear_ind_MSA_RC.tex", ${tables} mtitles("Baseline" "Boulder" "Denver" "Greeley")

esttab log2 log_indmsa1 log_indmsa6 log_indmsa13, ${tables} mtitles("Baseline" "Boulder" "Denver" "Greeley")
esttab log2 log_indmsa1 log_indmsa6 log_indmsa13 using "${aorm}/ListedLogit_ind_MSA_RC.tex", ${tables} mtitles("Baseline" "Boulder" "Denver" "Greeley")

********************************************************************************
/// Robustness Checks 
/// Quadratic 
global model listed $taxes excisetax citytaxrate2 excisetax2
reghdfe $model, absorb(propertyid listingtype monthlydate) vce(cluster city)
estimates store lin2q
xtlogit $model, fe 
estimates store log2q
/// Cubic 
global model listed $taxes excisetax citytaxrate2 excisetax2 citytaxrate3 excisetax3
reghdfe $model, absorb(propertyid listingtype monthlydate) vce(cluster city)
estimates store lin2c
xtlogit $model, fe 
estimates store log2c

esttab lin2 lin2q lin2c using "${aorm}/BinaryLinearRobust.tex", mtitles("Baseline" "Quadratic" "Cubic") ${tables}
esttab log2 log2q log2c using "${aorm}/BinaryLogitRobust.tex", mtitles("Baseline" "Quadratic" "Cubic") ${tables}

******************************************************************************

label variable homerule_salestax "Local Collection x Sales Tax"
label variable airbnbag "Airbnb Collection Agreement"
global coefopts1 recast(bar) citop ciopts(recast(rcap lowerlimit upperlimit barposition) lcolor(dknavy*1.2)) color(dknavy%70)
global coefopts2 recast(bar) citop ciopts(recast(rcap lowerlimit upperlimit barposition) lcolor(edkblue*1.2)) color(edkblue%70)
global coefopts3 recast(bar) citop ciopts(recast(rcap lowerlimit upperlimit barposition) lcolor(ebblue*1.2)) color(ebblue%70)
global coefopts4 recast(bar) citop ciopts(recast(rcap lowerlimit upperlimit barposition) lcolor(ltblue*1.2)) color(ltblue%70)

global options_plot xline(0) xlabel(#10,angle(0) labsize(small) grid) ylabel(,labsize(vsmall)) legend(on order(1 "Listed Days" 3 "Rented Days" 5 "Any Days - LPM" 7 "Any Days - Logit") rows(2) cols(4) size(vsmall)) ytitle("") graphregion(margin(r+5)) graphregion(color(white)) title("Coefficient Estimates - Evidence from Quantities", pos(11) size(small))

coefplot (totaldays2log, $coefopts1 barwidth(0.22)) ///
	(reservationdays2log, $coefopts2 barwidth(0.22)) ///
	(lin2, $coefopts3 barwidth(0.22)) ///
	(log2, $coefopts4 barwidth(0.22)), drop(_cons) ${options_plot} name(mainresquant, replace)
graph export "${aorm}/MainResultsQuantities_${mod}.png", $export 


/*
/// Options for Coefplots 
global options_plot xline(0) xlabel(#10,angle(0) labsize(small) grid) ylabel(,labsize(vsmall)) legend(on order(1 "Linear" 3 "Logit") rows(1) cols(4) size(vsmall)) ytitle("") graphregion(margin(r+5)) graphregion(color(white)) 
global coefopts1 recast(bar) citop ciopts(recast(rcap lowerlimit upperlimit barposition) lcolor(dknavy*1.2)) color(dknavy%70)
global coefopts2 recast(bar) citop ciopts(recast(rcap lowerlimit upperlimit barposition) lcolor(gray*1.2)) color(gray%70)
global coefopts3 recast(bar) citop ciopts(recast(rcap lowerlimit upperlimit barposition) lcolor(ebblue*1.2)) color(ebblue%70)

coefplot (binary3, $coefopts1 barwidth(0.2)) ///
	(binary2fe, $coefopts2 barwidth(0.2)), keep($taxes) ${options_plot} name(RegMonth, replace) title("Coefficient Estimates - Probability Models", pos(11) size(medsmall) color(black)) 
graph export "${aorm}/RegressionMonthlyBinaryOutcome.png", $export 
*/


keep _est_revenueperday1log _est_revenueperday3log _est_revenueperday2log 
save "${at}/monthrevres.dta", replace  

keep id msa_miss msazone metropolitanstatisticalarea city monthlydate propertyid listingtype listed $taxes excisetax msa* _est_lin2msa _est_lin2msa1 _est_lin2msa2 _est_lin2msa3 _est_log2msa _est_log2msa1 _est_log2msa2 _est_log2msa3
save "${at}/msanonlinearesults.dta", replace 
