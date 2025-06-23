---
title:  "Replication Package – State vs. Local Tax Enforcement Effectiveness"
author: Luis Navarro
date: "June 2025"
#output: github_document
---

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

### Functions or Programs Created
- None. The script uses standard Stata commands (`shp2dta`, `geoinpoly`, `egen`, etc.) and does not define custom programs or functions.


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

### Functions or Programs Created
- None. The script uses standard Stata commands (`egen`, `seq()`, `strtrim`, `tab`, etc.) and global macros. No custom functions or procedures are defined.

## Script: 3_ReverseGeoCode_Colorado.R

### Description
This R script performs reverse geocoding on Airbnb property listings located in Colorado cities with more than 1,000 listings, using latitude and longitude coordinates to retrieve standardized location data (such as city and administrative areas). It uses the `tidygeocoder` package with the OpenStreetMap (OSM) geocoding service. The script loops through 34 Stata `.dta` files containing batches of approximately 2,500 observations each (prepared in the previous Stata script), extracts the geographic coordinates and property IDs, and performs reverse geocoding. The results are saved as `.csv` files for later merging with the original dataset. A sample run on 10 observations is included at the end of the script for testing and debugging.

### Inputs
- `Property_Above1000_1.dta` to `Property_Above1000_34.dta`: Stata files containing Airbnb property listings with coordinates requiring geocoding (output from Script #2).

### Outputs
- `ColoradoReverse_1.csv` to `ColoradoReverse_34.csv`: Reverse-geocoded property datasets saved as `.csv` files containing address information retrieved via OpenStreetMap.

### Functions or Programs Created
- None. The script uses standard R packages and functions from:
  - `tidygeocoder` – for reverse geocoding.
  - `readstata13` and `rio` – for reading Stata `.dta` files.
  - `tibble`, `dplyr`, `tictoc` – for data handling and runtime tracking.
