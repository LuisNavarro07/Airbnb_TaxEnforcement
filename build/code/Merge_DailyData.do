********************************************************************************
********************************************************************************
**** State vs Local Tax Enforcement Effectiveness: Evidence from Airbnb Price Data 
**** By: Justin Ross, Whitney Afonso, Luis Navarro 
**** Last Update: Navarro, Luis 
********************************************************************************
********************************************************************************
/// Merge Daily Data 
// Directory
clear all 
/// Load Data 
/// For the first file -- File number 5 
import delimited "${btd}/airbnbdaily_p5.csv", delimiter(space) clear

/// File number Five is already loaded 

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

**** Merge Data Property and Month DataSet
merge m:1 propertyid using "${results}/ColoradoPropertyGeoCodeComplete.dta", keep(match master)
/// Examine Observations not Merged == 109 properties not merged. We lose 1049 observations 
rename _merge merge_property
sort propertyid date
/// All observations not matched at the property merge will not be find in the tax dataset because they do not have FIPS data. 
tab FIPS if merge_property == 1 
/// Hence for simplicity we will drop them from the sample 
drop if merge_property == 1

*** Merging with Tax Data
/// Create Variables to do the merge with Tax data
gen year = real(substr(date,1,4))
gen month = real(substr(date,6,2))
gen semester = .
replace semester = 1 if month <= 6 
replace semester = 2 if month > 6
*** Restrict the sample 
*********************************************************************************
keep if year == 2017 | year == 2018 | year == 2019
*********************************************************************************
/// Dimensions for the merge
global dimensions semester year FIPS city 
mdesc $dimensions county_fips
generate city_upper = upper(city)
drop city 
rename city_upper city 
/// Rename date 
rename date reportingdate 
/// Merge with Tax Dataset from step 4
merge m:1 $dimensions using "${results}/ColoradoSalesTaxClean.dta", keep(match master)
rename _merge merge_tax 
/// Examine observations not merged 
tab FIPS merge_tax
tab reportingdate merge_tax

/// See where the missings are in terms of the merging
/// Tax Merge
mdesc $dimensions 
// cities
tab city if merge_tax == 1
display r(r)
// counties 
tab FIPS if merge_tax == 1
display r(r)
/// Proportions of missing data over time
tab reportingdate merge_tax

*-------------------------------------------------------------------------------
// Step 7. Clean the Dataset for the analysis 
// Do Some Cleaning 
//1. Observations not matched 
// Missings from the Merge with the Tax Dataset
tab year merge_tax

// Drop Variables not Observed in the tax dataset. 
drop if merge_tax == 1 

/// 2. Transform Variables 
gen date2 = date(reportingdate, "YMD")
format date2 %td
gen monthlydate = mofd(date2)
format monthlydate %tm
egen id = group(propertyid)
order id monthlydate
sort id monthlydate
encode listingtype, gen(listing_type)
drop listingtype
rename listing_type listingtype

order id monthlydate priceusd citytaxrate homerule_salestax StateSalesTaxRate StateVendorRate CountyTaxType CountyTaxRate CountyVendorRate LocalTaxType LocalTaxRate LocalVendorRate HomeRule listingtype

/// 3. Check for missings in the outcome 
mdesc priceusd
gen revenue_miss = 0
replace revenue_miss = 1 if priceusd == .
tab monthlydate revenue_miss

save "${btd}/DailyDataClean5_`j'.dta", replace

restore 
}


****************************************************

log using ${bc}/LogCleaning, replace text

/// Clean all eight Files 
foreach i of numlist 1 2 3 4 6 7 8 { 
	
/// Load Data 
import delimited "${btd}/airbnbdaily_p`i'.csv", delimiter(space) clear

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

/// Create a variable that shows the number of the obs in the dataset
gen auxid = _n
// create a variable that separates the files in smaller ones. Say 20 files. 
egen groups = seq(), from(1) to(100)

forvalues j=1(1)100{

preserve 

keep if groups == `j'

**** Merge Data Property and Month DataSet
merge m:1 propertyid using "${results}/ColoradoPropertyGeoCodeComplete.dta", keep(match master)
/// Examine Observations not Merged == 109 properties not merged. We lose 1049 observations 
rename _merge merge_property
sort propertyid date
/// All observations not matched at the property merge will not be find in the tax dataset because they do not have FIPS data. 
tab FIPS if merge_property == 1 
/// Hence for simplicity we will drop them from the sample 
drop if merge_property == 1

*** Merging with Tax Data
/// Create Variables to do the merge with Tax data
gen year = real(substr(date,1,4))
gen month = real(substr(date,6,2))
gen semester = .
replace semester = 1 if month <= 6 
replace semester = 2 if month > 6
*** Restrict the sample 
*********************************************************************************
keep if year == 2017 | year == 2018 | year == 2019
*********************************************************************************
/// Dimensions for the merge
global dimensions semester year FIPS city 
mdesc $dimensions county_fips
generate city_upper = upper(city)
drop city 
rename city_upper city 
/// Rename date 
rename date reportingdate 
/// Merge with Tax Dataset from step 4
merge m:1 $dimensions using "${results}/ColoradoSalesTaxClean.dta", keep(match master)
rename _merge merge_tax 
/// Examine observations not merged 
tab FIPS merge_tax
tab reportingdate merge_tax

/// See where the missings are in terms of the merging
/// Tax Merge
mdesc $dimensions 
// cities
tab city if merge_tax == 1
display r(r)
// counties 
tab FIPS if merge_tax == 1
display r(r)
/// Proportions of missing data over time
tab reportingdate merge_tax

*-------------------------------------------------------------------------------
// Step 7. Clean the Dataset for the analysis 
// Do Some Cleaning 
//1. Observations not matched 
// Missings from the Merge with the Tax Dataset
tab year merge_tax

// Drop Variables not Observed in the tax dataset. 
drop if merge_tax == 1 

/// 2. Transform Variables 
gen date2 = date(reportingdate, "YMD")
format date2 %td
gen monthlydate = mofd(date2)
format monthlydate %tm
egen id = group(propertyid)
order id monthlydate
sort id monthlydate
encode listingtype, gen(listing_type)
drop listingtype
rename listing_type listingtype

order id monthlydate priceusd citytaxrate homerule_salestax StateSalesTaxRate StateVendorRate CountyTaxType CountyTaxRate CountyVendorRate LocalTaxType LocalTaxRate LocalVendorRate HomeRule listingtype

/// 3. Check for missings in the outcome 
mdesc priceusd
gen revenue_miss = 0
replace revenue_miss = 1 if priceusd == .
*tab monthlydate revenue_miss

save "${btd}/DailyDataClean`i'_`j'.dta", replace

restore 
}

}

log close 

clear all 
use "${temp}/DailyDataClean5_1.dta", clear 
forvalues j=2(1)100{
quietly append using "${temp}/DailyDataClean5_`j'.dta"
}

foreach i of numlist 1 2 3 4 6 7 8 { 
forvalues j=2(1)100{
quietly append using "${cleandaily}/DailyDataClean`i'_`j'.dta"	
}
}

/// Keep only the required variables 
global variables id propertyid  monthlydate reportingdate status priceusd citytaxrate homerule_salestax StateSalesTaxRate StateVendorRate CountyTaxType CountyTaxRate CountyVendorRate LocalTaxType LocalTaxRate LocalVendorRate HomeRule listingtype homerule_salestax citytaxrate HomeRule listingtype overallrating minimumstay maxguests propertytype bedrooms bathrooms county_fips CountyName city cityid merge_tax merge_property county_name zipcode numberofreviews numberofphotos cancellationpolicy responserate JurisdictionCode year month semester

mdesc $variables

keep $variables 


preserve 
use "${ai}/ColoradoPropertyMonthlyMerge.dta", clear
keep propertyid FIPS city County metropolitanstatisticalarea msa_miss cbsatitle cbsdum
rename city City
duplicates drop propertyid, force
save "${bt}/PropertyidCounty.dta", replace 
restore 
/// From this step we get the county information from the Montly Data 
merge m:1 propertyid using "${bt}/PropertyidCounty.dta", keep(match master) nogen
/// Replace manually the HomeRule Variable 
replace HomeRule = 0 if city == "CRAIG" & year == 2017 
replace HomeRule = 0 if city == "CRAIG" & year == 2018 & semester == 1 


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

encode metropolitanstatisticalarea, gen(msa)
save "${ai}/DailyDataCleanComplete.dta", replace

*******************************************************************************
/*
/// Now we will use the xfill and fillin commands 
use "${daily}/DailyDataCleanComplete.dta", clear
// Aux to Get time Variant Tax Data 
preserve 
keep propertyid semester year citytaxrate homerule_salestax StateSalesTaxRate StateVendorRate CountyTaxType CountyTaxRate CountyVendorRate LocalTaxType LocalTaxRate LocalVendorRate HomeRule
duplicates drop propertyid semester year, force 
save "${daily}/AuxTaxesProperty.dta", replace
restore 
// We will do the fillin 
keep propertyid priceusd status reportingdate
gen date = date(reportingdate, "YMD", 2050)
format date %td
egen id = group(propertyid)
order propertyid id date 
sort propertyid date 
duplicates report id date
xtset id date
// Fillin 
fillin propertyid id date 
/// Create Variables to do the merge with Tax data
gen year = year(date)
gen month = month(date)
gen semester = .
replace semester = 1 if month <= 6 
replace semester = 2 if month > 6
/// Generate Price Dummy 
gen pricedum = . 
replace pricedum = 0 if _fillin == 1
replace pricedum = 1 if _fillin == 0
/// Do the Xfill 
xfill propertytype zipcode bedrooms bathrooms maxguests responserate cancellationpolicy minimumstay numberofreviews numberofphotos overallrating county_name county_fips CountyName merge_property city JurisdictionCode cityid merge_tax FIPS City County
// Merge with the Tax data 
merge m:1 propertyid semester year using "${daily}/AuxTaxesProperty.dta", keep(match master)

*/
