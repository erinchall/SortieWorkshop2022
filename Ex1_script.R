library(rsortie)
library(data.table)
getwd()
loc_path <- file.path(getwd(), "Example1")

My_basePath <- paste0(loc_path,"/Inputs/","ParameterFiles/BaseFiles/")
My_newxmlPath <- paste0(loc_path,"/Inputs/","ParameterFiles/")
My_newvalsPath <- paste0(loc_path,"/Inputs/","ParameterValues/")

read.csv(file.path(loc_path, "Inputs", "FileLists", "InitClearCut.csv"))
read.csv(paste0(My_newvalsPath,"A1.csv"))
RunDetails <- fread(paste0(My_newvalsPath,"p.csv"))
RunDetails
# getwd()
Output_path <- "C:\\Users\\erinc\\Documents\\6. SORTIE and R\\Sortie Workshop - BVRC March 2022\\Test Example\\SORTIEworkshopFiles\\SortieWorkshop2022\\Example1\\Outputs\\"
RunDetails[V1=="ShortOutput", Western_Hemlock:= Output_path]
RunDetails[V1=="Output", Western_Hemlock:= Output_path]
#view the update
RunDetails
#write out as a csv for makefiles to access.
write.csv(RunDetails, paste0(My_newvalsPath,"p.csv"), row.names = FALSE)

MyFiles <- read.csv(paste0(loc_path,"/Inputs/FileLists/InitClearCut.csv"))
makeFiles(lstFiles = MyFiles, path_basexmls = My_basePath,
          path_newxmls = My_newxmlPath, path_newvals= My_newvalsPath)
