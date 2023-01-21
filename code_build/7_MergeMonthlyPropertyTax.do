********************************************************************************
********************************************************************************
**** State vs Local Tax Enforcement Effectiveness: Evidence from Airbnb Price Data 
**** By: Justin Ross, Whitney Afonso, Luis Navarro 
**** Last Update: Navarro, Luis 
********************************************************************************
********************************************************************************

/// DO FILE #7 : IMPORT MONTHLY DATA, MERGE WITH PROPERTY AND TAX DATA 
clear all 
********************************************************************************
//// Merge with the Monthly dataset 
** Load Colorado Data Monthly Data 
/// Read CSV
/* Run this step only once, it takes a lot of time to read the csv. 
import delimited "${bi}/us_Monthly_Match_2020-02-11.csv", varnames(1) clear 
** Filter Colorado Data 
keep if state == "Colorado"
save "${bt}/MonthlyDataColorado.dta", replace 
*/

/// Do The Merge 
use "${bt}/MonthlyDataColorado.dta", clear 
**** Merge Data Property and Month DataSet
// Remove Homeaways
generate prop_id_initial1 = substr(propertyid,1,2)
drop if prop_id_initial == "ha"
**** Merge Data Property and Month DataSet
merge m:1 propertyid using "${bt}/ColoradoPropertyGeoCodeComplete.dta", keep(match master)
rename _merge merge_property
distinct propertyid if merge_property == 1
/// destring FIPS 
destring FIPS, replace 
rename FIPS fips 
/// Examine Observations not Merged == 109 properties not merged. We lose 1049 observations 
sort propertyid reportingmonth
/// Hence for simplicity we will drop them from the sample 
drop if merge_property == 1
*** Merging with Tax Data
/// Create Variables to do the merge with Tax data
gen year = real(substr(reportingmonth,1,4))
gen month_scrape = real(substr(reportingmonth,6,2))
gen semester = .
replace semester = 1 if month_scrape <= 6 
replace semester = 2 if month_scrape > 6
*** Restrict the sample 
*********************************************************************************
keep if year == 2017 | year == 2018 | year == 2019
*********************************************************************************
/// Dimensions for the merge
global dimensions semester year fips city 
mdesc $dimensions county_fips
replace city = upper(city)
drop state_fips county_fips county_name country_code country
/// Merge with Tax Dataset from step 4
merge m:1 $dimensions using "${bt}/ColoradoSalesTaxClean.dta", keep(match master)
rename _merge merge_tax 
tab merge_tax

/// Tax Merge
// cities
tab city if merge_tax == 1
display r(r)
// counties = 55 out of 64
tab fips if merge_tax == 1
display r(r)
/// Proportions of missing data over time appear to be somewhat stable 
tab reportingmonth merge_tax

*-------------------------------------------------------------------------------
// Step 7. Clean the Dataset for the analysis 
// Do Some Cleaning 
// 0. Drop Variables not needed

//1. Observations not matched 
tab year merge_tax
// 2014 + 2015 = 152K observations (35%) dropped because we do not have tax data
// 2017 -2019 = 137K observations (32%) dropped because cities do not appear in the tax dataset. 
tab merge_tax year

// Drop Variables not Observed in the tax dataset. 
drop if merge_tax == 1 

/// 2. Transform Variables 
gen date2 = date(reportingmonth, "YMD")
format date2 %td
gen monthlydate = mofd(date2)
format monthlydate %tm
egen id = group(propertyid)
sort id monthlydate
encode listingtype, gen(listing_type)
drop listingtype
rename listing_type listingtype

order id monthlydate revenueusd averagedailyrateusd annualrevenueltmusd citytaxrate homerule_salestax StateSalesTaxRate StateVendorRate CountyTaxType CountyTaxRate CountyVendorRate LocalTaxType LocalTaxRate LocalVendorRate HomeRule listingtype

/// 3. Investigate Why the Revenue Variable Has 10% Missings
mdesc revenueusd
gen revenue_miss = 0
replace revenue_miss = 1 if revenueusd == .
tab monthlydate revenue_miss
// All Missings come from data between July 2016 and June 2017. 
/// NOTE: we can focus the analysis between 2018 and 2019 to avoid this problem. 

/// 4. Create Revenue Per Day Variable -- Proxy for Price
mdesc revenueusd reservationdays
tab year, summarize(reservationdays)
tab monthlydate, summarize(reservationdays)
generate revenueperday = 0
replace revenueperday = 0 if reservationdays == 0 
replace revenueperday = revenueusd / reservationdays if reservationdays > 0 

/// Assses how many missings do we have 
generate localratemiss = 0 
replace localratemiss = 1 if citytaxrate == . 
tab year, summarize(localratemiss)
mdesc citytaxrate if year == 2019
*bysort city: mdesc citytaxrate
tab city if year == 2019, summarize(localratemiss)
encode city, gen(cityname)
quietly sum cityname
global min = r(min)
global max = r(max)

/// Missings are at the city level. For some cities we do not have data
/// Missings from tyhe main variables in the models
mdesc citytaxrate revenueusd revenueperday
generate modelmiss = 0 
replace modelmiss = 1 if revenueusd == . | citytaxrate == . 
tab year modelmiss
/// Generate outcome: Total Days: Reservation Days + Available Days 
gen totaldays = reservationdays + availabledays

// Summarize the Variables 
sum revenueperday totaldays homerule_salestax citytaxrate HomeRule excisetax excisetaxhr airbnbag minimumstay maxguests numberofreviews listingtype if modelmiss == 0 
mdesc revenueperday totaldays homerule_salestax citytaxrate HomeRule excisetax excisetaxhr airbnbag minimumstay maxguests numberofreviews listingtype if modelmiss == 0 

gen msa_miss = . 
replace msa_miss = 0 if metropolitanstatisticalarea != ""
replace msa_miss = 1 if metropolitanstatisticalarea == ""

//// Merge 
preserve
use "${bi}/cbsa2fipsxw.dta", clear
gen FIPS = fipsstatecode + fipscountycode
keep if statename == "Colorado"
keep cbsatitle centraloutlyingcounty cbsacode FIPS
drop if FIPS == ""
destring FIPS, gen(fips)
drop FIPS
tempfile cbsa2fipsclean
save `cbsa2fipsclean', replace 

use "${bt}/CountyCodes.dta", clear 
keep if state == "Colorado"
rename county_fips fips
destring fips, replace 
merge 1:1 fips using `cbsa2fipsclean', keep(match master)
gen cbsdum = . 
replace cbsdum = 1 if _merge == 3 
replace cbsdum = 0 if _merge == 1
drop _merge 
tempfile cbsa2fipscomplete
save `cbsa2fipscomplete', replace 
restore 

/// Drop variables not needed 
drop propertyid propertytype state city1 neighborhood currencynative homeawaypropertyid homeawaypropertymanager prop_id_initial1 listingtitle createddate lastscrapeddate annualrevenueltmnative homeawaypremierpartner securitydepositnative extrapeoplefeenative instantbookenabled homeawaylistingurl homeawaylistingmainimageurl ST1 startdate start_year start_month STATEFP COUSUBNS GEOID NAME propid hostid propcount dummy_geocode groups v1 place_id osm_type osm_id osm_lat osm_lon house_number road postcode prop_id_initial stname state_abbrev state_abb state_code county_code mean_tax min_tax mean_hr min_hr date2

/// Merge 
merge m:1 fips using `cbsa2fipscomplete', keep(match master) force nogen 

save "${ai}/ColoradoPropertyMonthlyMerge.dta", replace
