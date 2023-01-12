clear
use "$bo/KS_SynthControls.dta", clear

xtset propid t
gen chg_Qs = ihs_Qs-L12.ihs_Qs

/* Pick a pre period*/

keep if start_year<2017
drop if t!=36 

/* set up logit model and generate pweights*/

*summarize 

logit ST17 Qs chg_Qs gig investor bedrooms bathrooms maxguests numberofphotos  
predict phat
generate inverse=1/phat

drop if missing(phat)

/*create a data set of the KS observations and a dataset of the donor pool*/

preserve
keep if ST17==1
generate n=_n
save "$bt/KS_props.dta",replace
restore

preserve
keep if ST17==0
save "$bt/KS_donors.dta",replace
restore 

/*Take property's one at a time from KS, find five nearest phat matches, keep them and their matched KS property*/
clear
use "$bt/KS_props.dta", clear
*sample size is 1604


forval i = 1/1604 {
	preserve 
	drop if n!=`i' 
	drop n
	append using "$bt/KS_donors.dta"
	generate absdiff=abs(phat-phat[1])
	egen diffrank=rank(absdiff), unique
	drop if diffrank>6
	keep propid phat
	save "$bt/KS_synthpmatch`i'.dta", replace
	restore
}


/*Because some control units are duplicates that will break unit fixed effects, merge each match file 1 by 1*/
use "$bo/KS_SynthControls.dta", clear

forval i = 1/1604 {
	preserve 
	merge m:1 propid using "$bt/KS_synthpmatch`i'.dta", keep(match) nogenerate
	generate int substack=`i'
	save "$bt/KS_synthpmatchpanel`i'.dta"
	restore
}


/*Now append together all of the files and save*/

clear

use "$bt/KS_synthpmatchpanel1.dta"
forval i=2/1604 {
	append using "$bt/KS_synthpmatchpanel`i'.dta"
}
*need new propid because duplicates if control unit selected more than 1 time across different substacks
recast int propid

sort substack propid t
egen propid2=group(substack propid)

sort propid2 t

duplicates report propid2 t

xtset propid2 t

save "$bo/KS_synthpmatch.dta", replace
save "$ai/KS_synthpmatch.dta", replace

