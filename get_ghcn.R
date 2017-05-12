get_ghcn<-function(FTP,ghcnlist){
  if (length(ghcnlist) > 0) {
    n.downloaded<-0
    for (ghcnName in ghcnlist) {
      er <- 0
      class(er) <- "try-error"
      ce <- 0
      starttrying<-Sys.time()
      while(class(er) == "try-error") {
        theurl<-paste0(FTP,ghcnName,".dly")
        print(paste("Trying URL:",theurl))
        if(url.exists(theurl)) {
          curl<-getCurlHandle()
          er<-try(getBinaryURL(url=theurl,curl=curl),silent=FALSE)
          rm(curl)  # release the curl!
          gc() #garbage collection, to force it to remove the curl
          #Original:
          #er <- try( download.file(url=theurl),destfile=ghcnName,mode='wb',quiet=T, cacheOK=FALSE),silent=TRUE)
        } else print(paste("URL does not exist:",theurl))
        if (class(er) == "try-error") {
          Sys.sleep(30)
          ce <- ce + 1
          mins<-as.numeric(Sys.time() - starttrying) %/% 60 #the modulus
          secs<-as.integer(as.numeric(Sys.time() - starttrying)) %% 60 #the remainder
          print(paste("Try: ",ce,"; Elapsed time:",mins,":",secs,sep=""))
          if (ce == 42) stop("The FTP server is not responding. Please try again later.") #stop after 21 minutes
        } else{
          ## write to file
          outfile = file ( paste0(getwd(),"/",ghcnName,".dly"), open="wb")
          writeBin(object = er, con = outfile ) 
          close(outfile)
          print(paste(ghcnName,"successfully downloaded."))
          n.downloaded<-n.downloaded + 1
        }#ok: write to file
      }#while still trying
    }# for ghcnName in ghcnlist
    print(paste(n.downloaded,"files successfully downloaded."))
  } #if length(ghcnlist) > 0
}#function get_ghcn
