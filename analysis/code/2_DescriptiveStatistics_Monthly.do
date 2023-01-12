********************************************************************************
********************************************************************************
**** State vs Local Tax Enforcement Effectiveness: Evidence from Airbnb Price Data 
**** By: Justin Ross, Whitney Afonso, Luis Navarro 
**** Last Update: Navarro, Luis 
********************************************************************************
********************************************************************************
/// Montly Dataset 
/// Open DataSet

clear all 


//// Colorado Airbnb 
use "${ai}/ColoradoPropertyMonthlyMerge.dta", clear
gen quarter = .
replace quarter = 1 if month_scrape <= 3
replace quarter = 2 if month_scrape <= 6 & month_scrape > 3 
replace quarter = 3 if month_scrape <= 9 & month_scrape > 6
replace quarter = 4 if month_scrape <= 12 & month_scrape > 9 

/// Figure 2. Bar Graphs 
graph bar (mean) revenueperday, over(quarter) over(year) bar(1, fcolor(emidblue) lcolor(none)) blabel(bar, size(small) orientation(horizontal) format(%8.2g)) ytitle("") ylabel(#10, labels labsize(small) angle(horizontal) nogrid) title(Average Daily Revenue, size(medsmall) position(11)) name(revenue1, replace)

graph bar (mean) reservationdays, over(quarter) over(year) bar(1, fcolor(emidblue) lcolor(none)) blabel(bar, size(small) orientation(horizontal) format(%8.2g)) ytitle("") ylabel(#10, labels labsize(small) angle(horizontal) nogrid) title(Average Reservation Days, size(medsmall) position(11)) name(days1, replace)

graph bar (mean) totaldays, over(quarter) over(year) bar(1, fcolor(emidblue) lcolor(none)) blabel(bar, size(small) orientation(horizontal) format(%8.2g)) ytitle("") ylabel(#10, labels labsize(small) angle(horizontal) nogrid) title(Average Listed Days, size(medsmall) position(11)) name(listed1, replace)

graph combine revenue1 listed1, rows(2) xcommon
graph export "${aodm}/DaysRevenue.png", $export 

/// Figure 3. Daily Revenue and City Tax Rates  
preserve 
gcollapse (mean) revenueperday totaldays StateSalesTaxRate citytaxrate CountyTaxRate countylodtax citylodtax excisetax, by(monthlydate)
rename monthlydate date 
format date %tm_m_CY
twoway (line revenueperday date, sort lcolor(black) lwidth(medthin)), xlabel(#12, nogrid labsize(medsmall) angle(90) axis(1)) ylabel(#10, nogrid labsize(medsmall) angle(0) axis(1)) xtitle("", size(medsmall)) ytitle("", size(medsmall) axis(1)) legend(off order(1 "Daily Revenue" 2 "Local Sales Tax" 3 "Excises Taxes") rows(1) size(medsmall)) title("Average Daily Revenue (USD)", size(medsmall) pos(11)) name(DailyRev, replace)
graph export "${aodm}/AverageDailyRevenue.png", $export 

twoway (line citytaxrate date, sort lcolor(ebblue) lwidth(medthin)) ///
	(line excisetax date, sort lcolor(maroon) lwidth(medthin) yaxis(2)), xlabel(#13, nogrid labsize(medsmall) angle(90) axis(1)) ylabel(#10, nogrid labsize(medsmall) angle(0) axis(1)) ylabel(#10, nogrid labsize(medsmall) angle(0) axis(2)) xtitle("", size(medsmall)) ytitle("Local Sales Tax", size(medsmall) axis(1)) ytitle("Excise Taxes", size(medsmall) axis(2)) legend(on order(1 "Local Sales Tax" 2 "Excises Taxes") rows(1) size(medsmall)) title("Average Applicable Tax Rates", size(medsmall) pos(11)) name(Taxes, replace)
graph export "${aodm}/AverageTaxRates.png", $export 

twoway (line revenueperday date, sort lcolor(ebblue) lwidth(medthin)) ///
	(line totaldays date, sort lcolor(maroon) lwidth(medthin) yaxis(2)), xlabel(#13, nogrid labsize(medsmall) angle(90) axis(1)) ylabel(#10, nogrid labsize(medsmall) angle(0) axis(1)) ylabel(#10, nogrid labsize(medsmall) angle(0) axis(2)) xtitle("", size(medsmall)) ytitle("Average Daily Revenue", size(medsmall) axis(1)) ytitle("Listed Days", size(medsmall) axis(2)) legend(on order(1 "Daily Revenue" 2 "Listed Days") rows(1) size(medsmall)) title("Average Daily Revenue and Listed Days", size(medsmall) pos(11)) name(RevDays, replace)
graph export "${aodm}/RevenueListedDays.png", $export 

restore 

/// Figure 4. Balance Tables 
gen logrev = ln(1+revenueperday)
gen logday = ln(1+totaldays)
gen logren = ln(1+reservationdays)
label variable logrev "Log Avg Daily Revenue"
label variable logday "Log Listed Days"
label variable logren "Log Rented Days"

global variables logrev logday logren citytaxrate excisetax 
global bal_opts vce(robust) pboth fnoobs format(%12.3fc) rowvarlabels replace grplabels("0 State-Collected @ 1 Self-Collected")
iebaltab ${variables}, grpvar(HomeRule) savetex(${aodm}/bt_variables.tex) ${bal_opts}
global bal_opts vce(robust) pboth fnoobs format(%12.3fc) rowvarlabels replace grplabels("0 No-Tax-Collection-Ag  @ 1 Tax-Collection-Ag")
iebaltab ${variables}, grpvar(airbnbag) savetex(${aodm}/bt_variablesair.tex) ${bal_opts}


/// Figure 5. Daily Revenue and City Tax Rates  
preserve 

gcollapse (mean) revenueperday totaldays StateSalesTaxRate citytaxrate CountyTaxRate countylodtax citylodtax excisetax, by(monthlydate HomeRule)
rename monthlydate date 
format date %tm_m_CY
twoway (line revenueperday date if HomeRule == 0, sort lcolor(dknavy) lwidth(medthin)) (line revenueperday date if HomeRule == 1, sort lcolor(maroon) lwidth(medthin)), xlabel(#12, nogrid labsize(small) angle(90) axis(1)) ylabel(#10, nogrid labsize(small) angle(0) axis(1)) xtitle("", size(small)) ytitle("", size(small) axis(1)) legend(on order(1 "State-Collected" 2 "Self-Collected") rows(1) size(small)) title("Average Daily Revenue (USD)", size(small) pos(11)) name(DailyRevHR, replace)
graph export "${aodm}/AverageDailyRevenueHR.png", $export 

twoway (line totaldays date if HomeRule == 0, sort lcolor(dknavy) lwidth(medthin)) (line totaldays date if HomeRule == 1, sort lcolor(maroon) lwidth(medthin)), xlabel(#12, nogrid labsize(small) angle(90) axis(1)) ylabel(#10, nogrid labsize(small) angle(0) axis(1)) xtitle("", size(small)) ytitle("", size(small) axis(1)) legend(on order(1 "State-Collected" 2 "Self-Collected") rows(1) size(small)) title("Listed Days", size(small) pos(11)) name(TotalDaysHR, replace)
graph export "${aodm}/ListedDaysHR.png", $export 

grc1leg DailyRevHR TotalDaysHR, legendfrom(DailyRevHR) rows(2) xcommon
graph export "${aodm}/AvgRevListedDaysHR.png", $export 

restore 



/// county level analysis
preserve 
rename revenueperday Daily_Revenue
label variable Daily_Revenue "Daily Revenue"
global variables Daily_Revenue
gcollapse (mean) ${variables}, by(year FIPS state)
destring FIPS, replace 
drop if FIPS == . 
rename FIPS county
local varlist ${variables}
foreach var of local varlist{

forvalues i=2017(1)2019{
quietly sum `var' if year == `i'
global max = round(r(max))
global min = round(r(min))
global options_map title("`var' (`i')", size(vsmall)) legend(lab(2 "${min}") lab(3 "") lab(4 "") lab(5 "") lab(6 "") lab(7 "${max}")) legend(size(vsmall)) name(`var'`i', replace) 
maptile `var' if year == `i' , geo(county2014) mapif(state =="Colorado") twopt($options_map)
}

graph combine `var'2017 `var'2018 `var'2019, rows(2) cols(2) title(`var' Distribution at the County Level)
graph export "${aodm}/`var'DistributionCounty.png", replace
}
restore 



/// Balance Tables to Compare Variables in the Model 
global bal_opts vce(robust) pboth fnoobs format(%12.3fc) rowvarlabels replace grplabels("0 State-Collected @ 1 Self-Collected")
iebaltab revenueperday citytaxrate if modelmiss == 0, grpvar(HomeRule) savetex(${output}/BalanceTable.tex) ${bal_opts}

forvalues i = 2017(1)2019{
	iebaltab revenueperday citytaxrate if modelmiss == 0 & year == `i' , grpvar(HomeRule) savetex(${output}/BalanceTable`i'.tex) ${bal_opts}
}


/// Correlation Analysis 

preserve 
drop if modelmiss == 1

global graph_opts ytitle(Daily Revenue, size(small)) xtitle(Local Sales Tax, size(small)) ylabel(#5, labels labsize(small) grid) xlabel(#5, labels labsize(small) grid) title(Correlation Local Sales Tax and Daily Revenue, size(small)) legend(on order(1 "Self-Collected 2017" 2 "State-Collected 2017" 3 "Self-Collected 2018" 4 "State-Collected 2018" 5 "Self-Collected 2019" 6 "State-Collected 2019") cols(2) rows(3) size(small))
twoway (lfit revenueperday citytaxrate if year == 2017 & HomeRule == 1, lcolor(dknavy) lwidth(thin) lpattern(solid)) ///
	(lfit revenueperday citytaxrate if year == 2017 & HomeRule == 0, lcolor(dknavy) lwidth(thin) lpattern(dash)) ///
	(lfit revenueperday citytaxrate if year == 2018 & HomeRule == 1, lcolor(maroon) lwidth(thin) lpattern(solid)) ///
	(lfit revenueperday citytaxrate if year == 2018 & HomeRule == 0, lcolor(maroon) lwidth(thin) lpattern(dash)) ///
	(lfit revenueperday citytaxrate if year == 2019 & HomeRule == 1, lcolor(green) lwidth(thin) lpattern(solid)) ///
	(lfit revenueperday citytaxrate if year == 2019 & HomeRule == 0, lcolor(green) lwidth(thin) lpattern(dash)) ///
	, ${graph_opts}
graph export "${aodm}/CorrelationRevenueTaxes_Full.png", replace


/// Collapsed Analysis 
gcollapse (mean) revenueperday citytaxrate, by(id year HomeRule)
label variable revenueperday "Daily Revenue"
label variable citytaxrate "Local Sales Tax"

global graph_opts ytitle(Daily Revenue, size(small)) xtitle(Local Sales Tax, size(small)) ylabel(#5, labels labsize(small) grid) xlabel(#5, labels labsize(small) grid) title(Correlation Local Sales Tax and Daily Revenue, size(small)) legend(on order(1 "Self-Collected 2017" 2 "State-Collected 2017" 3 "Self-Collected 2018" 4 "State-Collected 2018" 5 "Self-Collected 2019" 6 "State-Collected 2019") cols(2) rows(3) size(small))
twoway (lfit revenueperday citytaxrate if year == 2017 & HomeRule == 1, lcolor(dknavy) lwidth(thin) lpattern(solid)) ///
	(lfit revenueperday citytaxrate if year == 2017 & HomeRule == 0, lcolor(dknavy) lwidth(thin) lpattern(dash)) ///
	(lfit revenueperday citytaxrate if year == 2018 & HomeRule == 1, lcolor(maroon) lwidth(thin) lpattern(solid)) ///
	(lfit revenueperday citytaxrate if year == 2018 & HomeRule == 0, lcolor(maroon) lwidth(thin) lpattern(dash)) ///
	(lfit revenueperday citytaxrate if year == 2019 & HomeRule == 1, lcolor(green) lwidth(thin) lpattern(solid)) ///
	(lfit revenueperday citytaxrate if year == 2019 & HomeRule == 0, lcolor(green) lwidth(thin) lpattern(dash)) ///
	, ${graph_opts}
graph export "${aodm}/CorrelationRevenueTaxes.png", replace
restore 


