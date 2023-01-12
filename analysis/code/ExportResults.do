********************************************************************************
********************************************************************************
**** State vs Local Tax Enforcement Effectiveness: Evidence from Airbnb Price Data 
**** By: Justin Ross, Whitney Afonso, Luis Navarro 
**** Last Update: Navarro, Luis 
********************************************************************************
********************************************************************************
// Regression Estimation 

// Table 1
esttab month1 month2 month3, keep(${taxes}) se label mtitles("OLS" "FE-City" "FE-Property") replace 
esttab month1 month2 month3 using "${aorm}/RegressionMonthly.tex", keep(${taxes}) se label mtitles("OLS" "FE-City" "FE-Property") replace 

/// Table 2
esttab month1 month2 month3 totaldays1 totaldays2 totaldays3, keep(${taxes}) se label mtitles("DR:OLS" "DR:FE-City" "DR:FE-Property" "TD: OLS" "TD:FE-City" "TD:FE-Property") replace 
esttab month1 month2 month3 totaldays1 totaldays2 totaldays3 using "${aorm}/RegressionMonthly_PriceQuantityCoefficients.tex", keep(${taxes}) se label mtitles("DR:OLS" "DR:FE-City" "DR:FE-Property" "TD: OLS" "TD:FE-City" "TD:FE-Property") replace 

/// Table 3
esttab revenueperday1log revenueperday2log revenueperday3log totaldays1log totaldays2log totaldays3log, keep(${taxes}) se label mtitles("DR:OLS" "DR:FE-City" "DR:FE-Property" "Quant: OLS" "Quant:FE-City" "Quant:FE-Property") replace 
esttab revenueperday1log revenueperday2log revenueperday3log totaldays1log totaldays2log totaldays3log using "${aorm}/RegressionMonthly_LogPriceQuantityCoefficients.tex", keep(${taxes}) se label mtitles("DR:OLS" "DR:FE-City" "DR:FE-Property" "TD: OLS" "TD:FE-City" "TD:FE-Property") replace 

/// Options for Coefplots 
global options_plot xline(0) xlabel(#10,angle(0) labsize(small) grid) ylabel(,labsize(vsmall)) legend(on order(1 "OLS" 3 "FE-City" 5 "FE-Property") rows(1) cols(4) size(vsmall)) ytitle("") graphregion(margin(r+5)) graphregion(color(white)) 
global coefopts1 recast(bar) citop ciopts(recast(rcap lowerlimit upperlimit barposition) lcolor(dknavy*1.2)) color(dknavy%70)
global coefopts2 recast(bar) citop ciopts(recast(rcap lowerlimit upperlimit barposition) lcolor(gray*1.2)) color(gray%70)
global coefopts3 recast(bar) citop ciopts(recast(rcap lowerlimit upperlimit barposition) lcolor(ebblue*1.2)) color(ebblue%70)
global coefopts4 recast(bar) citop ciopts(recast(rcap lowerlimit upperlimit barposition) lcolor(eltblue*1.2)) color(eltblue%70)
global coefopts5 recast(bar) citop ciopts(recast(rcap lowerlimit upperlimit barposition) lcolor(edkblue*1.2)) color(edkblue%70)
global coefopts6 recast(bar) citop ciopts(recast(rcap lowerlimit upperlimit barposition) lcolor(emidblue*1.2)) color(emidblue%70)

/// Figure 1 
coefplot (month1, $coefopts1 barwidth(0.2)) ///
	(month2, $coefopts2 barwidth(0.2)) ///
	(month3, $coefopts3 barwidth(0.2)), keep(${taxes}) ${options_plot} name(RegMonth, replace) title("Daily Revenue Regression", pos(11) size(medsmall) color(black)) 
graph export "${aorm}/RegressionMonthly.png", $export 

/// Figure 2
global options_plot xline(0) xlabel(#10,angle(0) labsize(small) grid) ylabel(,labsize(vsmall)) ytitle("") graphregion(margin(r+5)) graphregion(color(white)) legend(on order(1 "Res: OLS" 3 "Res: FE-City" 5 "Res: FE-Property" 7 "Tot: OLS" 9 "Tot: FE-City" 11 "Tot: FE-Property") rows(2) cols(3) size(vsmall))

coefplot (reservationdays1, $coefopts1 barwidth(0.12)) ///
	(reservationdays2, $coefopts2 barwidth(0.12)) ///
	(reservationdays3, $coefopts3 barwidth(0.12)) ///
	(totaldays1, $coefopts4 barwidth(0.12)) ///
	(totaldays2, $coefopts5 barwidth(0.12)) ///
	(totaldays3, $coefopts6 barwidth(0.12)), keep(homerule_salestax excisetaxhr) ${options_plot} name(`var', replace) title("Coefficient Estimates Interaction Term - Monthly Revenue", pos(11) size(medsmall) color(black)) 
graph export "${aorm}/RegressionMonthly_InteractionTermsQuantity.png", $export 

/// Figure 3 
global options_plot xline(0) xlabel(#10,angle(0) labsize(small) grid) ylabel(,labsize(vsmall)) legend(on order(1 "OLS" 3 "FE-City" 5 "FE-Property") rows(1) cols(4) size(vsmall)) ytitle("") graphregion(margin(r+5)) graphregion(color(white)) 

coefplot (month1, $coefopts1 barwidth(0.12)) ///
	(month2, $coefopts2 barwidth(0.12)) ///
	(month3, $coefopts3 barwidth(0.12)), keep(homerule_salestax excisetaxhr) ${options_plot} name(Price, replace) title("Coefficient Estimates - Price Regression", pos(11) size(medsmall) color(black)) 
	
coefplot (totaldays1, $coefopts1 barwidth(0.12)) ///
	(totaldays2, $coefopts2 barwidth(0.12)) ///
	(totaldays3, $coefopts3 barwidth(0.12)), keep(homerule_salestax excisetaxhr) ${options_plot} name(Quant, replace) title("Coefficient Estimates - Quantity Regression", pos(11) size(medsmall) color(black)) 
grc1leg Price Quant, rows(2) legendfrom(Price)
graph export "${aorm}/RegressionMonthly_PriceQuantityCoefficients.png", $export 

/// Figure 4. 
global options_plot xline(0) xlabel(#10,angle(0) labsize(small) grid) ylabel(,labsize(vsmall)) legend(on order(1 "OLS" 3 "FE-City" 5 "FE-Property") rows(1) cols(4) size(vsmall)) ytitle("") graphregion(margin(r+5)) graphregion(color(white)) 

coefplot (revenueperday1log, $coefopts1 barwidth(0.12)) ///
	(revenueperday2log, $coefopts2 barwidth(0.12)) ///
	(revenueperday3log, $coefopts3 barwidth(0.12)), keep(homerule_salestax excisetaxhr) ${options_plot} name(Price, replace) title("Coefficient Estimates - Log Daily Revenue Regression", pos(11) size(medsmall) color(black)) 
	
coefplot (totaldays1log, $coefopts1 barwidth(0.12)) ///
	(totaldays2log, $coefopts2 barwidth(0.12)) ///
	(totaldays3log, $coefopts3 barwidth(0.12)), keep(homerule_salestax excisetaxhr) ${options_plot} name(Quant, replace) title("Coefficient Estimates - Log Total Days Regression", pos(11) size(medsmall) color(black)) 
grc1leg Price Quant, rows(2) legendfrom(Price) xcommon
graph export "${aorm}/RegressionMonthly_LogPriceQuantityCoefficients.png", $export 
