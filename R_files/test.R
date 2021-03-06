capture.output(source("shiny/R_files/datacheck.r"))

##DATACONCENATOR
#library(readxl)

#filepath= "C:/Users/AG_Winter/Desktop/20150706_MWM/20150706_Rosenmund_VGlut1-KO_MWM_training-1d"
#filepath="C:/Users/AG_Winter/Desktop/20150706_MWM/"
#END=".xls"
#NECESSARY="animal"

END=input$datatype
NECESSARY=input$necessary_text
NEVERTHERE="all"
Firstlinedata="Interval summary"
lastlinedata="Sum"

Filesname=list.files(path = filepath, pattern = NULL, all.files = FALSE,
                     full.names = FALSE, recursive = TRUE,
                     ignore.case = FALSE, include.dirs = FALSE, no.. = FALSE)




#datapath="Y:/AOCF-User Projects/1503_Vida_PV-GABAB-KO"
#specific = "/6. Data from Behavioral Tests/20150819_OF/RawData"

#filepath=paste(datapath,specific, sep="")
## get all file names in the folder
#Filesname= dir(filepath)


## chose only file ending with "xls"
substrRight <- function(x, n){
  substr(x, nchar(x)-n+1, nchar(x))
}
Filesname = Filesname[END == substrRight(Filesname, 4) ]
Filesname = Filesname[!grepl(NEVERTHERE,Filesname)]
#length(Filesname)
Filesname = Filesname[grepl(NECESSARY,Filesname)]
#Filesname = Filesname[grepl("animal13",Filesname)]

alldata=c()

for(i in c(1:length(Filesname))){
  print(i)
  filename= paste(filepath,"/", Filesname[i], sep="")
  #set metadata size
  testdata=t(readxl::read_excel(filename, sheet = 1, col_names =FALSE))
  Dstart=match(Firstlinedata , testdata[1,])
  
  # set data size
  Dend=match(lastlinedata , testdata[1,])
  Ldata=Dend-(Dstart+1)
  
  #get metadata:
  
  metadata=testdata[c(1,3),c(1:(Dstart-2))]
  addcolumns= as.data.frame(t(matrix(rep(metadata[2,],Ldata),Dstart-2,Ldata)))
  
  names(addcolumns)=gsub("\\:*","",metadata[1,])
  addcolumns=addcolumns[,-match("Date/Time",names(addcolumns))]
  
  
  #get animal ID, excluding the part after "." if it was entered as a number
  animal_ID=gsub("\\..*","",as.character(readxl::read_excel(filename, sheet = 1, col_names =FALSE)[7,3]))
  
  #get only the data, read again to get date format correctly
  data=readxl::read_excel(filename, sheet = 1, skip=(Dstart+1), col_names =FALSE)[1:Ldata,]
  #data=as.data.frame(t(testdata[,(Dstart+2):Dend]))
  
  # get right names
  zone=testdata[,Dstart]
  for (i in c(1:length(zone))){
    zone[i]=ifelse(is.na(zone[i]), zone[i-1], zone[i])
  }
  names(data)= paste(zone,testdata[,Dstart+1], sep= ":")
  
  
  
  ##put everything together and get out the empty row
  data2= cbind(addcolumns,data.frame("animalID"=rep(animal_ID,(Ldata)) ),data)[-(Ldata-1),]
  # add data to the sum row (date-time)
  data2[(Ldata-1),]= ifelse(is.na(data2[(Ldata-1),]), data2[(Ldata-2),],data2[(Ldata-1),])
  
  data2$`Interval summary:Time`=format(data2$`Interval summary:Time`, format="%H:%M:%S")
  data2$`Interval summary:Run time`=format(data2$`Interval summary:Run time`, format="%H:%M:%S")
  
  # debug if rbind is not working (add new columns with NAs to the small dataset)
  M=min(length(names(data2)),length(names(alldata)))
  L=ifelse(length(names(alldata))==0,0, length(names(data2))-length(names(alldata)))
  
  if (L>0 ){
    Nnames=names(merge(data2, alldata))
    alldata[,M+c(1:L)]=NA
    names(alldata)=Nnames
  }
  if (L<0 ){
    Nnames=names(merge(data2, alldata))
    data2[,M+c(1:(-L))]=NA
    names(data2)=Nnames
  }
  
  
  if(!all(names(data2)== names(alldata))){
    message("error")
    print(i)
  }  
  
  
  #concatenate
  alldata=rbind(alldata,data2)
  
}

concdata=alldata