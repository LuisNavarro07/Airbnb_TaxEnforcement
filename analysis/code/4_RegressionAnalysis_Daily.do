********************************************************************************
********************************************************************************
**** State vs Local Tax Enforcement Effectiveness: Evidence from Airbnb Price Data 
**** By: Justin Ross, Whitney Afonso, Luis Navarro 
**** Last Update: Navarro, Luis 
********************************************************************************
********************************************************************************
// Regression Analysis - Daily Data 
use "${ai}/DailyDataCleanComplete.dta", clear

*tab weekend_dum, summarize(priceusd)

/// Step 4. Regression Analysis 
global coefopts1 recast(bar) citop ciopts(recast(rcap lowerlimit upperlimit barposition) lcolor(dknavy*1.2)) color(dknavy%70)
global coefopts2 recast(bar) citop ciopts(recast(rcap lowerlimit upperlimit barposition) lcolor(gray*1.2)) color(gray%70)
global coefopts3 recast(bar) citop ciopts(recast(rcap lowerlimit upperlimit barposition) lcolor(ebblue*1.2)) color(ebblue%70)
global coefopts4 recast(bar) citop ciopts(recast(rcap lowerlimit upperlimit barposition) lcolor(eltblue*1.2)) color(eltblue%70)

label variable HomeRule "Local Collection"
label variable homerule_salestax "Local Collection x Sales Tax"

/// Step 3. Do the Regressions 
gen logprice = ln(1 + priceusd)
label variable logprice "Log Price"
/// Regressions by Status
*tab status, summarize(priceusd)

// For Robustness Check 2: Generate Quadratic and Cubic Variables for the citytax rate and excise taxes  
local varlist citytaxrate excisetax
foreach var of local varlist {
gen `var'2 = `var'^2
gen `var'3 = `var'^3
}

/// Missings are at the city level. For some cities we do not have data
/// Missings from tyhe main variables in the models
global $outcome logprice 
generate modelmiss = 0 
replace modelmiss = 1 if logprice == . | citytaxrate == . 
*tab year modelmiss

/// Main Results 
********************************************************************************
/// Model Definition 
global taxes homerule_salestax citytaxrate HomeRule airbnbag

/// Model 2. Baseline (No Excise Interaction ) - All Prices 
global model logprice $taxes excisetax
reghdfe $model if modelmiss == 0, absorb(propertyid listingtype date) vce(cluster city)
estimates store price2
reghdfe $model if modelmiss == 0 & status == 3, absorb(propertyid listingtype date) vce(cluster city)
estimates store price2rent

global options_plot xline(0) xlabel(#10,angle(0) labsize(small) grid) ylabel(,labsize(vsmall)) legend(on order(1 "All Prices" 3 "Rented Prices") rows(1) cols(4) size(vsmall)) ytitle("") graphregion(margin(r+5)) graphregion(color(white)) title("Coefficient Estimates - Evidence from Prices", pos(11) size(small))

coefplot (price2, $coefopts1 barwidth(0.30)) ///
	(price2rent, $coefopts2 barwidth(0.30)), drop(_cons) ${options_plot} name(mainresprices2, replace)
graph export "${aorm}/MainResultsPrices2.png", $export 

global tables keep(${coeff}) se label replace noobs compress 
esttab price2 price2rent, ${tables} 
esttab price2 price2rent using "${aord}/MainResultsPrices2Coef.tex", ${tables} 

*graph combine mainresprices1 mainresprices2, xcommon rows(2)
*graph export "${aorm}/MainResultsPricesfull_${mod}.png", $export 

*******************************************************************************
/// Robustness Check - 2 MSA Analysis 
global regopts absorb(propertyid listingtype date) vce(cluster city)
global conditional modelmiss == 0 & msa_miss == 0
/// Model 2. Baseline (No Excise Interaction ) - All Prices 
global model logprice $taxes excisetax
/// Model 2. Baseline (No Excise Interaction )
global model logprice $taxes excisetax
reghdfe $model if ${conditional}, ${regopts}
estimates store price2msa
/// Model 1 No Excise Taxes 
global model logprice $taxes 
reghdfe $model if ${conditional}, ${regopts}
estimates store price1msa
/// Model 3. Interaction 
global model logprice $taxes excisetax excisetaxhr
reghdfe $model if ${conditional}, ${regopts}
estimates store price3msa
esttab price2msa price1msa price3msa using "${aord}/pricecoef_msaall.tex", mtitles("Baseline" "No Excise Taxes" "Excise Interaction") ${tables}
esttab price2msa price1msa price3msa, mtitles("Baseline" "No Excise Taxes" "Excise Interaction") ${tables}
******** Rented Prices *********************************************************
global conditional modelmiss == 0 & msa_miss == 0 & status == 3
/// Model 2. Baseline (No Excise Interaction )
global model logprice $taxes excisetax
reghdfe $model if ${conditional}, ${regopts}
estimates store price2msarent
/// Model 1 No Excise Taxes 
global model logprice $taxes 
reghdfe $model if ${conditional}, ${regopts}
estimates store price1msarent
/// Model 3. Interaction 
global model logprice $taxes excisetax excisetaxhr
reghdfe $model if ${conditional}, ${regopts}
estimates store price3msarent
esttab price2msarent price1msarent price3msarent using "${aord}/pricecoef_msarent.tex", mtitles("Baseline" "No Excise Taxes" "Excise Interaction") ${tables}
esttab price2msarent price1msarent price3msarent, mtitles("Baseline" "No Excise Taxes" "Excise Interaction") ${tables}
********************************************************************************
********************************************************************************
********************************************************************************
/// Robustnes Check - Analysis by MSAs Zones 
tab metropolitanstatisticalarea, gen(msa)
global msa = r(r)
/// Variables for MSA analysis 
gen msazone = 0 
replace msazone = 1 if msa1 == 1 | msa3 == 1 | msa4 == 1 | msa6 == 1 | msa15 == 1
replace msazone = 2 if msa2 == 1 | msa5 == 1 | msa7 == 1 | msa8 == 1 | msa11 == 1 | msa12 == 1 | msa14 == 1 | msa16 == 1
replace msazone = 3 if msa9 == 1 | msa10 == 1 | msa13 == 1 | msa17 == 1 
tab msazone if msazone > 0 
label variable homerule_salestax "Local Collection x Sales Tax"
/// Listed Prices 
/// Create the Logged outcome 
forvalues i=1(1)3 {
global conditional modelmiss == 0 & msa_miss == 0 & msazone == `i' 
global model logprice $taxes excisetax
reghdfe $model if ${conditional}, ${regopts}
estimates store price2`i'
}
esttab price2msa price21 price22 price23, ${tables} mtitles("Baseline" "Zone1" "Zone2" "Zone3")
esttab price2msa price21 price22 price23 using "${aord}/pricelisted_MSA_RC.tex", ${tables} mtitles("Baseline" "Zone1" "Zone2" "Zone3")


/// Rented Prices 
forvalues i=1(1)3 {
global conditional modelmiss == 0 & msa_miss == 0 & status == 3 & msazone == `i' 
global model logprice $taxes excisetax
reghdfe $model if ${conditional}, ${regopts}
estimates store pricerent2`i'
}
esttab price2msarent pricerent21 pricerent22 pricerent23, ${tables} mtitles("Baseline" "Zone1" "Zone2" "Zone3")
esttab price2msarent pricerent21 pricerent22 pricerent23 using "${aord}/pricerented_MSA_RC.tex", ${tables} mtitles("Baseline" "Zone1" "Zone2" "Zone3")

/// Only MSA 1,6 and 13 are providing variation hence are able to get estimates. 
/// For Individual MSAs 
local numlist 1 6 13
foreach i of local numlist{
tab metropolitanstatisticalarea HomeRule if msa`i' == 1
global conditional modelmiss == 0 & msa_miss == 0 & msa`i' == 1 
global model logprice $taxes excisetax
capture noisily reghdfe $model if ${conditional}, ${regopts}
capture noisily  estimates store pmsa`i'

global conditional modelmiss == 0 & msa_miss == 0 & status == 3 & msa`i' == 1 
global model logprice $taxes excisetax
capture noisily reghdfe $model if ${conditional}, ${regopts}
capture noisily estimates store prentmsa`i'
}

esttab pmsa1 pmsa6 pmsa13, ${tables} mtitles("Boulder" "Denver-Aurora-Lakewood" "Greeley")
esttab prentmsa1 prentmsa6 prentmsa13, ${tables} mtitles("Boulder" "Denver-Aurora-Lakewood" "Greeley")

esttab pmsa1 pmsa6 pmsa13 using "${aord}/pricelisted_MSA_ind_RC.tex", ${tables} mtitles("Boulder" "Denver-Aurora-Lakewood" "Greeley")
esttab prentmsa1 prentmsa6 prentmsa13 using "${aord}/pricerented_MSA_ind_RC.tex", ${tables} mtitles("Boulder" "Denver-Aurora-Lakewood" "Greeley")
********************************************************************************
********************************************************************************
********************************************************************************
/// Only Denver-Aurora-Lakewood, CO Metro Area 
/// Robustness Check - 3 
global conditional modelmiss == 0 & msa_miss == 0 & metropolitanstatisticalarea == "Denver-Aurora-Lakewood, CO Metro Area"
/// Model 2. Baseline (No Excise Interaction ) - All Prices 
/// Model 2. Baseline (No Excise Interaction )
global model logprice $taxes excisetax
reghdfe $model if ${conditional}, ${regopts}
estimates store price2denver
/// Model 1 No Excise Taxes 
global model logprice $taxes 
reghdfe $model if ${conditional}, ${regopts}
estimates store price1denver
/// Model 3. Interaction 
global model logprice $taxes excisetax excisetaxhr
reghdfe $model if ${conditional}, ${regopts}
estimates store price3denver
esttab price2denver price1denver price3denver using "${aord}/pricecoef_denverall.tex",  mtitles("Baseline" "No Excise Taxes" "Excise Interaction") ${tables}
esttab price2denver price1denver price3denver,  mtitles("Baseline" "No Excise Taxes" "Excise Interaction") ${tables}
******** Rented Prices *********************************************************
global conditional modelmiss == 0 & msa_miss == 0 & status == 3 & metropolitanstatisticalarea == "Denver-Aurora-Lakewood, CO Metro Area"
/// Model 2. Baseline (No Excise Interaction )
global model logprice $taxes excisetax
reghdfe $model if ${conditional}, ${regopts}
estimates store price2denverent
/// Model 1 No Excise Taxes 
global model logprice $taxes 
reghdfe $model if ${conditional}, ${regopts}
estimates store price1denverent
/// Model 3. Interaction 
global model logprice $taxes excisetax excisetaxhr
reghdfe $model if ${conditional}, ${regopts}
estimates store price3denverent
esttab price2denverent price3denverent price1denverent using "${aord}/pricecoef_denverrent.tex",  mtitles("Baseline" "No Excise Taxes" "Excise Interaction") ${tables}
esttab price2denverent price3denverent price1denverent,  mtitles("Baseline" "No Excise Taxes" "Excise Interaction") ${tables}



*******************************************************************************
/// Model Definition 
global taxes homerule_salestax citytaxrate HomeRule airbnbag

/// Model 2. Baseline (No Excise Interaction )
global model logprice $taxes excisetax
reghdfe $model if modelmiss == 0, absorb(propertyid listingtype date) vce(cluster city)
estimates store price2

/// Model 1 No Excise Taxes 
global model logprice $taxes 
reghdfe $model if modelmiss == 0, absorb(propertyid listingtype date) vce(cluster city)
estimates store price1

/// Model 3. Interaction 
global model logprice $taxes excisetax excisetaxhr
reghdfe $model if modelmiss == 0, absorb(propertyid listingtype date) vce(cluster city)
estimates store price3

/// Export Baseline 
global coeff homerule_salestax citytaxrate HomeRule excisetax airbnbag 
global tables keep(${coeff}) se label replace noobs compress 
esttab price1 price2 price3 using "${aord}/logprice_coefBA1.tex", mtitles("No Excise Taxes" "Baseline" "Excise Interaction") ${tables}
esttab price1 price2 price3, mtitles("No Excise Taxes" "Baseline" "Excise Interaction") ${tables}

/// Robustness Checks -- Quadratic and Cubic 
/// Model 4. Baseline Quadratic 
global model logprice $taxes excisetax citytaxrate2 excisetax2 
reghdfe $model if modelmiss == 0, absorb(propertyid listingtype date) vce(cluster city)
estimates store price2q
/// Model 5. Baseline Cubic 
global model logprice $taxes excisetax citytaxrate2 excisetax2 citytaxrate3 excisetax3
reghdfe $model if modelmiss == 0, absorb(propertyid listingtype date) vce(cluster city)
estimates store price2c

esttab price2 price2q price2c using "${aord}/logprice_RC2.tex", ${tables} mtitles("Baseline" "Quadratic" "Cubic") 
esttab price2 price2q price2c, ${tables} mtitles("Baseline" "Quadratic" "Cubic") 


********************************************************************************
//// Same Analysis, but with Rented Prices
preserve 
keep if status == 3 
/// Model Definition 
global taxes homerule_salestax citytaxrate HomeRule airbnbag
/// Model 1 No Excise Taxes 
global model logprice $taxes 
reghdfe $model if modelmiss == 0, absorb(propertyid listingtype date) vce(cluster city)
estimates store price1
/// Model 2. Baseline (No Excise Interaction )
global model logprice $taxes excisetax
reghdfe $model if modelmiss == 0, absorb(propertyid listingtype date) vce(cluster city)
estimates store price2
/// Model 3. Interaction 
global model logprice $taxes excisetax excisetaxhr
reghdfe $model if modelmiss == 0, absorb(propertyid listingtype date) vce(cluster city)
estimates store price3
/// Export Baseline 
global coeff homerule_salestax citytaxrate HomeRule excisetax airbnbag 
global tables keep(${coeff}) se label replace noobs compress 
esttab price1 price2 price3 using "${aord}/logprice_coefBA1Rented.tex", mtitles("No Excise Taxes" "Baseline" "Excise Interaction") ${tables}
esttab price1 price2 price3, mtitles("No Excise Taxes" "Baseline" "Excise Interaction") ${tables}
/// Robustness Checks -- Quadratic and Cubic 
/// Model 4. Baseline Quadratic 
global model logprice $taxes excisetax citytaxrate2 excisetax2 
reghdfe $model if modelmiss == 0, absorb(propertyid listingtype date) vce(cluster city)
estimates store price2q
/// Model 5. Baseline Cubic 
global model logprice $taxes excisetax citytaxrate2 excisetax2 citytaxrate3 excisetax3
reghdfe $model if modelmiss == 0, absorb(propertyid listingtype date) vce(cluster city)
estimates store price2c
esttab price2 price2q price2c using "${aord}/logprice_RC2Rented.tex", ${tables} mtitles("Baseline" "Quadratic" "Cubic") 
esttab price2 price2q price2c, ${tables} mtitles("Baseline" "Quadratic" "Cubic") 
restore 


*********************************************************************************

/// Poisson Regression Model 
global regsaveopts table(base, format(%9.4f) parentheses(stderr) asterisk(10 5 1) order(regvars r2 N)) replace 
global regopts absorb(propertyid listingtype date) vce(cluster city)
global conditional modelmiss == 0 
/// Model Definition 
/// Model 1 No Excise Taxes 
global model priceusd $taxes 
ppmlhdfe $model if ${conditional}, ${regopts}
estimates store pricepoisson1
regsave using "${aodm}/price_t1poisson.dta", ${regsaveopts}
/// Model 2. No Interaction 
global model priceusd $taxes excisetax
ppmlhdfe $model if ${conditional}, ${regopts}
estimates store pricepoisson2
regsave using "${aodm}/price_t2poisson.dta", ${regsaveopts}
/// Model 3. City and Property Fixed Effects 
global model priceusd $taxes excisetax excisetaxhr
ppmlhdfe $model if ${conditional}, ${regopts}
estimates store pricepoisson3
regsave using "${aodm}/price_t3poisson.dta", ${regsaveopts}
esttab pricepoisson2 pricepoisson1 pricepoisson3 using "${aodm}/price_coefpoisson.tex", mtitles("Baseline" "No Excise Taxes" "Excise Interaction") ${tables}

/// Rented Prices 
global conditional modelmiss == 0 & status == 3
/// Model Definition 
/// Model 1 No Excise Taxes 
global model priceusd $taxes 
ppmlhdfe $model if ${conditional}, ${regopts}
estimates store pricepoissonrent1
regsave using "${aodm}/pricerent_t1poisson.dta", ${regsaveopts}
/// Model 2. No Interaction 
global model priceusd $taxes excisetax
ppmlhdfe $model if ${conditional}, ${regopts}
estimates store pricepoissonrent2
regsave using "${aodm}/pricerent_t2poisson.dta", ${regsaveopts}
/// Model 3. City and Property Fixed Effects 
global model priceusd $taxes excisetax excisetaxhr
ppmlhdfe $model if ${conditional}, ${regopts}
estimates store pricepoissonrent3
regsave using "${aodm}/pricerent_t3poisson.dta", ${regsaveopts}
esttab pricepoissonrent2 pricepoissonrent1 pricepoissonrent3 using "${aodm}/pricerent_coefpoisson.tex", mtitles("Baseline" "No Excise Taxes" "Excise Interaction") ${tables}
