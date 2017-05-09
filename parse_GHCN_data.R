parse_GHCN_data<-function(dly_file){
  #This function converts GHCN 'daily' data files to an R dataframe by reshaping
  #the data from 128 columns into 10. It retains all variables (temp, rain,
  #precip, etc.) as well as all measurement, source and quality flags.
  library(reshape2)
  
  #NOTE: factors would create big problems with melting
  raw<-read.fwf(dly_file,widths = c(11, 4, 2, 4, rep(c(5, 1, 1, 1),31)),stringsAsFactors=FALSE)
  
  #Make a list of the columns
  vals<-paste0("V",seq(5,128,4)) #values
  mflag<-paste0("V",seq(6,128,4)) #measurement flag
  qflag<-paste0("V",seq(7,128,4)) #quality flag
  sflag<-paste0("V",seq(8,128,4)) #source flag
  
  #Split the columns into values and flags (all are grouped by four)
  a<-raw[,c(1:4,which(names(raw) %in% vals))] #Keep only the values and discard all of the error flags
  mf<-raw[,c(1:4,which(names(raw) %in% mflag))]#The mflags (also indexed by station,year,month)
  qf<-raw[,c(1:4,which(names(raw) %in% qflag))]#qflags
  sf<-raw[,c(1:4,which(names(raw) %in% sflag))]#sflags
  
  #In each case, save the first 4 index columns, convert the "variable" to days by 
  #melting and then matching to the column list
  a1<-melt(a,id=c(1:4))
  a1$day<-match(a1$variable,vals) #Convert the column name to a day by matching its position with the list
  a1<-a1[,-which(names(a1)=="variable")] #drop the variable column
  names(a1)<-c("station","year","month","variable","value","day")
  
  mf1<-melt(mf,id=c(1:4)) 
  mf1$day<-match(mf1$variable,mflag) 
  mf1<-mf1[,-which(names(mf1)=="variable")] 
  names(mf1)<-c("station","year","month","variable","mflag","day")
  
  qf1<-melt(qf,id=c(1:4)) 
  qf1$day<-match(qf1$variable,qflag) 
  qf1<-qf1[,-which(names(qf1)=="variable")] 
  names(qf1)<-c("station","year","month","variable","qflag","day")
  
  sf1<-melt(sf,id=c(1:4)) 
  sf1$day<-match(sf1$variable,sflag) 
  sf1<-sf1[,-which(names(sf1)=="variable")] 
  names(sf1)<-c("station","year","month","variable","sflag","day")
  
  #Merge them into one dataframe
  am<-merge(a1,mf1,by=c("station","year","month","variable","day"),all=TRUE)
  amq<-merge(am,qf1,by=c("station","year","month","variable","day"),all=TRUE)
  db<-merge(amq,sf1,by=c("station","year","month","variable","day"),all=TRUE)
  
  #Add a date (time zone is UTC by default)
  db$date<-as.Date(paste(db$year,db$month,db$day,sep="-"),format="%Y-%m-%d")
  
  #Discard bad dates (in the original raw format, all months had 31 days)
  db<-db[!is.na(db$date),]
  
  #Turn the -9999's and spaces into NAs 
  #(note: blanks in the flag fields actually convey information --see GHCN readme)
  db[db==-9999]<-NA
  
  #Sort by date, then variable (could also turn flags into factors now if desired)
  db<-db[order(db$date,db$variable),]
  
  return(db)
}
