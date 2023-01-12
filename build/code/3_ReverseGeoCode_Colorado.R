library(tibble)
library(tidygeocoder)
library(dplyr)
library(foreign)
library(readstata13)
library(tictoc)
### Tidy Geocoder
### Code source: https://cran.r-project.org/web/packages/tidygeocoder/readme/README.html

#path<-"C:\\Users\\justross\\OneDrive - Indiana University\\Ross_Luis\\COVID19 PBF\\"
#path <-"C:/Users/luise/Indiana University/Ross, Justin - Ross_Luis/AirBNB/Data/ColoradoGeoCode"
path <- "/N/slate/lunavarr/AirbnbColorado/build/temp/geocode"

# Define the data and results path
input<-paste(path,"/Input",sep = "")
output<-paste(path,"/Output",sep = "") 

x <- c(1:34)
InputNames <- character(length(x))
OutputNames <- character(length(x))

for(i in x){

  InputNames[i] <- paste0("/Property_Above1000_", i, ".dta")
  OutputNames[i] <- paste0("/ReverseGeoCode/ColoradoReverse_", i, ".csv") 
  filename <- paste0(input,InputNames[i])
  results <- paste0(output,OutputNames[i])
  tic(InputNames[i])
  Colorado <- read.dta13(filename)
  subsetColorado <- data.frame(Colorado$propertyid, Colorado$latitude, Colorado$longitude)
  names(subsetColorado) <- c("propertyid","latitude","longitude")
  revgeo_colorado <- subsetColorado %>%
    reverse_geocode(lat = latitude, long = longitude, method = 'osm',
                    address = address_found, full_results = TRUE) %>%
    select(-licence, -boundingbox)
  write.csv(revgeo_colorado, file = results, sep = ";", na = "NA")
  toc()
}


#####################################
Colorado <- read.dta13(filename)

subsetColorado <- data.frame(Colorado$propertyid, Colorado$latitude, Colorado$longitude)
names(subsetColorado) <- c("propertyid","latitude","longitude")

sam_sub <- subsetColorado[1:10,]

revgeo_colorado <- sam_sub %>%
  reverse_geocode(lat = latitude, long = longitude, method = 'osm',
                  address = address_found, full_results = TRUE) %>%
  select(-licence, -boundingbox)

write.csv(revgeo_colorado, file = results, sep = ";", na = "NA")
