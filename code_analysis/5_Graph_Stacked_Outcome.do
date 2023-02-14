********************************************************************************
********************************************************************************
**** State vs Local Tax Enforcement Effectiveness: Evidence from Airbnb Price Data 
**** By: Justin Ross, Whitney Afonso, Luis Navarro 
**** Last Update: Navarro, Luis 
**** Date: January 20, 2023
**** Script: Graphs for Parallel Trends  
********************************************************************************
********************************************************************************


use "${at}/rcstackdid.dta", clear 

/// Differences between treatment and control across home rule status remain constant over time 

/// Collapse to take the average across time across treated and HomeRule 
gcollapse (mean) reservationdays, by(et HomeRule treated) 

gen logreservationdays = asinh(reservationdays)
global lineopt lwdith(medthin) lpattern(solid) msize(small) 
global graphopts xline(0,lcolor(black) lpattern(dash) lwidth(vthin)) ylabel(#10, labsize(small) angle(0) nogrid) xlabel(,angle(90) labsize(small) nogrid) 

twoway (connected logreservationdays et if treated == 0, lcolor(black) mcolor(black) msymbol(circle) $lineopt) ///
	(connected logreservationdays et if treated == 1, lcolor(black) mcolor(black) msymbol(circle) $lineopt), ///
	$graphopts name(outcome_stacked, replace) by(HomeRule)
