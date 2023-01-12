********************************************************************************
********************************************************************************
**** State vs Local Tax Enforcement Effectiveness: Evidence from Airbnb Price Data 
**** By: Justin Ross, Whitney Afonso, Luis Navarro 
**** Last Update: Navarro, Luis 
********************************************************************************
********************************************************************************
/// Montly Dataset 
/// Open DataSet

preserve 
use "${ai}/ColoradoPropertyMonthlyMerge.dta", clear
gcollapse (count) id, by(metropolitanstatisticalarea FIPS)
merge m:1 FIPS using "${bt}/cbsa2fipscomplete.dta", keep(match master using) nogen 
gen msa_miss = . 
replace msa_miss = 1 if metropolitanstatisticalarea != ""
replace msa_miss = 0 if metropolitanstatisticalarea == ""
save "${bt}/msa2fipscomplete.dta", replace 
restore 

/// HomeRule Maps - County Level 
use "${bt}/ColoradoSalesTaxClean.dta", clear 
gcollapse (mean) HomeRule excisetax citytaxrate, by(FIPS)
merge m:1 FIPS using "${bt}/msa2fipscomplete.dta", keep(match master using) 
gen state = "Colorado"
replace HomeRule = 0 if HomeRule == . 
rename FIPS county
destring county, replace
drop if county == .
gen homerule = 0  
replace homerule = 1 if HomeRule > 0 

tab metropolitanstatisticalarea, gen(msa)
global msa = r(r)
/// Variables for MSA analysis 
gen msazone = 0 
replace msazone = 1 if msa1 == 1 | msa3 == 1 | msa4 == 1 | msa6 == 1 | msa15 == 1
replace msazone = 2 if msa2 == 1 | msa5 == 1 | msa7 == 1 | msa8 == 1 | msa11 == 1 | msa12 == 1 | msa14 == 1 | msa16 == 1
replace msazone = 3 if msa9 == 1 | msa10 == 1 | msa13 == 1 | msa17 == 1 
tab msazone if msazone > 0 

/// Home Rule Map
global options_map title("HomeRule", size(vsmall)) legend(size(vsmall)) name(HomeRule1, replace) 
maptile HomeRule , geo(county2014) mapif(state =="Colorado") twopt($options_map)
*graph export "${aodm}/HomeRuleMap.png",  ${export}
/// CBS Map 
global options_map title("Metropolitan Statistical Areas", size(vsmall)) legend(size(vsmall)) name(CBS1, replace) legend(lab(2 "No MSA") lab(3 "MSA"))
maptile msa_miss , geo(county2014) mapif(state =="Colorado") twopt($options_map) 
*graph export "${aodm}/CBSMap.png",  ${export}
/// Local Sales Tax Map 
global options_map title("Local Sales Tax", size(vsmall)) legend(size(vsmall)) name(Local1, replace) 
maptile citytaxrate , geo(county2014) mapif(state =="Colorado") twopt($options_map) 
*graph export "${aodm}/LocalSalesTaxMap.png", ${export}
/// Excise Tax
global options_map title("Other Taxes", size(vsmall)) legend(size(vsmall)) name(Excise1, replace) 
maptile excisetax , geo(county2014) mapif(state =="Colorado") twopt($options_map)
*graph export "${aodm}/ExciseTaxMap.png", ${export}

graph combine CBS1 Local1 HomeRule1 Excise1, cols(2) rows(2) 
graph export "${aodm}/MapsCombined.png", ${export}

/// MSA Zone for Analysis
global options_map title("MSAs for Analysis", size(vsmall)) legend(size(vsmall)) name(MSAZone, replace) legend(lab(2 "No MSA") lab(3 "Zone 1") lab(4 "Zone 2") lab(5 "Zone 3"))
maptile msazone, geo(county2014) mapif(state =="Colorado") twopt($options_map) 
graph export "${aodm}/MapsMSAZoneAnalysis.png", ${export}



//// Airbnb Data 

use "${ai}/ColoradoPropertyMonthlyMerge.dta", clear
// property map 
preserve 
duplicates drop propertyid, force 
gcollapse (count) id, by(metropolitanstatisticalarea FIPS)
merge m:1 FIPS using "${bt}/cbsa2fipscomplete.dta", keep(match master using)
gen state = "Colorado"
rename FIPS county
destring county, replace 
/// Map. Number of Properties per County 
global options_map title("Number of Properties", size(vsmall)) legend(size(vsmall)) name(Prop1, replace) 
maptile id , geo(county2014) mapif(state =="Colorado") twopt($options_map)
restore 

gcollapse (count) id (mean) cbsdum HomeRule revenueperday totaldays revenueusd, by(metropolitanstatisticalarea FIPS)
merge m:1 FIPS using "${bt}/cbsa2fipscomplete.dta", keep(match master using) 
gen state = "Colorado"
rename FIPS county
destring county, replace 
/// Maps
global options_map title("Avg Daily Revenue", size(vsmall)) legend(size(vsmall)) name(Price1, replace) 
maptile revenueperday , geo(county2014) mapif(state =="Colorado") twopt($options_map)

global options_map title("Monthly Revenue", size(vsmall)) legend(size(vsmall)) name(Rev1, replace) 
maptile revenueusd , geo(county2014) mapif(state =="Colorado") twopt($options_map)

global options_map title("Listed Days", size(vsmall)) legend(size(vsmall)) name(Days1, replace) 
maptile totaldays , geo(county2014) mapif(state =="Colorado") twopt($options_map)

graph combine Prop1 Price1 Days1 Rev1, cols(2) rows(2) 
graph export "${aodm}/MapsCombinedAirbnb.png", ${export}


graph combine Prop1 Price1 CBS1 MSAZone, cols(2) rows(2)
graph export "${aodm}/MapsMSA.png", ${export} 
