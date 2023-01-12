********************************************************************************
********************************************************************************
**** State vs Local Tax Enforcement Effectiveness: Evidence from Airbnb Price Data 
**** By: Justin Ross, Whitney Afonso, Luis Navarro 
**** Last Update: Navarro, Luis 
********************************************************************************
********************************************************************************


/// DO FILE #6 : CLEAN SALES TAX DATA FROM COLORADO

// Directory
clear all 
matrix drop _all

/// Home Rule
/// Strong Assumption
*** The information from the HomeRule covers 80 cities. We assume that if it is not specified in either that dataset or in the current period excel file, then it is a state-collected sales tax city. 
import excel "${bi}/HomeRuleColorado2021.xlsx", firstrow sheet("Home_Rule") clear 
keep JurisdictionCode HomeRule
order JurisdictionCode HomeRule
save "${bt}/HomeRuleJurisCode.dta", replace

/// Step 1. Read the Data 
******* 2016 **********
/// 2nd Semester 2016
import excel "${bi}/Colorado_Jurisdiction_Codes_Rates_July-Dec_2016.xlsx", sheet("By City-Location Codes & Rates") firstrow clear
// Define year and semester of the analyzed data
global year = 2016
global semester = 2 
do "${bc}/ShapeSemesterData.do"

******* 2017 **********
/// 1st Semester 
import excel "${bi}/Colorado_Jurisdiction_Codes_Rates_Jan-June_2017.xlsx", sheet("By City-Location Codes & Rates") firstrow clear
global year = 2017
global semester = 1 
do "${bc}/ShapeSemesterData.do"

/// 2nd Semester 2017
import excel "${bi}/Colorado_Jurisdiction_Codes_Rates_July-Dec_2017.xlsx", sheet("By City-Location Codes & Rates") firstrow clear
global year = 2017
global semester = 2 
do "${bc}/ShapeSemesterData.do"

******* 2018 **********
/// 1st Semester 
import excel "${bi}/Colorado_Jurisdiction_Codes_Rates_Jan-June_2018.xlsx", sheet("By City-Location Codes & Rates") firstrow clear
global year = 2018
global semester = 1 
do "${bc}/ShapeSemesterData.do"
/// 2nd Semester 
import excel "${bi}/Colorado_Jurisdiction_Codes_Rates_July-Dec_2018.xlsx", sheet("By City-Location Codes & Rates") firstrow clear
global year = 2018
global semester = 2 
do "${bc}/ShapeSemesterData.do"

******* 2019 **********
/// 1st Semester 
import excel "${bi}/Colorado_Jurisdiction_Codes_Rates_Jan-June_2019.xlsx", sheet("By City-Location Codes & Rates") firstrow clear
global year = 2019
global semester = 1 
do "${bc}/ShapeSemesterData.do"

/// 2nd Semester 
import excel "${bi}/Colorado_Jurisdiction_Codes_Rates_July-Dec_2019.xlsx", sheet("By City-Location Codes & Rates") firstrow clear
global year = 2019
global semester = 2 
do "${bc}/ShapeSemesterData.do"

******* 2020 **********

/// 1st Semester 
import excel "${bi}/Colorado_Jurisdiction_Codes_Rates_Jan-June_2020.xlsx", sheet("By City-Location Codes & Rates") firstrow clear
global year = 2020
global semester = 1 
do "${bc}/ShapeSemesterData2020.do"

/// 2nd Semester 
import excel "${bi}/Colorado_Jurisdiction_Codes_Rates_July-Dec_2020.xlsx", sheet("By City-Location Codes & Rates") firstrow clear
global year = 2020
global semester = 2 
do "${bc}/ShapeSemesterData2020.do"


******* 2021 **********

/// 1st Semester 
import excel "${bi}/Colorado_Jurisdiction_Codes_Rates_Jan-June_2018.xlsx", sheet("By City-Location Codes & Rates") firstrow clear
global year = 2021
global semester = 1 
do "${bc}/ShapeSemesterData.do"

/// Step 2. Append the Data 
**** Append Data Sets
use "${bt}/ColoradoSalesTax_2017-2.dta", clear
append using "${bt}/ColoradoSalesTax_2016-2.dta", force
append using "${bt}/ColoradoSalesTax_2017-1.dta", force
append using "${bt}/ColoradoSalesTax_2018-1.dta", force
append using "${bt}/ColoradoSalesTax_2018-2.dta", force
append using "${bt}/ColoradoSalesTax_2019-1.dta", force
append using "${bt}/ColoradoSalesTax_2019-2.dta", force
append using "${bt}/ColoradoSalesTax_2020-1.dta", force
append using "${bt}/ColoradoSalesTax_2020-2.dta", force
append using "${bt}/ColoradoSalesTax_2021-1.dta", force
sort Location date County
/// Drop Missings 
drop if Location == ""

********************************************************************************
********************************************************************************
/// Step 3. Clean the Data 

/// County Typos 
** Remove blank spaces
gen county = strrtrim(County)
replace county = "MOFFAT" if county == "MOFFAT (CRAIG IGA)"
replace county = "MOFFAT" if county == "MOFFAT (DINOSAUR IGA)"
replace county = "PITKIN" if county == "PITKIN (in Basalt)"
replace county = "RIO BLANCO" if county == "RIO BLANCO (MEEKER IGA)"
replace county = "RIO BLANCO" if county == "RIO BLANCO (RANGELY IGA)"
replace county = "SUMMIT" if county == "SUMMIT (BLUE RIVER IGA)"
replace county = "SUMMIT" if county == "SUMMIT (BRECKENRIDGE IGA)"
replace county = "SUMMIT" if county == "SUMMIT (FRISCO IGA)"
replace county = "SUMMIT" if county == "SUMMIT (MONTEZUMA IGA)"
replace county = "SUMMIT" if county == "SUMMIT (SILVERTHORNE IGA)"
replace county = "SUMMIT" if county == "SUMMIT (DILLON IGA)"
drop County
rename county County

gen location = strrtrim(Location)
drop Location

********************************************************************************
********************************************************************************
/// Step 4. GET THE RIGHT FIP CODES TO GEOCODE 

/// County Codes -- To Merge 
preserve
import excel "${bi}/Colorado_countycodes.xlsx", firstrow sheet("Codes") clear 
save "${bt}/Colorado_countycodes.dta", replace 
restore 

merge m:1 County using "${bt}/Colorado_countycodes.dta", keep(match master)
drop _merge 
save "${bt}/ColoradoSalesTaxComplete.dta", replace 

********************************************************************************
********************************************************************************
/// County Fip Codes -- To Geocode
preserve
import excel "${bi}/CountyFIPCodes.xlsx", firstrow sheet("CountyFIPS") clear 
keep if State == "CO"
gen County = upper(Name)
drop State Name
save "${bt}/CountyFIPCodesColorado.dta", replace 
restore 

merge m:1 County using "${bt}/CountyFIPCodesColorado.dta", keep(match master)
sort Code
drop _merge 
** Manual Replacement 
replace FIPS = 8014 if County == "BROOMFIELD"
*** Convert to String 
tostring FIPS, gen(fips)
gen zero = 0
tostring zero, gen(Zero)
gen fips_s = Zero + fips
drop FIPS fips zero Zero 
rename fips_s FIPS 
order FIPS Code County location
sort FIPS

drop if FIPS == "0."
save "${bt}/ColoradoSalesTaxComplete.dta", replace 
********************************************************************************
use "${bt}/ColoradoSalesTaxComplete.dta", clear 
//// Step 4. Clean Sales Tax Data 
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

/// Generate the Right County Tax Rate 
/// 1. Save the Actual Sales Tax Rates
preserve 
gcollapse(mean) CountyTaxRate if CountyTaxType == 2, by(County year)
quietly tab County
display r(r)
save "${bt}/countysalestaxaux.dta", replace
restore
// 2. Create a Set that has all the counties and years and merge the variables. This could be done by the xfill command. However, to be sure it is correct i did it manually. 
preserve 
gcollapse(mean) CountyTaxRate, by(County year)
quietly tab County
display r(r)
drop CountyTaxRate
merge 1:1 County year using "${bt}/countysalestaxaux.dta", keep(match master) 
replace CountyTaxRate = 0 if _merge == 1
drop _merge
label variable CountyTaxRate "County Sales Tax Rate"
save "${bt}/CountySalesTaxRates.dta", replace
restore 

///3. Merge the data with the actual county sales tax rate 
drop CountyTaxRate
merge m:1 County year using "${bt}/CountySalesTaxRates.dta", keep(match master) nogen

/// 4. Create the County Lodging Data 
preserve 
// County Lodging Taxes 
import excel "${bi}/CountyLodgingTax.xlsx", sheet("COUNTY_LODTAX") firstrow clear
reshape long CLT, i(County) j(year)
rename CLT countylodtax 
replace countylodtax = countylodtax*100
drop if County == ""
save "${bt}/CountyLodTaxes.dta", replace 
// Local Marketing District Taxes 
import excel "${bi}/CountyLodgingTax.xlsx", sheet("CITY_LODTAX") firstrow clear
duplicates drop City, force 
reshape long CLT AG, i(City) j(year)
rename (CLT AG) (citylodtax airbnbag) 
replace citylodtax = citylodtax*100
drop if City == ""
save "${bt}/CityLodTaxes.dta", replace 
restore 

/// Do the merge County Lodge Taxes 
merge m:1 County year using "${bt}/CountyLodTaxes.dta", keep(match master)
rename _merge countylod_dum
replace countylod_dum = 0 if countylod_dum == 1 
replace countylod_dum = 1 if countylod_dum == 3 
replace countylodtax = 0 if countylodtax == . 
tab County countylod_dum
tab County, summarize(countylodtax) 

/// Do the merge City Lodge Taxes 
rename city City 
merge m:1 City year using "${bt}/CityLodTaxes.dta", keep(match master)
rename _merge citylod_dum
replace citylod_dum = 0 if citylod_dum == 1 
replace citylod_dum = 1 if citylod_dum == 3 
replace citylodtax = 0 if citylodtax == . 
replace airbnbag = 0 if airbnbag == . 
tab City citylod_dum
tab City, summarize(citylodtax) 
rename City city 


/// Generate variable of Additional Applicable Taxes 
/// In General we will consider four additional taxes: i) state sales tax, ii) county sales tax; iii) county lodging tax; iv) city lodging tax 

// Create the variable 
bysort city: generate excisetax = StateSalesTaxRate + CountyTaxRate + countylodtax + citylodtax

/// summary Table 
tabstat citytaxrate excisetax StateSalesTaxRate CountyTaxRate countylodtax citylodtax, by(County)
tabstat citytaxrate excisetax StateSalesTaxRate CountyTaxRate countylodtax citylodtax, by(year)

/// Generate Interactions 
local varlist excisetax StateSalesTaxRate CountyTaxRate countylodtax citylodtax
foreach var of local varlist {
	bysort city: generate `var'hr = `var'*HomeRule 
}

/// Final steps 
label variable homerule_salestax "Local Sales Tax - HR Int"
label variable citytaxrate "Local Sales Tax"
label variable HomeRule "Home Rule"
label variable excisetax "Excise Taxes"
label variable excisetaxhr "Excise Taxes - HR Int"
label variable airbnbag "Airbnb Tax Collection Agreement"
label variable CountyTaxRate "County Sales Tax"
label variable countylodtax "County Lodging Tax"
label variable citylodtax "City Lodging Tax"
*** Save Data 
save "${bt}/ColoradoSalesTaxClean.dta", replace




* source for broomfield fip code https://www.census.gov/programs-surveys/acs/technical-documentation/table-and-geography-changes/2009/geography-changes.html#:~:text=Broomfield%20County%2C%20Colorado&text=Broomfield%20County%20uses%20FIPS%206,%2Fcounty%20code%20(08014).
