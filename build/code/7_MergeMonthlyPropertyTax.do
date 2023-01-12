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
tab prop_id_initial1
drop if prop_id_initial == "ha"
**** Merge Data Property and Month DataSet
merge m:1 propertyid using "${bt}/ColoradoPropertyGeoCodeComplete.dta", keep(match master)
rename _merge merge_property
tab propertyid if merge_property == 1
display r(r)
/// Examine Observations not Merged == 109 properties not merged. We lose 1049 observations 
sort propertyid reportingmonth
/// All observations not matched at the property merge will not be find in the tax dataset because they do not have FIPS data. 
tab FIPS if merge_property == 1 
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
global dimensions semester year FIPS city 
mdesc $dimensions county_fips
generate city_upper = upper(city)
drop city 
rename city_upper city 
/// Merge with Tax Dataset from step 4
merge m:1 $dimensions using "${bt}/ColoradoSalesTaxClean.dta", keep(match master)
rename _merge merge_tax 
/// Examine observations not merged 
tab FIPS merge_tax
/// Almost 290K observations are not matched because they are before 2S 2016, hence we do not have tax date from them 
tab reportingmonth merge_tax

/// See where the missings are in terms of the merging
/// Tax Merge
// We have 132K observations from 60 cities over 35 counties that are not found in the tax dataset
*** Only 150 could be explained by lack of unique identifiers 
mdesc $dimensions 
// cities
tab city if merge_tax == 1
display r(r)
// counties 
tab FIPS if merge_tax == 1
display r(r)
/// Proportions of missing data over time appear to be somewhat stable 
tab reportingmonth merge_tax

*-------------------------------------------------------------------------------
// Step 7. Clean the Dataset for the analysis 
// Do Some Cleaning 
// 0. Drop Variables not needed

drop country homeawaypropertyid homeawaypropertymanager airbnbsuperhost homeawaypremierpartner cancellationpolicy  airbnbpropertyid airbnbhostid 

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
order id monthlydate
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
sum revenueusd reservationdays
generate revenueperday = 0
replace revenueperday = 0 if reservationdays == 0 
replace revenueperday = revenueusd / reservationdays if reservationdays > 0 

/// Drop variables not needed 
drop delta_hr min_hr mean_hr city1 delta_tax min_tax mean_tax county_name prop_id_initial CountyName county_name state_fips road house_number osm_lon osm_lat osm_id osm_type place_id address_found v1 idn county_fips_code0 NAME STATEFP ST1 homeawaylistingmainimageurl homeawaylistingurl airbnblistingmainimageurl airbnblistingurl prop_id_initial1

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
gen totaldays = reservationdays + availabledays


// Summarize the Variables 
sum revenueperday totaldays homerule_salestax citytaxrate HomeRule excisetax excisetaxhr airbnbag minimumstay maxguests numberofreviews listingtype if modelmiss == 0 
mdesc revenueperday totaldays homerule_salestax citytaxrate HomeRule excisetax excisetaxhr airbnbag minimumstay maxguests numberofreviews listingtype if modelmiss == 0 

gen msa_miss = . 
replace msa_miss = 0 if metropolitanstatisticalarea != ""
replace msa_miss = 1 if metropolitanstatisticalarea == ""

save "${ai}/ColoradoPropertyMonthlyMerge.dta", replace

//// Merge 
preserve
use "${bi}/cbsa2fipsxw.dta", clear
gen FIPS = fipsstatecode + fipscountycode
keep if statename == "Colorado"
keep cbsatitle centraloutlyingcounty cbsacode FIPS
drop if FIPS == ""
save "${bt}/cbsa2fipsclean.dta", replace 

use "${bt}/CountyCodes.dta", clear 
keep if state == "Colorado"
rename county_fips FIPS
keep FIPS 
merge 1:1 FIPS using "${bt}/cbsa2fipsclean.dta", keep(match master)
gen cbsdum = . 
replace cbsdum = 1 if _merge == 3 
replace cbsdum = 0 if _merge == 1
drop _merge 
save "${bt}/cbsa2fipscomplete.dta", replace 
restore 


use "${ai}/ColoradoPropertyMonthlyMerge.dta", clear 

merge m:1 FIPS using "${bt}/cbsa2fipscomplete.dta", keep(match master) 

save "${ai}/ColoradoPropertyMonthlyMerge.dta", replace
