GHCN climate data
-----------------

The Global Historical Climatology Network (GHCN) has daily weather data from 75,000 weather stations in 180 countries and territories (see <https://www.ncdc.noaa.gov/oa/climate/ghcn-daily/>). The data are in text files with ".dly" extension. Unfortunately, .dly files are written in an arcane format that is extremely difficult to use. Several tools exist to download and view data, for example:

-   The R package FedData described at <http://zevross.com/blog/2016/03/15/using-the-new-r-package-feddata-to-access-federal-open-datasets-including-interactive-graphics/>;
-   The Matlab script at <http://gce-lter.marsci.uga.edu/public/im/tools/toolbox_download.htm>;
-   A Python/Jupyter notebook/PostgreSQL script at <https://github.com/dylburger/noaa-ghcn-weather-data>.

However, FedData seems to drop the measurement, quality and source flags, and the data are still in a somewhat awkward format. I don't own Matlab, and I was unable to get the Python script to work due to an installation problem with missing libraries in a Python virtual environment.

By contrast, this R function is very simple (and R is free). You pass it the name of a .dly file, it parses the file and loads it into a regular R dataframe that retains all of the original information and can easily be saved as a .csv file. The function is designed for a single file, but it would be trivial to automate it to process a batch of files.

Note: you should have the R library "reshape2" installed (it is a popular library for manipulating dataframes).

Finding weather stations and downloading files:
-----------------------------------------------

Download the list of GHCN stations from <ftp://ftp.ncdc.noaa.gov/pub/data/ghcn/daily/ghcnd-stations.txt>. Then read the list into R, select stations in your area of interest, and download them. This method is dead simple and there are much slicker alternatives, but it's not hard to use and you can see exactly what is happening. The FedData library has a more sophisticated version that allows you to choose years, variables and extent, but it missed some stations when I gave it a bounding box.)

``` r
#The schema of the station data, from readme.txt.  
station_schema <- read.table(text = 
  "ID           1-11   Character
  LATITUDE     13-20   Real
  LONGITUDE    22-30   Real
  ELEVATION    32-37   Real
  STATE        39-40   Character
  NAME         42-71   Character
  GSNFLAG      73-75   Character
  HCNFLAG      77-79   Character
  WMOID        81-85   Character", 
  header = FALSE, stringsAsFactors = FALSE)

#Read in the GHCN list of stations from It's big (100,000 lines).
stations<-read.fwf('ghcnd-stations.txt',
                widths = c(11,9,10,7,3,31,4,4,6),stringsAsFactors=F,
                strip.white=TRUE,comment.char="",col.names = tolower(station_schema$V1))

#Find the stations within a bounding box (alternatively could use the 'sp' package to make this spatial, overlay polygons, etc.).
studyarea_stations<-stations[stations$latitude > 41.44 & stations$latitude < 45.97453 & stations$longitude > 104.3587 & stations$longitude < 111.9546,]
#Get the station ids
id_list<-studyarea_stations$id

#Download the files
library(RCurl)
source("get_ghcn.R") #load the function (add filepath if necessary)
FTP<-"ftp://ftp.ncdc.noaa.gov/pub/data/ghcn/daily/all/"
get_ghcn(FTP,id_list) #will put them in your working directory
```

Convert a GHCN daily climate file to a useable .csv file
--------------------------------------------------------

Let's assume that you have downloaded a file called "MBM00044354.dly" from the daily FTP directory (either /all or /by\_year) into your working directory. The file contains all weather records for the station. Now use the function to convert the data to a reasonable format.

``` r
source("parse_GHCN_data.R") #load the function (add filepath if necessary)
#Parse the file
fname<-'MGM00044354.dly' 
df<-parse_GHCN_data(fname)
#Write out the dataframe as a csv file
write.csv(df,"MGM00044354.csv",row.names=FALSE,na="")
```

That's all there is to it. The main variables are:

-   PRCP = Precipitation (tenths of mm)
-   SNOW = Snowfall(mm)
-   SNWD = Snow depth (mm)
-   TMAX = Maximum temperature (tenths of degrees C)
-   TMIN = Minimum temperature (tenths of degrees C)

but data from some weather stations include many other variables. See GHCN readme for more information, at <ftp://ftp.ncdc.noaa.gov/pub/data/ghcn/daily/readme.txt>. If you're only interested in one variable, just use regular R subsetting to get it: `{r, eval=FALSE}rain<-df[df$variable=="PRCP",]` but it's kind of nice having the variables together in the right format so that you can plot them against each other.
