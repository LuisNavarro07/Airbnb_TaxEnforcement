********************************************************************************
********************************************************************************
**** State vs Local Tax Enforcement Effectiveness: Evidence from Airbnb Price Data 
**** By: Justin Ross, Whitney Afonso, Luis Navarro 
**** Last Update: Navarro, Luis 
********************************************************************************
********************************************************************************

/// DO FILE #1 : READ AND CLEAN PROPERTY DATASET 

clear all

********************************************************************************
/// Step 0. Create the data set for the Colorado Analysis
/// Import Data Set
import delimited "${bi}/us_Property_Match_2020-02-11.csv", varnames(1) clear 
keep if state == "Colorado"
save "${bt}/Colorado_Property_Match_2020-02-11.dta", replace 


********************************************************************************

/// Step 1. Shape Data Set
/// Create Variables
generate look1=0
replace look1=1 if substr(propertyid,1,2)!="ab"
replace look1=0 if substr(propertyid,1,2)=="ha"
drop if look1==1
drop look1
tabulate state, generate(ST)
gen startdate=date(createddate,"YMD")
gen start_year = year(startdate)
gen start_month = month(startdate)
drop if propertyid==""
drop if airbnbhostid==.
gen len=length(propertyid)
sum len 
recast str11 propertyid
destring latitude, replace
destring longitude, replace
drop len

save "${bt}/Colorado_Property_Match_2020-02-11.dta", replace 

********************************************************************************
/// Step 2. Geocode Process 
shp2dta using "${bicb}/cb_2016_us_county_500k.shp", ///
	data("${bt}/cb2016_data.dta") coor("${bt}/cb2016_coor.dta") genid(cid) gencentroids(cent) replace
/// This command will add the ID variables, identifying the location of each property
geoinpoly latitude longitude using "${bt}/cb2016_coor.dta"
/// Rename the output from Geoinpoly 
rename _ID cid


********************************************************************************
/// Step 3. Merge GeoCode data with the dataset  

/// Merge with the data set containing all the StateFP, CountyFP and GEOID data
merge m:1 cid using "${bt}/cb2016_data.dta", keep(match) keepusing(STATEFP COUNTYFP GEOID) nogen
/// Create FIPS variable 
generate FIPS = STATEFP + COUNTYFP 
drop cid
save "${bt}/ColoradoFPS_sample_us_property_match.dta", replace


/// Colorado is Number 8
use "${bt}/Colorado_Property_Match_2020-02-11.dta", replace
shp2dta using "${bico}/cb_2018_08_cousub_500k.shp", ///
	data("${bt}/csb_temp_data.dta") coor("${bt}/csb_temp_coor.dta") genid(cid) gencentroids(cent) replace
geoinpoly latitude longitude using "${bt}/csb_temp_coor.dta"
rename _ID cid
mdesc cid

********************************************************************************
********************************************************************************
********************************************************************************

//// Step 4. Merge with the data from the subcounty level coordinates. Erase temp files and save the dataset. 
merge m:1 cid using "${bt}/csb_temp_data.dta", keepusing(COUSUBFP COUSUBNS GEOID NAME STATEFP COUNTYFP) nogen
generate FIPS = STATEFP + COUNTYFP 
drop cid
mdesc STATEFP COUNTYFP
erase "${bt}/csb_temp_data.dta"
erase "${bt}/csb_temp_coor.dta"

//// Step 5. Generate the property id and host variables. 
sort propertyid
egen propid=group(propertyid)
sort airbnbhostid
egen hostid=group(airbnbhostid)

save "${bt}/Colorado_property_match_stacked.dta", replace

********************************************************************************
/// Step 6. Get list of owners of multiple property owners and multistate operators
preserve
keep createddate lastscrapeddate propid hostid
collapse (count) propid, by (hostid)
generate propcount=propid
keep hostid propcount 
save "${bt}/Colorado_hostcount.dta", replace
restore

merge m:1 hostid using "${bt}/Colorado_hostcount.dta"
drop _merge
save "${bt}/Colorado_property_match_stacked.dta", replace

exit 
