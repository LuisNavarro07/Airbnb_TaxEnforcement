********************************************************************************
********************************************************************************
**** State vs Local Tax Enforcement Effectiveness: Evidence from Airbnb Price Data 
**** By: Justin Ross, Whitney Afonso, Luis Navarro 
**** Last Update: Navarro, Luis 
********************************************************************************

/// DO FILE #2 : SPLIT DATA TO DO THE REVERSE GEOCODE IN R

//// Use Geocode 
/*

Motivation: The problem is that data reporting the city is not accurate. Hence we need to use the geocode command to get the location. 
This will be done in two steps: 
1) For cities with more than 1000 listigns I'll need the city name obtained by geocode command to match with tax data.
2) For cities with less than 1000 listings I'll use the self reported city name by airbnb. So, do nothing. 

Further step: I need to change the way the merge is done. The pivoting is doing overkill.  
Also investigate the meaning of each variable in the data set. 


*/

/// THESE STEPS WERE DONE BEFORE DOING THE GEOCODE IN R
****************************************************************
clear all 
/// Load data 
use "${bt}/Colorado_property_match_stacked.dta", clear
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
save "${bt}/Colorado_Property_GeocodeRaw.dta", replace
/// Below 1000 listings
preserve 
keep if dummy_geocode == 0 
save "${bt}/Colorado_Property_GeocodeRaw_Below1000.dta", replace
restore 
/// Above 1000 listings
preserve 
keep if dummy_geocode == 1 
sort latitude longitude
save "${bt}/Colorado_Property_GeocodeRaw_Above1000.dta", replace
restore 


/// Step 3. Partition the Data Set 
use "${bt}/Colorado_Property_GeocodeRaw_Above1000.dta", clear
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
	quietly save "${geo_in}/Property_Above1000_`i'.dta", replace
	restore
}


exit 
