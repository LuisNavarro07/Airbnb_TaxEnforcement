
This file describes in detail the workflow for the scripts that replicate State vs Local Tax Enforcement Effectiveness. 

- *Data Cleaning and Processing (Build)*
  
	1.	1_CleanGeoCodePropertyData.do
	2.	2_SplitPropertyDataForGeoCode.do
	3.	3_ReverseGeoCode_Colorado.R
	4.	4_AppendGeoCodeDataFromR.do
	5.	5_MergeAllGeocodedData.do
	6.	6_CleanSalesTaxData.do
	7.	7_MergeMonthlyPropertyTax.do
	8.	8_PSM_Balance.R
	9.	9_Build_Feasible_Stacked_DID_Data.do
	10.	10_CreateMarketLevelData.do


- *Data Analysis and Regression Models (Analysis)*


# Data Cleaning and Processing (Build)

## Script: 1_CleanGeoCodePropertyData.do

### Description
This script processes and geocodes a dataset of Airbnb property listings in Colorado as part of the project *State vs. Local Tax Enforcement Effectiveness: Evidence from Airbnb Price Data*. It begins by filtering a nationwide dataset to retain only Colorado properties and cleans the data by removing invalid or duplicate entries, generating date variables, and formatting coordinates. It then performs geospatial joins using U.S. Census shapefiles to assign county and subcounty FIPS codes based on property coordinates. The script creates unique identifiers for each property and host, calculates how many properties each host owns, and merges this information back into the main dataset. The output is a cleaned and geocoded dataset ready for analysis.

### Inputs
- `us_Property_Match_2020-02-11.csv`: Nationwide Airbnb property dataset.
- Shapefiles for geocoding:
  - `cb_2016_us_county_500k.shp` – U.S. county boundaries.
  - `cb_2018_08_cousub_500k.shp` – Colorado subcounty boundaries.

### Outputs
- `Colorado_Property_Match_2020-02-11.dta`: Cleaned Airbnb property data for Colorado.
- `cb2016_data.dta` and `cb2016_coor.dta`: Converted county shapefile data.
- `ColoradoFPS_sample_us_property_match.dta`: Property data with merged county-level FIPS codes.
- `Colorado_property_match_stacked.dta`: Final cleaned dataset with county and subcounty geocodes and host/property IDs.
- `Colorado_hostcount.dta`: Summary of the number of properties owned by each host.

## Script: 2_SplitPropertyDataForGeoCode.do

### Description
This script prepares Airbnb property data for a reverse geocoding process in R to correct inaccuracies in self-reported city names. It identifies cities in Colorado with more than 1,000 property listings and flags those for reverse geocoding using latitude and longitude coordinates. Cities with fewer listings retain the original Airbnb-reported city name. The dataset is then split into two subsets: one for properties requiring geocoding (large cities) and one for those that do not (small cities). To facilitate batch geocoding in R, the subset for large cities is further divided into manageable chunks of ~2,500 observations each, and each chunk is saved as a separate file for processing.

### Inputs
- `Colorado_property_match_stacked.dta`: Cleaned and geocoded Airbnb dataset from Script #1.

### Outputs
- `Colorado_Property_GeocodeRaw.dta`: Full dataset with geocoding flags.
- `Colorado_Property_GeocodeRaw_Below1000.dta`: Properties in cities with fewer than 1,000 listings (no further geocoding required).
- `Colorado_Property_GeocodeRaw_Above1000.dta`: Properties in cities with 1,000+ listings (flagged for geocoding).
- `Property_Above1000_*.dta`: Partitioned subsets (∼2,500 records each) of the above-1000 group, saved individually for R-based reverse geocoding.

## Script: 3_ReverseGeoCode_Colorado.R

### Description
This R script performs reverse geocoding on Airbnb property listings located in Colorado cities with more than 1,000 listings, using latitude and longitude coordinates to retrieve standardized location data (such as city and administrative areas). It uses the `tidygeocoder` package with the OpenStreetMap (OSM) geocoding service. The script loops through 34 Stata `.dta` files containing batches of approximately 2,500 observations each (prepared in the previous Stata script), extracts the geographic coordinates and property IDs, and performs reverse geocoding. The results are saved as `.csv` files for later merging with the original dataset. A sample run on 10 observations is included at the end of the script for testing and debugging.

### Inputs
- `Property_Above1000_1.dta` to `Property_Above1000_34.dta`: Stata files containing Airbnb property listings with coordinates requiring geocoding (output from Script #2).

### Outputs
- `ColoradoReverse_1.csv` to `ColoradoReverse_34.csv`: Reverse-geocoded property datasets saved as `.csv` files containing address information retrieved via OpenStreetMap.

## Script: 4_AppendGeoCodeDataFromR.do

### Description
This script consolidates the reverse-geocoded outputs generated in R (from Script #3) and merges them back into the original Airbnb dataset for Colorado properties with over 1,000 listings per city. It first imports 34 individual `.csv` files (one per geocoded chunk), converts them to Stata `.dta` format, and appends them into a single file. Then, it loads and appends the corresponding 34 input property files, merging them one-to-one by `propertyid` with the geocoded results. After cleaning auxiliary variables and renaming columns, the script merges the resulting dataset with a county-level FIPS code lookup table to associate each property with its official county identifier. The final merged dataset includes standardized location data necessary for the tax enforcement analysis.

### Inputs
- `ColoradoReverse_1.csv` to `ColoradoReverse_34.csv`: Reverse-geocoded output files from R.
- `Property_Above1000_1.dta` to `Property_Above1000_34.dta`: Airbnb property data requiring geocoding.
- `CountyCodes.dta`: Lookup table mapping county names to official FIPS codes.

### Outputs
- `ColoradoReverse_full.dta`: Appended reverse-geocoded address dataset.
- `ColoradoReverse_merged.dta`: Final merged dataset that joins geocoded results with Airbnb properties and includes county FIPS codes.

## Script: 5_MergeAllGeocodedData.do

### Description
This script merges the reverse-geocoded property dataset (created from cities with more than 1,000 Airbnb listings) with the dataset containing properties from smaller cities (with fewer than 1,000 listings). It consolidates both datasets into a single file and ensures that each property is assigned an appropriate county FIPS code. Properties that did not go through reverse geocoding retain their original FIPS code from Airbnb, while geocoded properties use the updated FIPS from OpenStreetMap data. The script also cleans unneeded variables left over from the merging process and creates a helper variable to identify the origin of each `propertyid`. The resulting dataset is the comprehensive geocoded property file used in the core analysis.

### Inputs
- `ColoradoReverse_merged.dta`: Geocoded property data from cities with 1,000+ listings (from Script #4).
- `Colorado_Property_GeocodeRaw_Below1000.dta`: Property data from smaller cities that did not require geocoding.

### Outputs
- `ColoradoPropertyGeoCodeComplete.dta`: Fully merged and cleaned dataset of all Airbnb properties in Colorado, each with an assigned county FIPS code.

## Script: 6_CleanSalesTaxData.do

### Description
This script compiles, cleans, and harmonizes local sales tax data for jurisdictions in Colorado from 2016 to 2020. It begins by importing official sales tax rate spreadsheets from the Colorado Department of Revenue and merges them with a home rule classification dataset to distinguish between state- and self-collected jurisdictions. After standardizing naming conventions and correcting inconsistencies in county and city labels, the script merges in official county FIPS codes to facilitate geographic alignment with Airbnb property data. It constructs the primary city-level sales tax variable by extracting tax rates stored in different columns depending on jurisdiction type and uses carryforward methods to impute missing values in otherwise stable time series.

The script also integrates auxiliary tax datasets, including county and city lodging taxes and information on Airbnb tax collection agreements. It then constructs a composite **excise tax** variable as the sum of state, county, and lodging taxes, and interacts each tax with the home rule indicator to allow for heterogeneous treatment effects in the empirical analysis. The final output is a cleaned panel dataset with consistent city identifiers, time-stamped tax rates, and relevant fiscal indicators, used throughout the main analysis.

### Inputs
- `HomeRuleColorado2021.xlsx`: Classification of jurisdictions as state- or self-collected.
- `Colorado_Jurisdiction_Codes_Rates_*.xlsx`: Colorado DOR tax rate files for 2016–2020 (by semester).
- `Colorado_countycodes.xlsx`: Lookup table for official FIPS codes.
- `CountyLodgingTax.xlsx`: Contains both county and city lodging tax rates and Airbnb agreement status.

### Outputs
- `ColoradoSalesTaxClean.dta`: Final cleaned and merged dataset of city-level tax rates and jurisdiction characteristics (2017–2019 sample) with all relevant covariates for analysis.

## Script: 7_MergeMonthlyPropertyTax.do

### Description
This script merges Airbnb's monthly-level property performance data with geocoded location data and tax information to build the final panel dataset used in the empirical analysis. It first processes the raw CSV file of monthly listings and filters for properties located in Colorado. It then merges in city-level tax rates, home rule status, and other fiscal variables using a combination of FIPS codes, ZIP codes, and city names. Manual adjustments ensure accurate classification of home rule jurisdictions when missing. The script also aligns temporal variables, such as semester and monthly date formats, to ensure proper matching.

After merging, the script constructs derived variables including **revenue per day**, total listing days, and indicators for missing data. It filters the sample to 2017–2019 and retains only listings located in Metropolitan or Micropolitan Statistical Areas (MSAs). Finally, the script merges MSA identifiers using crosswalk files and saves a cleaned dataset containing only the variables needed for the analysis.

### Inputs
- `us_Monthly_Match_2020-02-11.csv`: Nationwide Airbnb monthly-level performance dataset.
- `ColoradoPropertyGeoCodeComplete.dta`: Geocoded property dataset (from Script #5).
- `ColoradoSalesTaxClean.dta`: Cleaned tax data with home rule status and city sales tax (from Script #6).
- `salestaxdatafull_1523.dta`: National tax dataset with monthly ZIP-code-level rates.
- `cbsa2fipsxw.dta`: Crosswalk of county FIPS codes to CBSA/MSA codes.
- `CountyCodes.dta`: State and county FIPS metadata.

### Outputs
- `ColoradoMonthlyData.dta`: Intermediate monthly dataset filtered to Colorado.
- `ColoradoAllSalesTaxes.dta`: Monthly city-level tax rates aligned with Airbnb data.
- `ColoradoPropertyMonthlyMerge.dta`: Final cleaned panel dataset for econometric analysis (property × month) with tax, location, and performance measures.

## Script: 8_PSM_Balance.R

### Description

This R script builds a set of propensity score models to assess the impact of local tax enforcement on Airbnb hosts in Colorado. It merges tax change data with ZIP- and county-level demographics, evaluates covariate balance via standardized mean differences (SMDs), and performs forward stepwise variable selection to minimize overall imbalance. The script outputs datasets with inverse probability weights, covariate balance tables, love plots, and formatted regression summaries.

### Inputs

- `taxrates_changes.dta`: Monthly Airbnb tax data with treated/control indicators.
- `colorado_zipcode_data.dta`: ACS ZIP-level data (2017).
- `colorado_county_data.dta`: ACS county-level data (2017).
- `R packages`: `MatchIt`, `cobalt`, `ebal`, `fixest`, `ggplot2`, `cowplot`, `rio`, `xtable`, etc.

### Outputs

- `colorado_psm_data.dta`: Matched dataset with predicted scores and weights.
- `pscores_data.dta`: Contains `pscore`, `pscore_min`, `pscore_hr`, and `pscore_hr_min` for treatment variants.
- `pscore_table_taxchange.tex` / `.jpg`: Latex and image versions of PSM regression tables.
- `balance_table_plot.jpg`: Love plot of covariate balance for baseline PSM.
- `balance_table_plot_comp.jpg`: Love plot comparing different PSM weighting schemes.
- `balance_table_descriptive_vars.tex` / `.jpg`: Table of means and t-tests (weighted vs unweighted).
- `balance_table_comp.tex` / `.jpg`: Combined table comparing different PSM approaches.

### Functions or Programs Created

- `format_plot(graph)`: Applies custom theme and layout for ggplot objects.
- `save_graph(graph, name, size)`: Saves plots to file with consistent style.
- `table_image(table, caption, file)`: Converts data frames to captioned JPEG tables.
- `evaluate_ps_formula(formula, data)`: Runs a PS model and calculates covariate balance.
- `forward_stepwise_sasmd(candidate_vars, data)`: Selects covariates minimizing SMD using forward search.
- `test_weighted(data)`: Produces mean/sd stats and weighted vs unweighted t-tests for a covariate.

## Script: 9_Build_Feasible_Stacked_DID_Data.do

### Description
This script implements the **stacked Difference-in-Differences design** following the procedure developed by Alex Hollingsworth, Coady Wing and Seth Freedman. It constructs multiple sub-experiments based on distinct tax change dates (referred to as "focal adoption times") and stacks them to form a single dataset for estimation. The key idea is to treat each tax change as a separate treatment event and use never-treated or late-treated cities as clean controls, trimming the event window to ±11 months around the intervention.

The script defines and applies a program (`create_sub_exp`) to generate event-time variables and sub-experiment indicators for each treatment cohort, ensuring pre- and post-treatment balance. After stacking the individual datasets, it restricts the sample to valid comparisons, drops ambiguous cases (e.g., early or late adopters), and computes proper weighting schemes for treated and control units. The script further merges in precomputed propensity score weights, constructs adjusted weights for estimation, and saves a fully formatted panel dataset ready for use in stacked DiD estimation with covariate and weighting flexibility.

### Inputs
- `ColoradoPropertyMonthlyRectangular.dta`: Fully rectangularized panel of Airbnb listings merged with tax and geo variables.
- `pscores_data.dta`: Precomputed propensity score weights by sub-experiment and ZIP code.

### Outputs
- `airbnb_subexp*.dta`: Sub-experiment-specific datasets generated per treatment date (temporary files).
- `rcstackdid_rectangular.dta`: Final stacked DiD dataset with:
  - Treatment assignment and event-time variables
  - Listing activity flags
  - Sub-experiment-specific weights and adjusted propensity score weights

### Functions or Programs Created
- `create_sub_exp`: A custom program that generates treatment/control status, event time, and sub-experiment indicators based on focal adoption time and feasibility windows.
- `compute_weights`: A helper function to calculate normalized weights for treated and control units within each sub-experiment.

## Script: 10_CreateMarketLevelData.do

### Description

This Stata script constructs a market-level dataset from Colorado Airbnb property data for use in a stacked Difference-in-Differences (DiD) analysis. It aggregates observations by ZIP code, city, and sub-experiment to compute average tax policy variables and listing intensity (as a share of local housing units). It also generates treatment indicators, event-time dummies, and normalized weights for each market-level observation. This data structure enables estimation of the policy effects at an aggregate scale.

### Inputs

- `${ai}/colorado_psm_data.dta`: Matched Airbnb property-level data with treatment info.
- `${ai}/pscores_data.dta`: Propensity score weights by ZIP code and sub-experiment.
- `${ai}/rcstackdid_rectangular.dta`: Rectangular property-level panel dataset.

### Outputs

- `${ai}/rcstackdid_mkt.dta`: Market-level panel dataset for stacked DiD estimation, with weights and covariates.

## Functions Created

- `market_level_data`: A Stata program that (1) aggregates listing and policy data to the ZIP-level, (2) merges housing unit counts, (3) computes listing density, and (4) constructs DiD weights using the `compute_weights` program from earlier scripts.


# Data Analysis and Regression Estimation 

## 0_Programs.do 

### Description 

This stata script contains all the user-written programs that are used for the regression analysis. 

### Programs Created 

- `final_prep_stacked`: final data prep done before regression analysis. 
- `compute_weights`: Program that compute the stacked sample weights defined by Hollingsworth, Wing and Freedman. 
- `create_df_results`: Program that format the regression results into a data frame. 
- `pre_trends_ate_lincom_test`: Program that uses `lincom` to compute the pre-trends Wald test and computes the Average Treatment Effect (ATE) .
- `pre_trends_ate_lincom_test_fs`: Program that uses `lincom` to compute the pre-trends Wald test and computes the Average Treatment Effect (ATE) for the first stage analysis. 
- `stacked_did_models`: Program that estimates the stacked DiD models.
- `stacked_did_models_unweighted`: Variant for unweighted estimation.
- `stacked_did_models_weighted`: Variant for weighted estimation using stack/IPW weights.
- `stacked_did_models_fs_unweighted`: Variant for unweighted estimation for the first stage analysis.
- `stacked_did_models_fs_weighted`: Variant for weighted estimation using stack/IPW weights for the first stage analysis.

  
## Script: 1_StackedDID_Estimation.do

### Description

This Stata script estimates stacked Difference-in-Differences (DiD) models to evaluate how Airbnb listing behavior responds to local tax enforcement policies. The script uses both binary (treated vs. control) and continuous (magnitude of tax change) treatments, with models stratified by home rule status and weighted using combinations of stack weights and inverse probability weights (IPW). It performs the estimation separately for two key outcomes: reservation days (extensive margin) and the likelihood of being listed (intensive margin). The script runs sub-experiment–specific models as well as pooled regressions across all sub-experiments. Each estimation routine applies the appropriate DiD setup using previously prepared data and saves the resulting model outputs for downstream analysis.

### Inputs

- `${ai}/rcstackdid.dta`: Stacked DiD dataset for reservation days outcome.
- `${ai}/rcstackdid_rectangular.dta`: Rectangularized panel for listing outcomes.
- `final_prep_stacked`: User-defined program that prepares data before estimation.
- `stacked_did_models`: Program that estimates the DiD models.
- `stacked_did_models_unweighted`: Variant for unweighted estimation.
- `stacked_did_models_weighted`: Variant for weighted estimation using stack/IPW weights.

### Outputs

- `${ao}/stacked_did_models_results_binary.dta`: Reservation days model (binary treatment).
- `${ao}/stacked_did_models_results_continuous.dta`: Reservation days model (continuous treatment).
- `${ao}/stacked_did_models_listed_binary_subexp1.dta`: Listed model (binary, sub-exp 1).
- `${ao}/stacked_did_models_listed_binary_subexp2.dta`: Listed model (binary, sub-exp 2).
- `${ao}/stacked_did_models_listed_continuous_subexp1.dta`: Listed model (continuous, sub-exp 1).
- `${ao}/stacked_did_models_listed_continuous_subexp2.dta`: Listed model (continuous, sub-exp 2).
- `${ao}/stacked_did_models_listed_binary_unweighted.dta`: Full sample, binary model, unweighted.
- `${ao}/stacked_did_models_listed_binary_weighted_stack.dta`: Full sample, binary model, stack weights.
- `${ao}/stacked_did_models_listed_binary_weighted_stack_ipw.dta`: Full sample, binary model, stack × IPW.
- `${ao}/stacked_did_models_listed_continuous_unweighted.dta`: Full sample, continuous model, unweighted.
- `${ao}/stacked_did_models_listed_continuous_weighted_stack.dta`: Full sample, continuous model, stack weights.
- `${ao}/stacked_did_models_listed_continuous_weighted_stack_ipw.dta`: Full sample, continuous model, stack × IPW.

## Script: 2_FirstStageAnalysis.do

### Description

This Stata script estimates first-stage stacked Difference-in-Differences (DiD) models to examine the relationship between tax enforcement policies and the likelihood that an Airbnb property is listed. It evaluates both binary and continuous treatment definitions, using a variety of weighting schemes: unweighted, stack-weighted, and a combination of stack weights and inverse probability weights (IPW). The models are estimated using the full rectangularized panel of property-level data, and results are saved for later use in two-stage models and robustness checks.

### Inputs

- `${ai}/rcstackdid_rectangular.dta`: Rectangular Airbnb panel dataset with treatment status, event time, weights, and covariates.
- `final_prep_stacked`: External program to finalize dataset preparation.
- `stacked_did_models_fs_unweighted`: Program for first-stage unweighted model estimation.
- `stacked_did_models_fs_weighted`: Program for first-stage weighted model estimation (stack and/or IPW weights).

### Outputs

- `${ao}/stacked_did_models_fstage_listed_binary_unweighted.dta`: Binary treatment, unweighted model.
- `${ao}/stacked_did_models_fstage_listed_binary_weighted_stack.dta`: Binary treatment, stack weights only.
- `${ao}/stacked_did_models_fstage_listed_binary_weighted_stack_ipw.dta`: Binary treatment, stack × IPW weights.
- `${ao}/stacked_did_models_fstage_listed_continuous_unweighted.dta`: Continuous treatment, unweighted model.
- `${ao}/stacked_did_models_fstage_listed_continuous_weighted_stack.dta`: Continuous treatment, stack weights only.
- `${ao}/stacked_did_models_fstage_listed_continuous_weighted_stack_ipw.dta`: Continuous treatment, stack × IPW weights.

## Script: 3_Market_Level_Analysis.do

### Description

This Stata script performs stacked Difference-in-Differences (DiD) estimation using market-level data aggregated by ZIP code and city. It evaluates both binary and continuous treatment definitions to estimate the effects of tax enforcement policies on the share of listed Airbnb units (`listed_units`). The script applies several model specifications, including unweighted regressions, stack-weighted regressions, and regressions weighted by a combination of stack and inverse probability weights (IPW). It also conducts a first-stage analysis to isolate the effect of tax changes independently from interactions with local autonomy (Home Rule). An extended commented-out section includes exploratory triple difference analyses and synthetic DiD visualizations for robustness and event study dynamics.

### Inputs

- `${ai}/rcstackdid_mkt.dta`: Market-level panel dataset of Airbnb activity by ZIP code and city, with covariates, weights, and treatment timing.

### Outputs

- `${ao}/stacked_did_models_results_market_binary_unweighted.dta`
- `${ao}/stacked_did_models_results_market_binary_weighted_stack.dta`
- `${ao}/stacked_did_models_results_market_binary_weighted_stack_ipw.dta`
- `${ao}/stacked_did_models_results_market_continuous_unweighted.dta`
- `${ao}/stacked_did_models_results_market_continuous_weighted_stack.dta`
- `${ao}/stacked_did_models_results_market_continuous_weighted_stack_ipw.dta`
- `${ao}/stacked_did_models_fstage_market_binary_unweighted.dta`
- `${ao}/stacked_did_models_fstage_market_binary_weighted_stack.dta`
- `${ao}/stacked_did_models_fstage_market_binary_weighted_stack_ipw.dta`
- `${ao}/stacked_did_models_fstage_market_continuous_unweighted.dta`
- `${ao}/stacked_did_models_fstage_market_continuous_weighted_stack.dta`
- `${ao}/stacked_did_models_fstage_market_continuous_weighted_stack_ipw.dta`

## Script: 4_DescriptiveGraphs.R

### Description

This R script produces descriptive visualizations for the paper *"State vs Local Tax Enforcement Effectiveness: Evidence from Airbnb Price Data"*. It formats and exports time-series and event-study plots to illustrate the evolution of city-level sales tax rates, Airbnb listing behavior, and reservation patterns. The graphs compare trends across treatment groups (control vs. tax change) and Home Rule status (state vs. local enforcement). It uses cleaned and aggregated datasets, applying custom formatting functions to ensure a consistent aesthetic for publication-ready figures. All plots are saved as `.jpg` files for use in the paper or presentations.

### Inputs

- `ColoradoAllSalesTaxes.dta`: Sales tax data by city and home rule status.
- `taxrates_changes.dta`: Records of city tax rate changes and treatment dates.
- `rcstackdid.dta`: Airbnb-level panel dataset for event-time analysis of reservation behavior.
- `rcstackdid_rectangular.dta`: Rectangular stacked panel with listing probability and treatment flags.

### Outputs

- `taxratechanges_combined.jpg`: Side-by-side plot of sales tax rates over time and relative to tax changes.
- `graph_homerule_rates.jpg`: Tax rate trends by Home Rule status (mean and median).
- `stacked_dv_plot_comb.jpg`: Event-study plots of reservation days by treatment and Home Rule.
- `dv_listed_plot.jpg`: Event-study plot of listing probability by treatment, sub-experiment, and enforcement status.
- Summary tables of unique Airbnb IDs by sub-experiment and treatment group (printed, not saved).

### Functions or Programs Created

- `format_plot()`: Formats ggplot objects with standardized theme and color settings.
- `save_graph()`: Wrapper for saving plots in consistent dimensions and resolution.
