********************************************************************************
********************************************************************************
**** State vs Local Tax Enforcement Effectiveness: Evidence from Airbnb Price Data 
**** By: Justin Ross, Whitney Afonso, Luis Navarro 
**** Last Update: Navarro, Luis 
********************************************************************************
********************************************************************************

/// Outcomes 
global outcome revenueperday totaldays reservationdays availabledays

//// Regression where the outcome variable is the number of days 
// Definitions
* Reservation Days: count of days with a reservation in the month 
* Available Days: count of available days that did not have a booking 
* Blocked Days: count of days blocked from accepting reservations in the month. 

/// Regression: Outcomes in Levels 
local varlist $outcome 
foreach var of local varlist {
/// Model Definition 
/// Model 1 Linear 
global model `var' $taxes 
reghdfe $model if modelmiss == 0, absorb(propertyid listingtype monthlydate) vce(cluster city)
estimates store `var'1
/// Model 2. Quadratic
global model `var' $taxes citytaxrate2 excisetax2
reghdfe $model if modelmiss == 0, absorb(propertyid listingtype monthlydate) vce(cluster city)
estimates store `var'2
/// Model 3. Cubic
global model `var' $taxes citytaxrate2 excisetax2 citytaxrate3 excisetax3
reghdfe $model if modelmiss == 0, absorb(propertyid listingtype monthlydate) vce(cluster city)
estimates store `var'3
esttab `var'1 `var'2 `var'3 using "${aorm}/`var'_coef${mod}.tex", mtitles("Baseline" "Quadratic" "Cubic") ${tables}

} 

*******************************************************************************
/// Regressions: Outcomes are Logged y = log(1+y)

local varlist $outcome 
foreach var of local varlist {
/// Create the Logged outcome 
generate log`var' = ln(1 + `var')
/// Model Definition 
global model log`var' $taxes 
reghdfe $model if modelmiss == 0, absorb(propertyid listingtype monthlydate) vce(cluster city)
estimates store `var'1log
/// Model 2. No Interaction 
global model log`var' $taxes citytaxrate2 excisetax2
reghdfe $model if modelmiss == 0, absorb(propertyid listingtype monthlydate) vce(cluster city)
estimates store `var'2log
/// Model 3. City and Property Fixed Effects 
global model log`var' $taxes citytaxrate2 excisetax2 citytaxrate3 excisetax3
reghdfe $model if modelmiss == 0, absorb(propertyid listingtype monthlydate) vce(cluster city)
estimates store `var'3log
esttab `var'1log `var'2log `var'3log using "${aorm}/`var'log_coef${mod}.tex", mtitles("Baseline" "Quadratic" "Cubic")${tables}

drop log`var'
} 

