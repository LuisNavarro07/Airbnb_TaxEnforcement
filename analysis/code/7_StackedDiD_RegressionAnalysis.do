
/// Stacked Analysis 
global taxes homerule_salestax citytaxrate HomeRule airbnbag excisetax 
global regsaveopts table(base, format(%9.4f) parentheses(stderr) asterisk(10 5 1) order(regvars r2 N)) replace 
global conditional modelmiss == 0 
global regopts absorb(propertyid listingtype monthlydate) vce(cluster city)
global outcome revenueperday totaldays reservationdays 
global dimensions semester year FIPS city 

forvalues i=1(1)3{
use "${at}/StackedDID_TreatControl`i'.dta", clear 
/// (Baseline): Include the Airbnb Tax Agreement 
label variable HomeRule "Local Collection"
label variable homerule_salestax "Local Collection x Sales Tax"
/// Model 2. No Interaction 
local varlist $outcome 
foreach var of local varlist {
gen log`var' = ln(`var')
global model 
reghdfe log`var' homerule_salestax citytaxrate HomeRule airbnbag excisetax if ${conditional}, ${regopts}
estimates store `var'_treat`i'
}
********************************************************************************
********************************************************************************
//// Probability Model 
// Step 1. Get the Fillin and Xfill code working. 
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
merge m:1 $dimensions using "${bt}/ColoradoSalesTaxClean.dta", keep(match master)
drop if _merge == 1
drop _merge 
// Step 3. Generate the Binary Outcome 
generate listed = . 
replace listed = 0 if _fillin == 1 
replace listed = 1 if _fillin == 0 
/// Generate MonthlyDate
gen date2 = date(reportingmonth, "YMD")
format date2 %td
drop monthlydate 
gen monthlydate = mofd(date2)
format monthlydate %tm
xtset id monthlydate 
/// Step 3. Do the Regressions 
reghdfe listed $taxes, absorb(propertyid listingtype monthlydate) vce(cluster city)
estimates store linear`i'
xtlogit listed $taxes, fe 
estimates store logit`i'

esttab revenueperday_treat`i' totaldays_treat`i' reservationdays_treat`i' linear`i' logit`i', mtitles("Daily Revenue" "Listed Days" "Booked Days" "Any Days Linear" "Any Days Logit") keep(homerule_salestax) se label replace noobs compress 
esttab revenueperday_treat`i' totaldays_treat`i' reservationdays_treat`i' linear`i' logit`i' using "${ao}/Coefficients_Treated`i'.tex", mtitles("Daily Revenue" "Listed Days" "Booked Days" "Any Days Linear" "Any Days Logit") keep(homerule_salestax) se label replace noobs compress 

}
********************************************************************************

