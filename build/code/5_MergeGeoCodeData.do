********************************************************************************
********************************************************************************
**** State vs Local Tax Enforcement Effectiveness: Evidence from Airbnb Price Data 
**** By: Justin Ross, Whitney Afonso, Luis Navarro 
**** Last Update: Navarro, Luis 
********************************************************************************
********************************************************************************

/// DO FILE #5 : MERGE GEOCODED DATA FROM R WITH DATA WITH AIRBNB COUNTY FIPS 
clear all 
/// This is the set for the above 1000 (we did this dataset through R)
use "${geo_save}/ColoradoReverse_merged.dta", clear
/// This is the set for the below 1000
/// Append
append using "${bt}/Colorado_Property_GeocodeRaw_Below1000.dta"
/// Clean some unecessary variables resulting from the merging process (Above DataSet)
drop hamlet town building tourism leisure amenity shop village aerialway office residential neighbourhood suburb historic landuse highway retail club railway commercial man_made craft emergency place aeroway industrial junction military
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
generate FIPS = ""
replace FIPS = county_fips_code0 if dummy_geocode == 0 
replace FIPS = county_fips if dummy_geocode == 1
/// Save the Merged Dataset
save "${bt}/ColoradoPropertyGeoCodeComplete.dta", replace

exit 
