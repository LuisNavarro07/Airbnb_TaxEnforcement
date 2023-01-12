********************************************************************************
********************************************************************************
**** State vs Local Tax Enforcement Effectiveness: Evidence from Airbnb Price Data 
**** By: Justin Ross, Whitney Afonso, Luis Navarro 
**** Last Update: Navarro, Luis 
********************************************************************************
********************************************************************************
// Regression Analysis - Daily Data (aux)
/// Model Definition 
global model $outcome ${taxes} ${controls}
/// Model 1: OLS 
regress $model if modelmiss == 0, vce(cluster city)
estimates store model1_f
/// Model 2: City and Month Fixed Effects
reghdfe $model if modelmiss == 0 , absorb(city listingtype date) vce(cluster city)
estimates store model2_f
/// Model 4 City and Property Fixed Effects 
global model $outcome ${taxes} 
reghdfe $model if modelmiss == 0, absorb(propertyid listingtype date) vce(cluster city)
estimates store model3_f

esttab model1_f model2_f model3_f, keep(${taxes}) se label mtitles("OLS" "FE-City" "FE-Property") replace 
esttab model1_f model2_f model3_f using "${aord}/RegressionDailyPrices.tex", keep(${taxes}) se label mtitles("OLS" "FE-City" "FE-Property") replace 

// By Status 
/// Define the model
global model $outcome ${taxes}
reghdfe $model if modelmiss == 0, absorb(propertyid date listingtype) vce(cluster city)
estimates store status0
forvalues i = 1(1)4{
reghdfe $model if modelmiss == 0 & status == `i', absorb(propertyid date listingtype) vce(cluster city)
estimates store status`i'
}

esttab status0 status1 status2 status3 , keep(${taxes}) se label mtitles("All" "Available" "Booked" "Rented") replace 
esttab status0 status1 status2 status3 using "${aord}/RegressionDailyByStatus.tex", keep(${taxes}) se label mtitles("All" "Available" "Booked" "Rented") replace 

/// I would suggest to do the models only in the subset of the sample for rented data. It makes more sense to do this considering it is a market equilibrium outcome. 
*tab status if status == 3
/// 3 is for rented data 
/*
// Do all the regressions across different status 
forvalues i=1(1)4{
	
/// Model Definition 
global model $outcome ${taxes} ${controls}
/// Model 1: OLS 
regress $model if modelmiss == 0 & status == `i' , vce(cluster city)
estimates store model1_`i'
/// Model 2: City and Month Fixed Effects
reghdfe $model if modelmiss == 0 & status == `i' , absorb(city listingtype date) vce(cluster city)
estimates store model2_`i'
/// Model 4 City and Property Fixed Effects 
global model $outcome ${taxes} 
reghdfe $model if modelmiss == 0 & status == `i' , absorb(propertyid listingtype date) vce(cluster city)
estimates store model3_`i'

esttab model1_`i' model2_`i' model3_`i', keep(${taxes}) se label mtitles("OLS" "FE-City" "FE-Property") replace 
esttab model1_`i' model2_`i' model3_`i' using "${aord}/RegressionDailyRented`i'.tex", keep(${taxes}) se label mtitles("OLS" "FE-City" "FE-Property") replace 


/*
global options_plot xline(0) xlabel(#10,angle(0) labsize(small) grid) ylabel(,labsize(vsmall)) legend(on order(1 "OLS" 3 "FE-City" 5 "FE-Property") rows(1) cols(4) size(vsmall)) ytitle("") graphregion(margin(r+5)) graphregion(color(white)) 

coefplot (model1_`i', $coefopts1 barwidth(0.2)) ///
	(model2_`i', $coefopts2 barwidth(0.2)) ///
	(model3_`i', $coefopts3 barwidth(0.2)), keep(homerule_salestax citytaxrate HomeRule) ${options_plot} name(RegRentDaily`i', replace) title("Coefficient Estimates- Daily Price - Status `i'", pos(11) size(medsmall) color(black)) 
graph export "${aord}/RentedModels`i'.png", $export 

/// Export Graphs 
coefplot (model1_`i' , $coefopts1 barwidth(0.2)) ///
	(model2_`i' , $coefopts2 barwidth(0.2)) ///
	(model3_`i' , $coefopts3 barwidth(0.2)), keep(homerule_salestax citytaxrate HomeRule) ${options_plot} name(RegRentDailyComb, replace) title("Coefficient Estimates- Daily Price ", pos(11) size(medsmall) color(black)) 
graph export "${aord}/RentedModels`i'.png", $export 
*/
}


***********************************************************************************
///// Modell with all prices, do not differentiaing the status 
/// Model Definition 
global model $outcome ${taxes} ${controls} 
/// Model 1: OLS 
regress $model if modelmiss == 0 , vce(cluster city)
estimates store model1full
/// Model 2: City and Month Fixed Effects
reghdfe $model if modelmiss == 0 , absorb(city listingtype date) vce(cluster city)
estimates store model2full
/// Model 4 City and Property Fixed Effects 
global model $outcome ${taxes}
reghdfe $model if modelmiss == 0 , absorb(propertyid listingtype date) vce(cluster city)
estimates store model3full

esttab model1full model2full model3full, drop(_cons) se label mtitles("OLS" "FE-City" "FE-Property") replace 
esttab model1full model2full model3full using "${aord}/RegressionDailyRentedFull.tex", keep(homerule_salestax citytaxrate HomeRule) se label mtitles("OLS" "FE-City" "FE-Property") replace 

/*
global options_plot xline(0) xlabel(#10,angle(0) labsize(small) grid) ylabel(,labsize(vsmall)) legend(on order(1 "All" 3 "Available" 5 "Booked" 7 "Rented" 9 "Unavailable") rows(1) cols(4) size(vsmall)) ytitle("") graphregion(margin(r+5)) graphregion(color(white)) 

coefplot (status0, $coefopts1 barwidth(0.1)) ///
	(status1, $coefopts2 barwidth(0.1)) ///
	(status2, $coefopts3 barwidth(0.1)) ///
	(status3, $coefopts4 barwidth(0.1)) ///
	(status4, $coefopts5 barwidth(0.1)), keep(homerule_salestax citytaxrate HomeRule) ${options_plot} name(RegByStatus1, replace) title("Daily Price by Unit Status", pos(11) size(medsmall) color(black)) 
graph export "${aord}/RegressionByStatus.png", $export 
 


/// Export Graphs 
coefplot (model1full , $coefopts1 barwidth(0.2)) ///
	(model2full , $coefopts2 barwidth(0.2)) ///
	(model3full , $coefopts3 barwidth(0.2)), keep(homerule_salestax citytaxrate HomeRule) ${options_plot} name(RegRentDailyComb, replace) title("Coefficient Estimates- Daily Data - All Status", pos(11) size(medsmall) color(black)) 
graph export "${aord}/RentedModelsFull.png", $export 
*/

***********************************************************************************
/// Collapse the dataset to have monthly observations 
/*
preserve 
gcollapse (mean) $outcome citytaxrate, by(monthlydate)
twoway (line $outcome monthlydate, sort lcolor(black) lwidth(thin))(line citytaxrate monthlydate, sort lcolor(navy) lwidth(thin) yaxis(2)), xlabel(#10, grid labsize(medsmall) angle(90) axis(1)) ylabel(#10, grid labsize(medsmall) angle(0) axis(1)) ylabel(#10, grid labsize(medsmall) angle(0) axis(2)) xtitle("Date", size(medsmall)) ytitle("Daily Price", size(medsmall) axis(1)) ytitle("Local Sales Tax Rate", size(medsmall) axis(2)) legend(on order(1 "Daily Price" 2 "Local Sales Tax Rate") rows(1) size(medsmall)) title("Average Daily Price and Local Sales Tax Rate", size(medsmall) pos(11)) name(PriceTaxComb, replace)
graph export "${aord}/PriceTaxCombinedDaily.png", $export 
restore 

/// Collapse the dataset to monthly data for consistency with the revenue dataset 
preserve 
gcollapse (mean) $outcome homerule_salestax citytaxrate HomeRule listingtype overallrating minimumstay maxguests, by(propertyid monthlydate)
format monthlydate %tm_m_CY
label variable homerule_salestax "Home Rule Sales Tax Interaction"
label variable citytaxrate "Sales Tax Rate"
label variable HomeRule "Home Rule"

/// Model Definition 
global model $outcome homerule_salestax citytaxrate HomeRule i.listingtype overallrating minimumstay maxguests

/// Model 1: OLS 
regress $model, vce(cluster city)
estimates store m1
/// Model 2: City and Month Fixed Effects
reghdfe $model, absorb(city monthlydate) vce(cluster city)
estimates store m2
/// Model 4 City and Property Fixed Effects 
global model $outcome homerule_salestax citytaxrate HomeRule 
reghdfe $model, absorb(propertyid monthlydate) vce(cluster city)
estimates store m3


global coefopts1 recast(bar) citop ciopts(recast(rcap lowerlimit upperlimit barposition) lcolor(dknavy*1.2)) color(dknavy%70)
global coefopts2 recast(bar) citop ciopts(recast(rcap lowerlimit upperlimit barposition) lcolor(gray*1.2)) color(gray%70)
global coefopts3 recast(bar) citop ciopts(recast(rcap lowerlimit upperlimit barposition) lcolor(ebblue*1.2)) color(ebblue%70)
global coefopts4 recast(bar) citop ciopts(recast(rcap lowerlimit upperlimit barposition) lcolor(eltblue*1.2)) color(eltblue%70)


global options_plot xline(0) xlabel(#10,angle(0) labsize(small) grid) ylabel(,labsize(vsmall)) legend(on order(1 "OLS" 3 "FE-City" 5 "FE-Property") rows(1) cols(4) size(vsmall))  ytitle("") graphregion(margin(r+5)) graphregion(color(white)) 

/// Counties 
coefplot (m1, $coefopts1 barwidth(0.24)) (m2, $coefopts2 barwidth(0.24)) (m3, $coefopts3 barwidth(0.24)), keep(homerule_salestax citytaxrate HomeRule) ${options_plot} name(MonthPrices, replace) title("Coefficient Estimates - Monthly Prices", pos(11) size(medsmall) color(black)) 
*graph export "${aord}\ModelResults.png", $export 

coefplot (month1, $coefopts1 barwidth(0.24)) (month2, $coefopts2 barwidth(0.24)) (month3, $coefopts3 barwidth(0.24)), keep(homerule_salestax citytaxrate HomeRule) ${options_plot} name(MonthRevenue, replace) title("Coefficient Estimates - Monthly Revenue", pos(11) size(medsmall) color(black)) 
*graph export "${aord}\ModelResults.png", $export 

grc1leg MonthPrices MonthRevenue, rows(2) legendfrom(MonthRevenue) xcommon 
graph export "${aord}/ModelsComparisonMonthlyPricesRevenue.png", $export 

restore 
*/
*/
