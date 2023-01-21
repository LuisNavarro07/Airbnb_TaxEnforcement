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
tempfile HomeRuleJurisCode
save `HomeRuleJurisCode' , replace

/// Step 1. Read the Data 
local file0 "Colorado_Jurisdiction_Codes_Rates_July-Dec_2016.xlsx" 
local file1 "Colorado_Jurisdiction_Codes_Rates_Jan-June_2017.xlsx" 
local file2 "Colorado_Jurisdiction_Codes_Rates_July-Dec_2017.xlsx" 
local file3 "Colorado_Jurisdiction_Codes_Rates_Jan-June_2018.xlsx" 
local file4 "Colorado_Jurisdiction_Codes_Rates_July-Dec_2018.xlsx" 
local file5 "Colorado_Jurisdiction_Codes_Rates_Jan-June_2019.xlsx" 
local file6 "Colorado_Jurisdiction_Codes_Rates_July-Dec_2019.xlsx" 
local file7 "Colorado_Jurisdiction_Codes_Rates_Jan-June_2020.xlsx" 
local file8 "Colorado_Jurisdiction_Codes_Rates_July-Dec_2020.xlsx"

/// Read all the Excel Files 
local yr = 2017 
forvalues i = 1(1)8{
qui import excel "${bi}/`file`i''", sheet("By City-Location Codes & Rates") firstrow clear
qui rename (TaxType Rate K L M N O P) (State State_SalesTaxRate County_TaxType County_TaxRate County_VendorRate Local_TaxType Local_TaxRate Local_VendorRate) 
/// 2020 renaming of the variable 
qui cap rename VendorFeeRate State_VendorRate
qui cap rename ServiceFeeRate State_VendorRate
qui drop CityExemptionsstatecoll CountyExemptions SpecialDistExemptions Q R S T U V W X Y Z AA AB AC AD AE AF AG AH AI AJ AK AL AM AN AO AP AQ
 /// Auxiliary Variable Equal to 1 if it is the first semester of the year and zero if it is the second 
qui gen semaux = mod(`i',2)
qui qui sum semaux
qui local semaux = r(mean) 
qui gen semester = semaux
qui replace semester = 2 if semaux == 0 
qui gen year = `yr' 
qui gen quarter = 1 
qui replace quarter = 3 if semester == 2
qui gen date = yq(`yr' , quarter)
qui drop quarter semaux
/// Merge using jurisdiction codes to determine whether the county has home rule status or not 
qui merge m:1 JurisdictionCode using `HomeRuleJurisCode', keep(match master) nogen
/// Assumption: unmatched observations we assume that have state-collection 
qui replace HomeRule = "State-collected" if HomeRule == ""
qui tempfile coloradotax`i'
qui save `coloradotax`i'', replace
/// Update the Year counter such that in only adds one afther the second semester
if `semaux' == 1 {
	local yr = `yr'
}
else {
	local yr = `yr' + 1
}
}

//// First Year 
import excel "${bi}/`file0'", sheet("By City-Location Codes & Rates") firstrow clear
rename (TaxType Rate K L M N O P) (State State_SalesTaxRate County_TaxType County_TaxRate County_VendorRate Local_TaxType Local_TaxRate Local_VendorRate) 
cap rename VendorFeeRate State_VendorRate
cap rename ServiceFeeRate State_VendorRate
drop CityExemptionsstatecoll CountyExemptions SpecialDistExemptions Q R S T U V W X Y Z AA AB AC AD AE AF AG AH AI AJ AK AL AM AN AO AP AQ
/// Auxiliary Variable Equal to 1 if it is the first semester of the year and zero if it is the second 
qui gen semester = 2
qui gen year = 2016 
qui gen quarter = 1 
qui replace quarter = 3 if semester == 2
qui gen date = yq(year , quarter)
qui drop quarter
qui merge m:1 JurisdictionCode using `HomeRuleJurisCode', keep(match master) nogen
qui replace HomeRule = "State-collected" if HomeRule == ""
qui tempfile coloradotax0
qui save `coloradotax0', replace

********************************************************************************
/// Step 2. Append the Data 
**** Append Data Sets
use `coloradotax0' , clear
forvalues i = 1(1)8{
append using `coloradotax`i'', force 
}
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
/// Contains all 64 counties from Colorado 
gen location = strrtrim(Location)
drop Location

********************************************************************************
********************************************************************************
/// Step 4. GET THE RIGHT FIP CODES TO GEOCODE 

/// County Codes -- To Merge 
preserve
import excel "${bi}/Colorado_countycodes.xlsx", firstrow sheet("Codes") clear
tempfile colorado_countycodes 
save `colorado_countycodes', replace 
restore 

merge m:1 County using `colorado_countycodes', keep(match master) nogen
/// County Fip Codes -- To Geocode
/// Get State and County Fip Codes 
gen stname = "COLORADO"
statastates, name(stname) nogen
countyfips, name(County) statefips(state_fips) nogen 

********************************************************************************
********************************************************************************

//// Step 5. Clean Sales Tax Data 
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
rename cityname2 city 
/// Check that city fips and semester uniquely identify the observations in the dataset 
duplicates report city fips date

/// Variables not needed 
drop location cityname cityname1 par mail drop_index unic State

/// Homogenize Home Rule Variable
encode HomeRule, gen(homerule)
drop HomeRule
rename homerule HomeRule
replace HomeRule = 0 if HomeRule == 2
label define HomeRule 0 "State-Collected" 1 "Self-Collected"
label values HomeRule HomeRule
//// rename for simplicity 
rename (State_SalesTaxRate State_VendorRate County_TaxType County_TaxRate County_VendorRate Local_TaxType Local_TaxRate Local_VendorRate) /// 	
	(StateSalesTaxRate StateVendorRate CountyTaxType CountyTaxRate CountyVendorRate LocalTaxType LocalTaxRate LocalVendorRate)

/// view the time dimension of the dataset
tabulate year semester
/// City Sales Tax Rates are messed up, need to create a variable that stores them properly 
tab LocalTaxType, sort  
tab CountyTaxType, sort 
/// 492 observations contain a city sales tax rate stored in the county column
/// 1,557 observations contain city sales tax rate in the city column
/// check there is no overlap
generate taxtypeaux = 0 
replace taxtypeaux = 1 if CountyTaxType == "City" & LocalTaxType == "City"
drop taxtypeaux
/// Result: there is no overlap 
********************************************************************************
/// Step 6. Create City Sales Tax Variable 
/// Create the variable 
generate citytaxrate = . 
replace citytaxrate = CountyTaxRate if CountyTaxType == "City"
replace citytaxrate = LocalTaxRate if LocalTaxType == "City"

/// CarryForward -- This will fill the blanks for all city tax rates that have missings in between the time series and that do not experienced a change in the tax rate. 
// city FIPS is the unique identifier because we could have some cities that overlap in counties. Example: we have Denver that has tax rates for different FIP Codes
duplicates tag date city, gen(d1)
tab city if d1 >= 1 
// 29 cities appear in more than one county
tab fips if d1 >= 1
drop d1
// There are 26 counties that have a city overlapping in to two counties 
/// Check Unique IDs
duplicates report date city fips
egen cityid = group(city fips)
sort city fips date
/// Create variable to identify which observations have blanks in between the series
gen missdate = 0
replace missdate = 1 if citytaxrate == . 
tab date missdate
// Do the CarryForward. This will assume that the last tax rate observed remains the same
bysort cityid: carryforward citytaxrate, replace 
label variable citytaxrate "Local Sales Tax"

*******************************************************************************

/// Create Interaction Rate Home Rule 
generate homerule_salestax = HomeRule * citytaxrate 
label variable homerule_salestax "Local Sales Tax - Home Rule Int"
bysort year: mdesc citytaxrate homerule_salestax

/// Variation Analysis - HomeRule and City Tax Rates
*** Restrict the sample 
*********************************************************************************
keep if year == 2017 | year == 2018 | year == 2019
*********************************************************************************
** Panel setting 
xtset cityid date
xtsum citytaxrate

/// Keep only locations from which we have certainty abou their city sales tax rate 
keep if CountyTaxType == "City" | LocalTaxType == "City"
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
gcollapse(mean) CountyTaxRate if CountyTaxType == "City", by(County year)
tempfile countysalestaxaux
save `countysalestaxaux', replace
restore
// 2. Create a Set that has all the counties and years and merge the variables. This could be done by the xfill command. However, to be sure it is correct i did it manually. 
preserve 
gcollapse(mean) CountyTaxRate, by(County year)
drop CountyTaxRate
merge 1:1 County year using `countysalestaxaux', keep(match master) 
replace CountyTaxRate = 0 if _merge == 1
drop _merge
label variable CountyTaxRate "County Sales Tax Rate"
tempfile countysaletaxrates
save `countysaletaxrates', replace
restore 

///3. Merge the data with the actual county sales tax rate 
drop CountyTaxRate
merge m:1 County year using `countysaletaxrates', keep(match master) nogen

/// 4. Create the County Lodging Data 
preserve 
// County Lodging Taxes 
import excel "${bi}/CountyLodgingTax.xlsx", sheet("COUNTY_LODTAX") firstrow clear
reshape long CLT, i(County) j(year)
rename CLT countylodtax 
replace countylodtax = countylodtax*100
drop if County == ""
tempfile countylodtaxes
save `countylodtaxes', replace 
// Local Marketing District Taxes 
import excel "${bi}/CountyLodgingTax.xlsx", sheet("CITY_LODTAX") firstrow clear
duplicates drop City, force 
reshape long CLT AG, i(City) j(year)
rename (CLT AG) (citylodtax airbnbag) 
replace citylodtax = citylodtax*100
drop if City == ""
tempfile citylodtaxes
save `citylodtaxes' , replace 
restore 

/// Do the merge County Lodge Taxes 
merge m:1 County year using `countylodtaxes' , keep(match master)
rename _merge countylod_dum
replace countylod_dum = 0 if countylod_dum == 1 
replace countylod_dum = 1 if countylod_dum == 3 
replace countylodtax = 0 if countylodtax == . 
tab County countylod_dum
tab County, summarize(countylodtax) 

/// Do the merge City Lodge Taxes 
rename city City 
merge m:1 City year using `citylodtaxes', keep(match master)
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
