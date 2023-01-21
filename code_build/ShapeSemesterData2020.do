********************************************************************************
********************************************************************************
*** Merge HomeRule
********************************************************************************
********************************************************************************

rename TaxType State
rename Rate State_SalesTaxRate
rename ServiceFeeRate State_VendorRate
rename K County_TaxType
rename L County_TaxRate
rename M County_VendorRate
rename N Local_TaxType
rename O Local_TaxRate
rename P Local_VendorRate

drop CityExemptionsstatecoll CountyExemptions SpecialDistExemptions
drop Q R S T U V W X Y Z AA AB AC AD AE AF AG AH AI AJ AK AL AM AN AO AP AQ

gen semester = $semester
gen year = $year 
gen quarter = 1 
replace quarter = 3 if semester == 2
gen date = yq($year , quarter)
format date %tq
drop quarter 

merge m:1 JurisdictionCode using "${bt}/HomeRuleJurisCode.dta", keep(match master) nogen 

replace HomeRule = "State-collected" if HomeRule == ""

save "${bt}/ColoradoSalesTax_${year}-${semester}.dta", replace

exit 
