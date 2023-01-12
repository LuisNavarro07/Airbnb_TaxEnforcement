********************************************************************************
********************************************************************************
**** State vs Local Tax Enforcement Effectiveness: Evidence from Airbnb Price Data 
**** By: Justin Ross, Whitney Afonso, Luis Navarro 
**** Last Update: Navarro, Luis 
********************************************************************************
********************************************************************************
/// Montly Dataset 
/// Open DataSet

clear all 
//// Colorado Airbnb 
use "${ai}/ColoradoPropertyMonthlyMerge.dta", clear

/// Balance Tables to Compare Variables in the Model 
global bal_opts vce(robust) pboth format(%12.3fc) rowvarlabels replace grplabels("0 State-Collection @ 1 Local-Collection")
iebaltab revenueperday totaldays reservationdays if modelmiss == 0, grpvar(HomeRule) savetex(${aodm}/BalanceTableMonthly.tex) ${bal_opts}


/// Daily Analysis 
use "${ai}/DailyDataCleanComplete.dta", clear
generate modelmiss = 0 
replace modelmiss = 1 if priceusd == . | citytaxrate == . 

global bal_opts vce(robust) pboth format(%12.3fc) rowvarlabels replace grplabels("0 State-Collection @ 1 Local-Collection")
iebaltab priceusd if modelmiss == 0, grpvar(HomeRule) savetex(${aodd}/BalanceTableAllPrices.tex) ${bal_opts}
iebaltab priceusd if modelmiss == 0 & status == "R", grpvar(HomeRule) savetex(${aodd}/BalanceTableRentedPrices.tex) ${bal_opts}
