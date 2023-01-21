********************************************************************************
********************************************************************************
**** State vs Local Tax Enforcement Effectiveness: Evidence from Airbnb Price Data 
**** By: Justin Ross, Whitney Afonso, Luis Navarro 
**** Last Update: Navarro, Luis 
**** Date: January 14, 2023
**** Script: Descriptive Statistics 
********************************************************************************
********************************************************************************

***** Table 1: Mean Comparison of Outcome Variables Across Treatment Status 
use "${ai}/ColoradoPropertyMonthlyMerge.dta", clear
/// Variables 
global outcomes reservationdays
global model homerule_salestax citytaxrate HomeRule airbnbag excisetax
global conditional modelmiss == 0 & msa_miss == 0

/// Balance Tables to Compare Variables in the Model 
global bal_opts vce(robust) pboth format(%12.3fc) rowvarlabels replace grplabels("0 State-Collection @ 1 Local-Collection")
// Estimate the Balance Table 
iebaltab reservationdays citytaxrate airbnbag excisetax if $conditional, grpvar(HomeRule) savetex("${ao}/Descriptive1_BalanceTable.tex") ${bal_opts}



***** Table 2: Descriptive Statistics
***** Rows: Variables in the Regression: Outcome, indepedents, controls. 
***** Columns: Statistics: Mean, Std Dev, 25th Pctile, Median, 75th Pctile, N 


/// Intensive Margin 
matrix define S = J(5,6,.)
matrix rownames S = "Reservation Days" "Local Collection" "Sales Tax Rate" "Airbnb CA" "Other Taxes"
matrix colnames S = "Mean" "SD" "P25" "Median" "P75" "N"
local i = 1
local varlist reservationdays HomeRule citytaxrate airbnbag excisetax
foreach var of local varlist {
/// Summarize the Variable using the same conditional as in the model. 
qui sum `var' if $conditional , detail 
matrix S[`i',1] = r(mean)
matrix S[`i',2] = r(sd)
matrix S[`i',3] = r(p25)
matrix S[`i',4] = r(p50)
matrix S[`i',5] = r(p75)
matrix S[`i',6] = r(N)
local i = `i' + 1
}

/// Extensive Margin 
qui fillin id reportingmonth 
qui keep id reportingmonth monthlydate modelmiss msa_miss _fillin 

// Step 3. Generate the Binary Outcome 
generate listed = . 
replace listed = 0 if _fillin == 1 
replace listed = 1 if _fillin == 0 

/// Get the Mean
matrix define E = J(1,6,.)
matrix rownames E = "Listed"
matrix colnames E = "Mean" "SD" "P25" "Median" "P75" "N"
/// Summarize the Variable using the same conditional as in the model. 
qui sum listed, detail 
matrix E[1,1] = r(mean)
matrix E[1,2] = r(sd)
matrix E[1,3] = r(p25)
matrix E[1,4] = r(p50)
matrix E[1,5] = r(p75)
matrix E[1,6] = r(N)


**** Export the Results in Tables 
clear 
preserve 
svmat E 
rename E* S*
gen var = "Listed Any Days"
tempfile listed
save `listed', replace 
restore 


clear 
svmat S
gen var = ""
order var 
replace var = "Reservation Days" 		if _n == 1
replace var = "Local Collection"		if _n == 2
replace var = "Sales Tax Rate"			if _n == 3
replace var = "Airbnb Collection Agreement"	if _n == 4
replace var = "Other Taxes"			if _n == 5
**** 
append using `listed', force 


/// Label Variables 
label variable S1 "Mean"
label variable S2 "SD"
label variable S3 "P25"
label variable S4 "P50"
label variable S5 "P75"
label variable S6 "Obs"
format S1 S2 S3 S4 S5 %12.4fc
format S6 %12.0fc


qui tostring S1 S2 S3 S4 S5 , replace force
local varlist S1 S2 S3 S4 S5 
foreach var of local varlist {
qui gen point_pos = strpos(`var',".")
qui replace `var' = substr(`var',1,point_pos + 4) 
qui replace `var' = "0" + `var' if strpos(`var',".") == 1
qui replace `var' = `var' + ".0000" if strpos(`var',".") == 0
qui replace `var' = `var' + "000" if length(`var') == 3
qui drop point_pos
}

list


*** Export the Table 
local title "Descriptive Statistics"
local fn "Notes: Panel A shows the descriptive statistics from the month-property dataset. From this sample we exclude observations from which we could not identify the Metropolitan Statistical Area. Summary statistics for variable \textit{Listed Any Days} are calculated after the rectangularizing the data set in order to have a balance panel of property by month-year. "
texsave using "${ao}/Descriptive_Table2.tex", varlabels hlines(0) nofix replace marker(tab:Descriptive_Table2) title("`title'") footnote("`fn'")
exit 



