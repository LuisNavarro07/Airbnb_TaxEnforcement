********************************************************************************
********************************************************************************
**** State vs Local Tax Enforcement Effectiveness: Evidence from Airbnb Price Data 
**** By: Justin Ross, Whitney Afonso, Luis Navarro 
**** Last Update: Navarro, Luis 
********************************************************************************
********************************************************************************

/// DO FILE #4 : APPEND GEOCODED DATA FROM R

// Directory
clear all 
matrix drop _all

//// Merge R ouputs from reverse geocode 
forvalues i = 1(1)34{
	quietly import delimited "${geo_out}/ColoradoReverse_`i'.csv", varnames(1) encoding(ISO-8859-2) clear 
	quietly save "${geo_temp}/ColoradoReverse_`i'.dta", replace 
}

use "${geo_temp}/ColoradoReverse_1.dta", clear

forvalues i = 2(1)34{
	quietly append using "${geo_temp}/ColoradoReverse_`i'.dta" 
}
save "${geo_save}/ColoradoReverse_full.dta", replace 

***************************************************************************
// Input Files 
use "${geo_in}/Property_Above1000_1.dta", clear
forvalues i = 2(1)34{
	append using "${geo_in}/Property_Above1000_`i'.dta" 
}

merge 1:1 propertyid using "${geo_save}/ColoradoReverse_full.dta", keep(match master) nogen 

drop groupid* check city_dum*
gen county_name = upper(county)
drop county
rename county_name govname
save "${geo_save}/ColoradoReverse_merged.dta", replace 

***************************************************************************
/// Get County Fip Codes 
use "${geo_save}/ColoradoReverse_merged.dta", clear
merge m:1 state govname using "${bt}/CountyCodes.dta", keep(match master)
save "${geo_save}/ColoradoReverse_merged.dta", replace 


********************************************************************************

