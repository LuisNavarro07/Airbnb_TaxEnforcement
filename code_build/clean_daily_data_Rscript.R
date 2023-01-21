### Airbnb Clean Daily Data 

rm(list = ls()) 
library(tidyverse)
library(readr)
library(kableExtra)
library(plyr)

path <- "/N/slate/lunavarr/AirbnbColorado/"
bi <- paste(path,"build/input/", sep="" ) 
btd <- paste(path,"build/temp/daily/", sep="" ) 
btdf <- paste(path,"build/temp/daily/full/", sep="" )

prop_name <- "us_Property_Match_2020-02-11.csv"
prop_file <-paste(bi,prop_name, sep="" )
property_data <- read.csv(prop_file, header=TRUE, sep=",")


daily_file5 <- read.csv(paste(btd,"airbnbdaily_p5.csv", sep="" ), header=TRUE, sep=" ")



daily_file1 <- read.csv(paste(btd,"airbnbdaily_p1.csv", sep="" ), header=TRUE, sep=" ")


clean_daily <- function(file){
  file 
}
