/// Code to Append the Partitioned dataset and merge it with the Property dataset. 
/// For Professor Daniel Simon. 
/// Load Property Dataset 
clear 
log using "${btdf}/logcleandaily.log", replace 
timer clear 
timer on 1

// Variables to keep 
global variables propertyid date status priceusd year propertytype state city zipcode annualrevenueltmusd

import delimited "${bi}/us_Property_Match_2020-02-11.csv", varnames(1) clear
qui save "${btdf}/propertydata.dta", replace 

/// For the first file -- File number 5 
import delimited "${btd}/airbnbdaily_p5.csv", delimiter(space) clear
// Label Variables 
label variable v1 "Data ID"
// Rename Variables
rename v1 dataid
/// Create a variable that shows the number of the obs in the dataset
gen auxid = _n
// create a variable that separates the files in smaller ones. Say 20 files. 
egen groups = seq(), from(1) to(100)
forvalues j=1(1)100{
preserve 
keep if groups == `j'
qui merge m:1 propertyid using "${btdf}/propertydata.dta", keep(match master) nogen 
cap keep $variables 
qui save "${btdf}/daily_data_5_`j'.dta", replace 
display "File 5 - SubFile `j' out of 100"
restore 
}


foreach i of numlist 1 2 3 4 6 7 8 { 
clear
/// Load Daily Data 
/// For the first file -- File number `i'
import delimited "${btd}/airbnbdaily_p`i'.csv", delimiter(space) clear
/// Create date variables 
// Label Variables 
label variable v1 "Data ID"
label variable v2 "Property ID" 
label variable v3 "Date"
label variable v4 "Status" 
label variable v5 "Booked Date" 
label variable v6 "Price (USD)" 
label variable v7 "Price (Native)" 
label variable v8 "Currency Native"

// Rename Variables
rename v1 dataid
rename v2 propertyid
rename v3 date
rename v4 status
rename v5 bookeddate
rename v6 priceusd
rename v7 pricenative 
rename v8 currencynative 

gen year = real(substr(date,1,4))
/// Restrict the sample 
keep if year == 2018 | year == 2019 | year == 2020 
/// Create a variable that shows the number of the obs in the dataset
gen auxid = _n
// create a variable that separates the files in smaller ones. Say 0 files. 
egen groups = seq(), from(1) to(100)
forvalues j=1(1)100{
preserve 
qui keep if groups == `j'
qui merge m:1 propertyid using "${btdf}/propertydata.dta", keep(match master) nogen 
cap keep $variables 
qui save "${btdf}/daily_data_`i'_`j'.dta", replace 
display "File `i' - SubFile `j' out of 100"
restore 
}
}



clear 
forvalues i=1(1)8{
/// part 1
use "${btdf}/daily_data_`i'_1.dta", clear 
cap keep $variables 
forvalues j=2(1)25{
qui append using "${btdf}/daily_data_`i'_`j'.dta", force  
}
save "${btdf}/daily_data_full`i'_part1.dta", replace 
/// part 2 
use "${btdf}/daily_data_`i'_26.dta", clear 
forvalues j=26(1)50{
qui append using "${btdf}/daily_data_`i'_`j'.dta", force  
}
save "${btdf}/daily_data_full`i'_part2.dta", replace 
/// part 3 
use "${btdf}/daily_data_`i'_51.dta", clear 
forvalues j=52(1)75{
qui append using "${btdf}/daily_data_`i'_`j'.dta", force  
}
save "${btdf}/daily_data_full`i'_part3.dta", replace
/// part 4 
use "${btdf}/daily_data_`i'_76.dta", clear 
forvalues j=76(1)100{
qui append using "${btdf}/daily_data_`i'_`j'.dta", force  
}
save "${btdf}/daily_data_full`i'_part4.dta", replace  
}
}
timer off 1 
log close 
exit 

