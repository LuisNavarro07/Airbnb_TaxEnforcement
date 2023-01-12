************************************************************
************************************************************
**** Airbnb Project
**** Colorado Sales and Use Tax Clean Data Set 
**** Update: May, 18th 2021
**** Professor: Justin Ross
**** Last Update: Navarro, Luis 
**** Colorado Airbnb Property Data Append with Tax Code Data 
************************************************************
************************************************************

// Directory
clear all 
matrix drop _all
/*
/// Regular Globals 
cd "C:\Users\luise\Indiana University\Ross, Justin - Ross_Luis\AirBNB"
global data "Data\ColoradoTaxRates"
global code "Code\ColoradoTaxRates"
global results "Data\ColoradoTaxRates\StataResults"
global airbnb "Data\Colorado_Airbnb"
*/

/// Carbonate Luis Globals 
cd "/N/slate/lunavarr/AirbnbColorado/"
global results "Data/StataResults"
global results_root "Results"
global output "Results/DescriptiveStats"
global geo_in "Data/StataResults/OpenCageGeo/Input/"
global geo_out "Data/StataResults/OpenCageGeo/Output/"

************************************************************
************************************************************
**** Airbnb Project
**** Colorado Sales and Use Tax Clean Data Set 
**** Update: May, 18th 2021
**** Professor: Justin Ross
**** Last Update: Navarro, Luis 
**** Colorado Airbnb Property Data Append with Tax Code Data 
************************************************************
************************************************************

log using "${results}/Log_Merge_Monthly_PropertyData.log", replace 


//// Use Geocode 
/*
Motivation: The problem is that data reporting the city is not accurate. Hence we need to use the geocode command to get the location. 
This will be done in two steps: 
1) For cities with more than 1000 listigns I'll need the city name obtained by geocode command to match with tax data.
2) For cities with less than 1000 listings I'll use the self reported city name by airbnb. So, do nothing. 
*/

/// THESE STEPS WERE DONE BEFORE DOING THE GEOCODE IN R
****************************************************************
/*
/// Load data 
use "${results}/Colorado_Colorado_property_match_stacked.dta", clear
// Remove Blanks in City names 
gen cityname = upper(city)
gen cityname1 = stritrim(cityname)
gen cityname2 = strtrim(cityname1)
drop cityname cityname1 city
rename cityname2 city 

// Step 1. Split the dataset 
tab city, sort matcell(city_freq) gen(city_dum)

** 22 rows with cities above 1000 (For this to work data needs to be sorted)
global ncities = 22
generate dummy_geocode = 0

forvalues i = 1(1)$ncities {
	replace dummy_geocode = 1 if city_dum`i' == 1
}
tab dummy_geocode

/// Step 2. Perform the geocode process only for the dummy_geocode == 1
// to avoid mistakes lets split the dataset
save "${results}/Colorado_Property_GeocodeRaw.dta", replace
/// Below 1000 listings
preserve 
keep if dummy_geocode == 0 
save "${results}/Colorado_Property_GeocodeRaw_Below1000.dta", replace
restore 
/// Above 1000 listings
preserve 
keep if dummy_geocode == 1 
sort latitude longitude
save "${results}/Colorado_Property_GeocodeRaw_Above1000.dta", replace
restore 


/// Step 3. Partition the Data Set 
use "${results}/Colorado_Property_GeocodeRaw_Above1000.dta", clear
global sets = round(_N/2500)
egen groups = seq(), from(1) to ($sets)
tab groups, gen(groupid)
forvalues i=1(1)$sets{
	preserve 
	keep if groupid`i' == 1
	gen idn = _n
	label variable idn "Group Individual ID - Group `i'"
	gen check = 0 
	label variable check "== 1 if already geocoded"
	save "${geo_in}/Property_Above1000_`i'.dta", replace
	restore
}
*/

// THESE STEPS ARE DONE AFTER HAVING THE DATA GEOCODED
*******************************************************************************
********************************************************************
//// Step 4. Clean Sales Tax Data 
use "${results}/ColoradoSalesTaxComplete.dta", clear
// Create String Variables to identify which locations contain city tax rates
gen par =  strpos(location, "(") > 0
gen mail =  strpos(location, "MAIL") > 0
gen unic =  strpos(location, "UNINCORPORATED") > 0
gen drop_index = par + mail + unic
drop if drop_index > 0 
// Remove Blanks in City names 
gen cityname = upper(location)
gen cityname1 = stritrim(cityname)
gen cityname2 = strtrim(cityname1)
drop location cityname cityname1 par mail drop_index unic
rename cityname2 city 
order County FIPS city date
sort FIPS city date  
duplicates report city FIPS date
/// Variable not needed 
drop State
/// Homogenize Home Rule Variable
replace HomeRule = "Self-collected" if HomeRule == "Self-Collected"
drop if HomeRule == "A,B,K"
encode HomeRule, gen(homerule)
drop HomeRule
rename homerule HomeRule
replace HomeRule = 0 if HomeRule == 2
label define HomeRule 0 "State-Collected" 1 "Self-Collected"
label values HomeRule HomeRule
//// rename for simplicity 
rename State_SalesTaxRate StateSalesTaxRate
rename State_VendorRate StateVendorRate
rename County_TaxType CountyTaxType
rename County_TaxRate CountyTaxRate
rename County_VendorRate CountyVendorRate
rename Local_TaxType LocalTaxType
rename Local_TaxRate LocalTaxRate 
rename Local_VendorRate LocalVendorRate
/// view the time dimension of the dataset
tabulate year semester
/// City Sales Tax Rates are messed up, need to create a variable that stores them properly 
tab CountyTaxType 
display r(r)
/// 546 observations contain a city sales tax rate stored in the county column
tab LocalTaxType 
display r(r)
/// 1730 observations contain city sales tax rate in the city column
/// check there is no overlap
generate taxtypeaux = 0 
global conditional CountyTaxType == "City" & LocalTaxType == "City"
replace taxtypeaux = 1 if $conditional
tab taxtypeaux 
drop taxtypeaux
/// Create the variable to do the conversion
encode CountyTaxType, gen(countytax)
encode LocalTaxType, gen(localtax)
tab countytax if countytax == 1 
tab localtax if localtax == 2
generate citytaxrate = . 
replace citytaxrate = CountyTaxRate if countytax == 1
replace citytaxrate = LocalTaxRate if localtax == 2


/// CarryForward -- This will fill the blanks for all city tax rates that have missings in between the time series and that do not experienced a change in the tax rate. 
*ssc install carryforward, replace 
// city FIPS is the unique identifier because we could have some cities that overlap in counties. Example: we have Denver that has tax rates for different FIP Codes
tab FIPS if city == "DENVER"
duplicates tag date city, gen(d1)
tab d1
tab city if d1 >= 1 
display r(r)
// 29 cities appear in more than one county
tab FIPS if d1 >= 1
display r(r)
drop d1
// There are 26 counties that have a city overlapping in to two counties 
/// Check Unique IDs
duplicates report date city FIPS
egen cityid = group(city FIPS)
sort city FIPS date
/// Create variable to identify which observations have blanks in between the series
gen missdate = 0
replace missdate = 1 if citytaxrate == . 
tab date missdate
// Do the CarryForward. This will assume that the last tax rate observed remains the same
bysort cityid: carryforward citytaxrate, gen(cityrate)
drop citytaxrate CountyTaxType LocalTaxType 
rename (cityrate countytax localtax) (citytaxrate CountyTaxType LocalTaxType)
tab date missdate 
tab year, summarize(citytaxrate)
label variable citytaxrate "Local Sales Tax"

*******************************************************************************

/// Create Interaction Rate Home Rule 
generate homerule_salestax = HomeRule * citytaxrate 
label variable homerule_salestax "Local Sales Tax - Home Rule Int"
mdesc homerule_salestax
bysort year: mdesc citytaxrate homerule_salestax


/// Variation Analysis - HomeRule and City Tax Rates
*** Restrict the sample 
*********************************************************************************
keep if year == 2017 | year == 2018 | year == 2019
*********************************************************************************
** Panel setting 
xtset cityid date
xtsum citytaxrate

sum city FIPS cityid date CountyTaxType CountyTaxRate LocalTaxType LocalTaxRate citytaxrate if CountyTaxType == 1 | LocalTaxType == 2
tab CountyTaxType
tab LocalTaxType
keep if CountyTaxType == 1 | LocalTaxType == 2
*** identify the cities that changed tax rate. If the min is different from the mean, then it is not a constant series. 
by cityid: egen mean_tax = mean(citytaxrate) 
by cityid: egen min_tax = min(citytaxrate)
by cityid: gen delta_tax = 0 
by cityid: replace delta_tax = 1 if mean_tax != min_tax
** Cities that observed a change in their tax rates between 2017-2019
tab city if delta_tax == 1, sum(citytaxrate)
sort cityid date
encode city, gen(city1)
tab city1 date if delta_tax == 1
*** Values of the Cities that Observed Changes in their tax rates
table city1 date if delta_tax == 1, stat(mean citytaxrate)



***************************
// Homerule changes 
xtsum HomeRule
by cityid: egen mean_hr = mean(HomeRule) 
by cityid: egen min_hr = min(HomeRule)
by cityid: gen delta_hr = 0 
by cityid: replace delta_hr = 1 if mean_hr != min_hr
*** Cities that experienced changes in their HomeRule 
tab city1 if delta_hr == 1, sum(HomeRule)
tab city1 date if delta_hr == 1
** Periods from which they changed the homerule 
table city1 date if delta_hr == 1, stat(mean HomeRule)

*** Save Data 
save "${results}/ColoradoSalesTaxClean.dta", replace



*******************************************************************************
/// Merge Data 
/// Step 5. Use data already merged at Luis's stata
cd "/N/slate/lunavarr/AirbnbColorado/"
global results "Data/StataResults"
global results_root "Results"
global geo_in "Data/StataResults/OpenCageGeo/Input/"
global geo_out "Data/StataResults/OpenCageGeo/Output/"
/// This is the set for the above 1000 (we did this dataset through R)
use "${results}/ColoradoReverse_merged.dta", clear
/// This is the set for the below 1000
/// Append
append using "${results}/Colorado_Property_GeocodeRaw_Below1000.dta"
drop IssuedState _merge
rename govname county_name
drop city_dum*
drop if propertyid == ""
duplicates report propertyid
/// Propertyid Variable for Merged
generate prop_id_initial = substr(propertyid,1,2)
****************
// Use the appropiate FIPS code for the merge 
rename FIPS county_fips_code0 
// Create variable FIPS
generate FIPS = ""
replace FIPS = county_fips_code0 if dummy_geocode == 0 
replace FIPS = county_fips if dummy_geocode == 1
tab FIPS dummy_geocode

/// Clean some unecessary variables resulting from the merging process (Above DataSet)
drop hamlet town building tourism leisure amenity shop village aerialway office residential neighbourhood suburb historic landuse highway retail club railway commercial man_made craft emergency place aeroway industrial junction military ST1 airbnbhostid airbnblistingurl airbnblistingmainimageurl homeawaypropertyid homeawaypropertymanager homeawaylistingurl homeawaylistingmainimageurl listingtitle startdate neighborhood currencynative country country_code road house_number osm_type COUNTYFP STATEFP

/// Save the Merged Dataset
save "${results}/ColoradoPropertyGeoCodeComplete.dta", replace
********************************************************************************
//// Step 6. Merge with the Monthly dataset 
** Load Colorado Data Monthly Data 
use "${results_root}/MonthlyDataColorado.dta", clear 
/// Remove Homeaways
generate prop_id_initial1 = substr(propertyid,1,2)
tab prop_id_initial1
drop if prop_id_initial == "ha"
**** Merge Data Property and Month DataSet
merge m:1 propertyid using "${results}/ColoradoPropertyGeoCodeComplete.dta", keep(match master)
/// Examine Observations not Merged == 109 properties not merged. We lose 1049 observations 
rename _merge merge_property
tab propertyid if merge_property == 1
display r(r)
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
merge m:1 $dimensions using "${results}/ColoradoSalesTaxClean.dta", keep(match master)
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

/// County Lodging Data 
preserve 
// County Lodging Taxes 
import excel "${results}/CountyLodgingTax.xlsx", sheet("CLT") firstrow clear
replace CLDTaxRate = CLDTaxRate*100
rename Year year
drop Semester
duplicates drop County year, force 
drop if County == ""
save "${results}/CLTaxes.dta", replace 
// Local Marketing District Taxes 
import excel "${results}/CountyLodgingTax.xlsx", sheet("LMDT") firstrow clear
replace LMDTaxRate = LMDTaxRate*100
rename Year year 
drop LMD
save "${results}/LMDTaxes.dta", replace 
restore 

/// Do the merge 
merge m:1 County year using "${results}/CLTaxes.dta", keep(match master)
rename _merge LodgeDum
replace LodgeDum = 0 if LodgeDum == 1 
replace LodgeDum = 1 if LodgeDum == 3 


save "${results}/ColoradoPropertyMonthlyMerge.dta", replace

log close 
