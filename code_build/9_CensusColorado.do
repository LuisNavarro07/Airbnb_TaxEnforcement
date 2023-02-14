********************************************************************************
********************************************************************************
**** State vs Local Tax Enforcement Effectiveness: Evidence from Airbnb Price Data 
**** By: Justin Ross, Whitney Afonso, Luis Navarro 
**** Last Update: Navarro, Luis 
**** Date: January 20, 2023
**** Script: Clean Census Data
********************************************************************************
********************************************************************************
clear all 
********************************************************************************
import delimited "${bi}/The Government Finance Database_All Data.csv", clear varnames(1)
/// Keep Only Colorado 
statastates, fips(fips_code_state) nogen
keep if state_name == "COLORADO"
/// Keep Only Municipalities 
keep if type_code == 2
/// Only Last Census Year 

***************************************************
// Manual Corrections 
/// Redefine Variables to get nice round numbers
/// Insurance Trust Revenues And Utility Revenues are not included in charges and miscellaneous 
replace tot_chgs_and_misc_rev = tot_chgs_and_misc_rev  + total_insur_trust_rev + total_utility_revenue
// Fire Expenditure (L24 not included in total expenditure)
replace fire_prot_total_expend = fire_prot_total_expend - fire_prot_ig_to_state
/// Total Expenditure in Education (L21 not included in total expenditures)
replace total_educ_total_exp = total_educ_total_exp- educ_nec_ig_to_state

***********************************************************************************
/// Revenue Structure
gen taxes = 100*total_taxes / total_revenue
gen igrev = 100*total_ig_revenue / total_revenue 
gen chgmisc = 100*tot_chgs_and_misc_rev / total_revenue
label variable total_taxes "Taxes"
label variable total_ig_revenue "Intergovernemntal Revenue"
label variable tot_chgs_and_misc_rev "Charges and Miscellaneous"
label variable taxes "Taxes"
label variable igrev "Intergovernemntal Revenue"
label variable chgmisc "Charges and Miscellaneous"
gen revcheck = taxes + igrev + chgmisc


// Total Taxes = Property Taxes + Federal Custom Duties + General Sales and Gross Receipt Taxes + Alcoholic Beverages + 
gen proptaxes = 100*property_tax / total_taxes
gen salestax = 100*tot_sales___gr_rec_tax / total_taxes
gen licensetax = 100*total_license_taxes / total_taxes
gen incometax = 100*total_income_taxes / total_taxes
sum proptaxes salestax licensetax incometax 

label variable property_tax "Property Taxes"
label variable tot_sales___gr_rec_tax "Sales Taxes"
label variable total_license_taxes "License Taxes"
label variable total_income_taxes "Income Taxes"

label variable proptaxes "Property Taxes (% TT)"
label variable salestax "Sales Taxes (% TT)"
label variable licensetax "License Taxes (% TT)"
label variable incometax "Income Taxes (% TT)"

gen taxcheck = proptaxes + salestax + licensetax + incometax 
global taxes proptaxes salestax licensetax incometax   
sum proptaxes salestax licensetax incometax taxcheck 

/// Total IG Revenue = Fed IG Revenue + State IG Revenue 
gen fedrev = 100*total_fed_ig_revenue / total_ig_revenue
gen staterev = 100*total_state_ig_revenue / total_ig_revenue
label variable total_fed_ig_revenue "Federal IG Revenue (% IG Rev)"
label variable total_state_ig_revenue "State IG Revenue (% IG Rev)"
label variable fedrev "Federal IG Revenue (% IG Rev)"
label variable staterev "State IG Revenue (% IG Rev)"
global igrev fedrev staterev 
sum fedrev staterev

/// Charges and Miscellaneous = Total Charges + Miscellaneous 
gen charges = 100*total_general_charges / tot_chgs_and_misc_rev
gen misc = 100*misc_general_revenue / tot_chgs_and_misc_rev
label variable total_general_charges "General Charges"
label variable misc_general_revenue "Miscellaneous Revenue"
label variable charges "General Charges (% Charges and Misc)"
label variable misc "Miscellaneous Rev (%Charges and Misc)"
global charges charges misc
sum charges misc

gen ownsource =  100*total_rev_own_sources / total_revenue

********************************************************************************

gen rest = total_revenue - (property_tax + tot_sales___gr_rec_tax + total_license_taxes + total_income_taxes + total_fed_ig_revenue + total_state_ig_revenue + total_general_charges + misc_general_revenue)

/// Create Proportion Variables 
global analysis property_tax tot_sales___gr_rec_tax total_license_taxes total_income_taxes total_fed_ig_revenue total_state_ig_revenue total_general_charges misc_general_revenue rest
local varlist ${analysis}
foreach var of local varlist{
	gen `var'1 = (`var'/total_revenue)*100
	copydesc `var' `var'1
}


********************************************************************************
/// Expenditure 
/// Total Expenditure = Direct Expenditure + Total IG Expenditure 

gen directexp = 100*direct_expenditure / total_expenditure
gen igexp = 100*total_ig_expenditure / total_expenditure
sum directexp igexp

gen currexp = 100*total_current_expend / total_expenditure
gen capout = 100*total_capital_outlays / total_expenditure

// Label variables for Expenditure
label variable air_trans_total_expend "Air Transportations"
label variable correct_total_exp "Correctional Institutions"
label variable total_educ_total_exp "Total Education"
label variable elem_educ_total_exp "Elementary Education"
label variable higher_ed_total_exp "Higher Education"
label variable educ_nec_total_expend "Federal and State Charges"
label variable fin_admin_total_exp "Financial Administration"
label variable fire_prot_total_expend "Fire Protection"
label variable judicial_total_expend "Judicial and Legal"
label variable cen_staff_total_expend "Central Staff"
label variable gen_pub_bldg_total_exp "General Public Buildings"
label variable health_total_expend "Health"
label variable total_hospital_total_exp "Hospitals"
label variable own_hospital_total_exp "Federal Own Hospitals - Veterans"
label variable hosp_other_total_exp "Federal Other Hospitals - Veterans"
label variable regular_hwy_total_exp "Regular Highways"
label variable toll_hwy_total_expend "Toll Highways"
label variable hous___com_total_exp "Housing and Community Development "
label variable libraries_total_expend "Libraries"
label variable natural_res_total_exp "Nartural Resources, Fish and Forestry"
label variable parking_total_expend "Parkings"
label variable parks___rec_total_exp "Parks and Recreation"
label variable police_prot_total_exp "Police Protection"
label variable prot_insp_total_exp "Protective Inspection and Regulation"
label variable public_welf_total_exp "Public Welfare"
label variable sewerage_total_expend "Sewerage"
label variable sw_mgmt_total_expend "Solid Waste Management"
label variable water_trans_total_exp "Sea and Inland Port Facilities"
label variable general_nec_total_exp "Other"
label variable total_util_total_exp "Total Utilities"
label variable water_util_total_exp "Water Utilities"
label variable elec_util_total_exp "Electric Utilities"
label variable trans_util_total_exp "Transport Utilities"
label variable emp_ret_total_expend "Benefit Payments"
label variable unemp_comp_total_exp "Benefit Payments"

/// Expenditure Variables 
global expends air_trans_total_expend correct_total_exp total_educ_total_exp fin_admin_total_exp fire_prot_total_expend judicial_total_expend cen_staff_total_expend gen_pub_bldg_total_exp health_total_expend total_hospital_total_exp regular_hwy_total_exp toll_hwy_total_expend hous___com_total_exp libraries_total_expend natural_res_total_exp parking_total_expend parks___rec_total_exp police_prot_total_exp prot_insp_total_exp public_welf_total_exp sewerage_total_expend sw_mgmt_total_expend water_trans_total_exp general_nec_total_exp total_util_total_exp emp_ret_total_expend 


// gen aggregated categories 
/// Naco Categories
gen infra_trans = regular_hwy_total_exp + toll_hwy_total_expend + sewerage_total_expend + sw_mgmt_total_expend + total_util_total_exp + water_trans_total_exp + air_trans_total_expend
label variable infra_trans "Transportation and Infrastructure"
gen health = health_total_expend + total_hospital_total_exp
label variable health "Community Health"
gen justice = police_prot_total_exp + correct_total_exp + judicial_total_expend + fire_prot_total_expend + prot_insp_total_exp
label variable justice "Justice and Public Safety"
gen human_serv = public_welf_total_exp + total_educ_total_exp + unemp_comp_total_exp + emp_ret_total_expend
label variable human_serv "Human Services"
gen community = gen_pub_bldg_total_exp + hous___com_total_exp + libraries_total_expend + parking_total_expend + parks___rec_total_exp  + fin_admin_total_exp + cen_staff_total_expend + liquor_stores_tot_exp + emp_sec_adm_direct_exp + natural_res_total_exp + misc_com_activ_tot_exp
label variable community "County Management"
gen others = total_expenditure - (infra_trans + health + justice + human_serv + community) 
label variable community "Interests and Others"



/// Separate the Expenditure between Current and Outlays
// gen aggregated categories 
/// Naco Categories
gen infra_trans_outlay = regular_hwy_cap_outlay + toll_hwy_cap_outlay + sewerage_cap_outlay + sw_mgmt_capital_outlay + total_util_cap_outlay + water_trans_cap_outlay + air_trans_cap_outlay
gen health_outlay = health_capital_outlay + total_hospital_cap_out
gen justice_outlay = police_prot_cap_outlay + correct_cap_outlay + judicial_cap_outlay + fire_prot_cap_outlay + prot_insp_cap_outlay
gen human_serv_outlay = public_welf_cap_outlay + total_educ_cap_outlay
gen community_outlay = gen_pub_bldg_cap_out + hous___com_cap_outlay + libraries_cap_outlay + parking_capital_outlay + parks___rec_cap_outlay  + fin_admin_cap_outlay + cen_staff_cap_outlay + liquor_stores_cap_out + emp_sec_adm_cap_outlay + natural_res_cap_outlay + misc_com_activ_cap_out
gen others_outlay = general_nec_cap_outlay

/// Gen Current Expenditure 
gen infra_trans_current = infra_trans - infra_trans_outlay
gen health_current = health - health_outlay
gen justice_current = justice - justice_outlay
gen human_serv_current = human_serv - human_serv_outlay
gen community_current = community - community_outlay
gen others_current = others - others_outlay

/// Proportion of Capital Outlay 
gen infra_trans_outp = 100*infra_trans_outlay / infra_trans
gen health_outp = 100*health_outlay / health
gen justice_outp = 100*justice_outlay / justice
gen human_serv_outp = 100*human_serv_outlay / human_serv
gen community_outp = 100*community_outlay / community 
gen others_outp = 100*others_outlay / others

/// Label Variable 
local varlist outlay current outp
foreach x of local varlist {
label variable infra_trans_`x' "Transportation and Infrastructure"
label variable health_`x' "Community Health"
label variable justice_`x' "Justice and Public Safety"
label variable human_serv_`x' "Human Services"
label variable community_`x' "County Management"	
label variable others_`x' "Interest and Others"
}

/// Operating Position 
gen operating = total_revenue - total_expenditure

********************************************************************************
/// Choose Variables For Regression Model. 
keep year4 name county fips_place fips_combined total_revenue total_rev_own_sources general_revenue total_taxes property_tax total_gen_sales_tax total_select_sales_tax total_income_taxes total_ig_revenue total_fed_ig_revenue total_general_charges tot_chgs_and_misc_rev total_expenditure total_ig_expenditure direct_expenditure total_capital_outlays general_expenditure state_abbrev state_name taxes igrev chgmisc revcheck proptaxes salestax licensetax incometax taxcheck fedrev staterev charges misc ownsource rest property_tax1 tot_sales___gr_rec_tax1 total_license_taxes1 total_income_taxes1 total_fed_ig_revenue1 total_state_ig_revenue1 total_general_charges1 misc_general_revenue1 rest1 directexp igexp currexp capout infra_trans health justice human_serv community others infra_trans_outlay health_outlay justice_outlay human_serv_outlay community_outlay others_outlay infra_trans_current health_current justice_current human_serv_current community_current others_current infra_trans_outp health_outp justice_outp human_serv_outp community_outp others_outp operating
keep if year4 == 2017 
/// City name Clean 
replace name = subinstr(name," TOWN", "", 1)
replace name = subinstr(name," CITY", "", 1)
rename (name fips_combined) (city fips)
save "${bt}/CensusColoradoCities.dta", replace 

use "${bt}/CensusColoradoCities.dta", clear 
keep 


use "${bt}/taxrates_changes.dta", clear 
merge m:1 city fips using "${bt}/CensusColoradoCities.dta", keep(match master) 
