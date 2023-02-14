********************************************************************************
********************************************************************************
**** State vs Local Tax Enforcement Effectiveness: Evidence from Airbnb Price Data 
**** By: Justin Ross, Whitney Afonso, Luis Navarro 
**** Last Update: Navarro, Luis 
**** Date: January 20, 2023
**** Script: Descriptive Statistics Across MSA 
********************************************************************************
********************************************************************************

/// Monthly Data 
use "${ai}/ColoradoPropertyMonthlyMerge.dta", clear
sample 10, by(HomeRule)

/// City by MSA
tab metropolitanstatisticalarea HomeRule, rowsort 

table metropolitanstatisticalarea HomeRule delta_tax
*log using "${ao}/LogStackedDIDModel.log", replace 
use "${at}/rcstackdid.dta", clear 
