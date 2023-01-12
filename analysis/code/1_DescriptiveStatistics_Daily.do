********************************************************************************
********************************************************************************
**** State vs Local Tax Enforcement Effectiveness: Evidence from Airbnb Price Data 
**** By: Justin Ross, Whitney Afonso, Luis Navarro 
**** Last Update: Navarro, Luis 
********************************************************************************
********************************************************************************

/// Daily Analysis 
use "${ai}/DailyDataCleanComplete.dta", clear

/// Step 1. Do some prep cleaning before running everything 
generate localratemiss = 0 
replace localratemiss = 1 if citytaxrate == . 
*tab year, summarize(localratemiss)
mdesc citytaxrate if year == 2019
*bysort city: mdesc citytaxrate
*tab city if year == 2019, summarize(localratemiss)
encode city, gen(cityname)
quietly sum cityname
global min = r(min)
global max = r(max)
encode status, gen(status1)
drop status 
rename status1 status

drop date 
gen date = date(reportingdate,"YMD",2050)
format date %td
drop reportingdate
gen dow = dow(date)

sort propertyid date 
order propertyid date 

/// dow is the weekday variable == 0 at sunday and 6 at saturday. Weekends are the numbers 5,6 and 0 
gen weekend_dum = 0 
replace weekend_dum = 1 if dow == 5 | dow == 6 
label define weekend_dum 0 "Weekdays" 1 "Weekend"
label value weekend_dum weekend_dum
*tab weekend_dum, summarize(priceusd)

/// Step 2. Some Graphs about the descriptive statistics of the variables 
/// 2.1. Compare simply the average price and tax rate across places with home rule and without homerule 
/*global bal_opts vce(robust) pboth fnoobs format(%12.3fc) rowvarlabels replace grplabels("0 State-Collected @ 1 Self-Collected")
forvalues i = 2017(1)2019{
	iebaltab priceusd citytaxrate if year == `i' , grpvar(HomeRule) savetex(${aodd}/BalanceTableDaily`i'.tex) ${bal_opts}
}
*/
/// 2.2 Prices and Taxes per city 
*tabulate city, summarize(priceusd)
*tabulate city, summarize(citytaxrate)
// County Maps 
/*
preserve 
global variables priceusd citytaxrate HomeRule
gcollapse (mean) ${variables}, by(year FIPS)
/// Do some scatterplots to see the correlation between prices and citytaxrates 
twoway (scatter priceusd citytaxrate if year == 2017, mcolor(ebblue) msize(tiny)) ///
	(lfit priceusd citytaxrate if year == 2017, lcolor(ebblue) lwidth(thin)) ///
	(scatter priceusd citytaxrate if year == 2018, mcolor(dknavy) msize(tiny)) ///
	(lfit priceusd citytaxrate if year == 2018, lcolor(dknavy) lwidth(thin)) ///
	(scatter priceusd citytaxrate if year == 2019, mcolor(edkblue*1.2) msize(tiny)) ///
	(lfit priceusd citytaxrate if year == 2019, lcolor(edkblue*1.2) lwidth(thin)), xlabel(#10, grid labsize(medsmall) angle(90)) ylabel(#10, grid labsize(medsmall) angle(0)) xtitle("Local Sales Tax Rate", size(medsmall)) ytitle("Average Daily Price ", size(medsmall)) legend(on order(1 "2017" 3 "2018" 5 "2019") size(medsmall) rows(1)) title("Local Sales Tax and Prices - Correlation by County and Year", size(medsmall) pos(11)) name(ScatterPriceTaxCountyYr, replace)
graph export "${aodd}/ScatterPriceTaxCountyYear.png", $export


twoway (scatter priceusd citytaxrate if HomeRule == 0, mcolor(ebblue) msize(tiny)) ///
	(lfit priceusd citytaxrate if HomeRule == 0, lcolor(ebblue) lwidth(thin)) ///
	(scatter priceusd citytaxrate if HomeRule == 1, mcolor(maroon) msize(tiny)) ///
	(lfit priceusd citytaxrate if HomeRule == 1, lcolor(maroon) lwidth(thin)), xlabel(#10, grid labsize(medsmall) angle(90)) ylabel(#10, grid labsize(medsmall) angle(0)) xtitle("Local Sales Tax Rate", size(medsmall)) ytitle("Average Daily Price ", size(medsmall)) legend(on order(1 "State-Collected" 3 "Self-Collected") size(medsmall)) title("Local Sales Tax and Prices - Correlation by County and Home Rule", size(medsmall) pos(11)) name(ScatterPriceTaxCountyHR, replace)
graph export "${aodd}/ScatterPriceTaxCountyHomeRule.png", $export

/*
destring FIPS, replace 
drop if FIPS == . 
rename FIPS county
gen state = "Colorado"
forvalues i=2017(1)2019{
local varlist ${variables}
foreach var of local varlist{
quietly sum `var' if year == `i'
global max = round(r(max))
global min = round(r(min))
global options_map title("`var' (`i')", size(vsmall)) legend(lab(2 "${min}") lab(3 "") lab(4 "") lab(5 "") lab(6 "") lab(7 "${max}")) legend(size(vsmall)) name(`var'`i', replace) 
maptile `var' if year == `i' , geo(county2014) mapif(state =="Colorado") twopt($options_map)
graph export "${aodd}/Map`var'`i'.png", $export 
}
graph combine priceusd`i' citytaxrate`i' HomeRule`i', rows(2) cols(2) title("`var' Distribution at the County Level", size(medsmall) pos(11))
graph export "${aodd}/MapCombined`i'.png", $export
}
*/
restore 
*/


/// 2.3 Time series graphs of city and tax rate 
preserve 
gcollapse (mean) priceusd citytaxrate, by(date)
format date %td_m_CY
twoway line priceusd date, sort lcolor(black) lwidth(thin) xlabel(#10, grid labsize(medsmall) angle(90)) ylabel(#10, grid labsize(medsmall) angle(0)) xtitle("Date", size(medsmall)) ytitle("Average Daily Price", size(medsmall)) legend(off) title("Average Daily Price", size(medsmall) pos(11)) name(DailyPrice, replace)
graph export "${aodd}/PriceDaily.png", $export 

twoway line citytaxrate date, sort lcolor(black) lwidth(thin) xlabel(#10, grid labsize(medsmall) angle(90)) ylabel(#10, grid labsize(medsmall) angle(0)) xtitle("Date", size(medsmall)) ytitle("Average Local Sales Tax Rate", size(medsmall)) legend(off) title("Average Local Sales Tax Rate", size(medsmall) pos(11)) name(CityTaxRate, replace)
graph export "${aodd}/LocalTaxRateDaily.png", $export 

twoway (line priceusd date, sort lcolor(black) lwidth(thin))(line citytaxrate date, sort lcolor(navy) lwidth(thin) yaxis(2)), xlabel(#10, grid labsize(medsmall) angle(90) axis(1)) ylabel(#10, grid labsize(medsmall) angle(0) axis(1)) ylabel(#10, grid labsize(medsmall) angle(0) axis(2)) xtitle("Date", size(medsmall)) ytitle("Daily Price", size(medsmall) axis(1)) ytitle("Local Sales Tax Rate", size(medsmall) axis(2)) legend(on order(1 "Daily Price (Rented)" 2 "Local Sales Tax Rate") rows(1) size(medsmall)) title("Average Daily Price and Local Sales Tax Rate", size(medsmall) pos(11)) name(PriceTaxComb, replace)
graph export "${aodd}/PriceTaxCombinedDaily.png", $export 
/*
twoway scatter priceusd citytaxrate, mcolor(black) msize(tiny) xlabel(#10, grid labsize(medsmall) angle(90)) ylabel(#10, grid labsize(medsmall) angle(0)) xtitle("Local Sales Tax Rate", size(medsmall)) ytitle("Daily Price", size(medsmall)) legend(off) title("Correlation Prices and Local Sales Tax Rate", size(medsmall) pos(11)) name(Scatter, replace)
graph export "${aodd}/PriceTaxScatterDaily.png", $export 
*/
restore 

/// 2.4 Time series of price by unit status 
preserve 
gcollapse(mean) priceusd citytaxrate, by(date status)
format date %td_m_CY
gen year = year(date)
twoway (line priceusd date if status == 1, sort lcolor(black) lwidth(thin)) ///
	(line priceusd date if status == 2, sort lcolor(ebblue) lwidth(thin)) ///
	(line priceusd date if status == 3, sort lcolor(dknavy) lwidth(thin)) ///
	(line priceusd date if status == 4, sort lcolor(maroon) lwidth(thin)), xlabel(#10, grid labsize(medsmall) angle(90)) ylabel(#10, grid labsize(medsmall) angle(0)) xtitle("Date", size(medsmall)) ytitle("Daily Price", size(medsmall)) legend(on order(1 "Available" 2 "Booked" 3 "Rented" 4 "Unavailable") rows(1) size(medsmall)) title("Average Daily Price by Unit Status", size(medsmall) pos(11)) name(DailyStatus, replace)
graph export "${aodd}/DailyPriceByStatus.png", $export 


twoway (line priceusd date if status == 1, sort lcolor(black) lwidth(thin)) ///
	(line priceusd date if status == 3, sort lcolor(dknavy) lwidth(thin)), xlabel(#10, grid labsize(medsmall) angle(90)) ylabel(#10, grid labsize(medsmall) angle(0)) xtitle("Date", size(medsmall)) ytitle("Daily Price", size(medsmall)) legend(on order(1 "Available" 2 "Rented") rows(1) size(medsmall)) title("Average Daily Price by Unit Status", size(medsmall) pos(11)) name(DailyStatus, replace)
graph export "${aodd}/DailyPriceByStatusRentedAvailable.png", $export 

twoway (line citytaxrate date if status == 1, sort lcolor(black) lwidth(thin)) ///
	(line citytaxrate date if status == 3, sort lcolor(dknavy) lwidth(thin)), xlabel(#10, grid labsize(medsmall) angle(90)) ylabel(#10, grid labsize(medsmall) angle(0)) xtitle("Date", size(medsmall)) ytitle("Sales Tax Rate", size(medsmall)) legend(on order(1 "Available" 2 "Rented") rows(1) size(medsmall)) title("Average Sales Tax Rate by Unit Status", size(medsmall) pos(11)) name(DailyStatus, replace)
graph export "${aodd}/TaxRateByStatusRentedAvailable.png", $export 

graph hbar (mean) priceusd, over(year, label(labcolor("black") labsize(medsmall))) over(status, label(labcolor("black") labsize(medsmall)) relabel(1 "Available" 2 "Booked" 3 "Rented" 4 "Unavailable")) bar(1, fcolor(ebblue*0.6) lwidth(none)) blabel(bar, size(small) color(black) format(%6.2g)) yscale(range(250 350)) ylabel(#10, grid labsize(medsmall) angle(0)) ytitle("Average Daily Price", size(medsmall)) title("Average Daily Price by Unit Status", size(medsmall) pos(11)) name(PriceStatus, replace) 
graph export "${aodd}/PriceByStatusAvg.png", $export 

graph hbar (mean) citytaxrate, over(year, label(labcolor("black") labsize(medsmall))) over(status, label(labcolor("black") labsize(medsmall)) relabel(1 "Available" 2 "Booked" 3 "Rented" 4 "Unavailable")) bar(1, fcolor(ebblue*0.6) lwidth(none)) blabel(bar, size(small) color(black) format(%6.2g)) yscale(range(0 0.5)) ylabel(#10, grid labsize(medsmall) angle(0)) ytitle("Average Sales Tax Rate", size(medsmall)) title("Average Sales Tax Rate by Unit Status", size(medsmall) pos(11)) name(PriceStatus, replace) 
graph export "${aodd}/TaxRateByStatusAvg.png", $export 

/// Reshape the dataset to do some analysis between prices across status 

reshape wide priceusd citytaxrate, i(date) j(status)

twoway (line priceusd3 date, sort lcolor(black) lwidth(thin))(line citytaxrate3 date, sort lcolor(navy) lwidth(thin) yaxis(2)), xlabel(#10, grid labsize(medsmall) angle(90) axis(1)) ylabel(#10, grid labsize(medsmall) angle(0) axis(1)) ylabel(#10, grid labsize(medsmall) angle(0) axis(2)) xtitle("Date", size(medsmall)) ytitle("Daily Price", size(medsmall) axis(1)) ytitle("Local Sales Tax Rate", size(medsmall) axis(2)) legend(on order(1 "Daily Price (Rented)" 2 "Local Sales Tax Rate") rows(1) size(medsmall)) title("Average Daily Price and Local Sales Tax Rate", size(medsmall) pos(11)) name(PriceTaxComb3, replace)
graph export "${aodd}/PriceTaxCombinedDailyRented.png", $export 

/*
twoway (scatter priceusd3 priceusd1, mcolor(black) msize(tiny)) (lfit priceusd3 priceusd1, lcolor(black) lwidth(thin)), xlabel(#10, grid labsize(medsmall) angle(90)) ylabel(#10, grid labsize(medsmall) angle(0)) xtitle("Daily Price (Available)", size(medsmall)) ytitle("Daily Price (Rented)", size(medsmall)) legend(off) title("Correlation Available and Rented Prices", size(medsmall) pos(11)) name(ScatterRentedAvailable, replace)
*/
graph export "${aodd}/ScatterAvailableRented.png", $export 

restore 

/// 2.5 By Home Rule 
preserve 
gcollapse(mean) priceusd citytaxrate, by(date HomeRule)
format date %td_m_CY
twoway (line priceusd date if HomeRule == 0, sort lcolor(black) lwidth(thin)) ///
	(line priceusd date if HomeRule == 1, sort lcolor(navy) lwidth(thin)), xlabel(#10, grid labsize(medsmall) angle(90) axis(1)) ylabel(#10, grid labsize(medsmall) angle(0)) xtitle("Date", size(medsmall)) ytitle("Daily Price", size(medsmall)) legend(on order(1 "State-Collected" 2 "Self-Collected") rows(1) size(medsmall)) title("Average Daily Price (Rented) by Home Rule", size(medsmall) pos(11)) name(PriceHomeRule, replace)
graph export "${aodd}/PriceHomeRule.png", $export 
restore 



preserve 
gcollapse(mean) priceusd citytaxrate, by(date status HomeRule)
format date %td_m_CY

twoway (line priceusd date if HomeRule == 0 & status == 3, sort lcolor(black) lwidth(thin)) ///
	(line priceusd date if HomeRule == 1 & status == 3, sort lcolor(navy) lwidth(thin)), xlabel(#10, grid labsize(medsmall) angle(90) axis(1)) ylabel(#10, grid labsize(medsmall) angle(0)) xtitle("Date", size(medsmall)) ytitle("Daily Price", size(medsmall)) legend(on order(1 "State-Collected" 2 "Self-Collected") rows(1) size(medsmall)) title("Average Daily Price (Rented) by Home Rule", size(medsmall) pos(11)) name(PriceHomeRule, replace)
graph export "${aodd}/PriceHomeRuleRented.png", $export 

twoway (line priceusd date if HomeRule == 0 & status == 1, sort lcolor(black) lwidth(thin)) ///
	(line priceusd date if HomeRule == 1 & status == 1, sort lcolor(navy) lwidth(thin)), xlabel(#10, grid labsize(medsmall) angle(90) axis(1)) ylabel(#10, grid labsize(medsmall) angle(0)) xtitle("Date", size(medsmall)) ytitle("Daily Price", size(medsmall)) legend(on order(1 "State-Collected" 2 "Self-Collected") rows(1) size(medsmall)) title("Average Daily Price (Available) by Home Rule", size(medsmall) pos(11)) name(PriceHomeRule, replace)
graph export "${aodd}/PriceHomeRuleAvailable.png", $export

/*
twoway (line citytaxrate date if HomeRule == 0 & status == 3, sort lcolor(black) lwidth(thin)) ///
	(line citytaxrate date if HomeRule == 1 & status == 3, sort lcolor(navy) lwidth(thin)), xlabel(#10, grid labsize(medsmall) angle(90) axis(1)) ylabel(#10, grid labsize(medsmall) angle(0)) xtitle("Date", size(medsmall)) ytitle("Daily Price", size(medsmall)) legend(on order(1 "State-Collected" 2 "Self-Collected") rows(1) size(medsmall)) title("Average Sales Tax Rate (Rented Units) by Home Rule", size(medsmall) pos(11)) name(PriceHomeRule, replace)
graph export "${aodd}/TaxHomeRuleRented.png", $export 

twoway (line citytaxrate date if HomeRule == 0 & status == 1, sort lcolor(black) lwidth(thin)) ///
	(line citytaxrate date if HomeRule == 1 & status == 1, sort lcolor(navy) lwidth(thin)), xlabel(#10, grid labsize(medsmall) angle(90) axis(1)) ylabel(#10, grid labsize(medsmall) angle(0)) xtitle("Date", size(medsmall)) ytitle("Daily Price", size(medsmall)) legend(on order(1 "State-Collected" 2 "Self-Collected") rows(1) size(medsmall)) title("Average Sales Tax Rate (Available Units) by Home Rule", size(medsmall) pos(11)) name(PriceHomeRule, replace)
graph export "${aodd}/TaxHomeRuleAvailable.png", $export 
*/
restore 

/*
/// 2.6 Taxes and Prices 
preserve 
gcollapse(mean) priceusd citytaxrate if status == 3, by(date)
format date %td_m_CY
twoway (line priceusd date, sort lcolor(black) lwidth(thin))(line citytaxrate date, sort lcolor(navy) lwidth(thin) yaxis(2)), xlabel(#10, grid labsize(medsmall) angle(90) axis(1)) ylabel(#10, grid labsize(medsmall) angle(0) axis(1)) ylabel(#10, grid labsize(medsmall) angle(0) axis(2)) xtitle("Date", size(medsmall)) ytitle("Daily Price", size(medsmall) axis(1)) ytitle("Local Sales Tax Rate", size(medsmall) axis(2)) legend(on order(1 "Daily Price (Rented)" 2 "Local Sales Tax Rate") rows(1) size(medsmall)) title("Average Daily Price and Local Sales Tax Rate", size(medsmall) pos(11)) name(PriceTaxComb, replace)
graph export "${aodd}/PriceTaxCombinedDailyRented.png", $export 
restore 



/// Bar Plots on the levels of the price 

label define dow 0 "Sunday" 1 "Monday" 2 "Tuesday" 3 "Wednesday" 4 "Thrusday" 5 "Friday" 6 "Saturday" 
label values dow dow 
/// Summarize Outcome by Weekday 
tab dow, summarize(priceusd)

/// Difference in prices across weekdays 
graph hbar (mean) priceusd, over(dow, label(labcolor("black") labsize(medsmall))) bar(1, fcolor(ebblue*0.8) lwidth(none)) blabel(bar, size(small) color(black) format(%6.2g)) yscale(range(250 350)) ylabel(#10, grid labsize(medsmall) angle(0)) ytitle("Average Daily Price", size(medsmall)) title("Average Daily Price by Day of the Week", size(medsmall) pos(11)) name(DailyPriceDOW, replace) 

graph hbar (mean) priceusd, over(weekend_dum, label(labcolor("black") labsize(medsmall))) bar(1, fcolor(ebblue*0.6) lwidth(none)) blabel(bar, size(small) color(black) format(%6.2g)) yscale(range(250 350)) ylabel(#10, grid labsize(medsmall) angle(0)) ytitle("Average Daily Price", size(medsmall)) title("Average Daily Price by Day of the Week", size(medsmall) pos(11)) name(DailyPriceDOWdum, replace) 

graph combine DailyPriceDOW DailyPriceDOWdum, rows(2) xcommon
graph export "${aodd}/DailyPriceWeekend.png", $export 

graph hbar (mean) priceusd, over(month, label(labcolor("black") labsize(medsmall))) bar(1, fcolor(ebblue*0.6) lwidth(none)) blabel(bar, size(small) color(black) format(%6.2g)) yscale(range(250 350)) ylabel(#10, grid labsize(medsmall) angle(0)) ytitle("Average Daily Price", size(medsmall)) title("Average Daily Price by Month", size(medsmall) pos(11)) name(DailyPriceMonth, replace) 

graph hbar (mean) priceusd, over(year, label(labcolor("black") labsize(medsmall))) over(weekend_dum, label(angle(90))) bar(1, fcolor(ebblue*0.6) lwidth(none)) blabel(bar, size(small) color(black) format(%6.2g)) yscale(range(250 350)) ylabel(#10, grid labsize(medsmall) angle(0)) ytitle("Average Daily Price", size(medsmall)) title("Average Daily Price by Year", size(medsmall) pos(11)) name(DailyPriceYearDow, replace) 

graph combine DailyPriceMonth DailyPriceYearDow, rows(2) xcommon
graph export "${aodd}/DailyPriceYear.png", $export 


*log close 


*/

