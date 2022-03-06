library(rsortie)
head(VariableNames)
tail(VariableNames)
# to learn more about makeFiles
`?`(makeFiles)

# example of the local root pathway. In this case, all the
# files are within the Inputs directory:
# Change this to your root input directory
getwd()
loc_path <- paste0(getwd(), "/Example1/Inputs/")
# where are your base parameter files?
My_basePath <- paste0(loc_path, "ParameterFiles/BaseFiles/")
# where do you want to put newly created parameter files?
My_newxmlPath <- paste0(loc_path, "ParameterFiles/")
# where are the values that will substitute those in the
# base file?
My_newvalsPath <- paste0(loc_path, "ParameterValues/")
read.csv(paste0(loc_path, "FileLists/Init_ForestCarbon.csv"))
read.csv(paste0(My_newvalsPath, "FR01Inits.csv"))
read.csv(paste0(My_newvalsPath, "d.csv"))


library(data.table)
RunDetails <- fread(paste0(My_newvalsPath, "d.csv"))
RunDetails
# where do you want outputs? Update this to a valid
# directory on your computer
#getwd()
Output_path <- "C:\\Users\\erinc\\Documents\\SortieWorkshop2022\\Example1\\Outputs\\"
# must use double backslash not single if writing this in R

# Update Run details with new directory
RunDetails[V1 == "ShortOutput", `:=`(Interior_Spruce, Output_path)]
RunDetails[V1 == "Output", `:=`(Interior_Spruce, Output_path)]
# view the update
RunDetails
# write out as a csv for makefiles to access.
write.csv(RunDetails, paste0(My_newvalsPath, "d.csv"), row.names = FALSE)

MyFiles <- read.csv(paste0(loc_path, "FileLists/CopyOfInit_ForestCarbon.csv"))
makeFiles(lstFiles = MyFiles, path_basexmls = My_basePath, path_newxmls = My_newxmlPath,
          path_newvals = My_newvalsPath)

`?`(runSortie)
# ex - run the first new parameter file
runSortie(paste0(My_basePath, "SBS-01_FR01.xml"), sortie_loc = 0)  # Was My_newxmlPath AND "SBS-01-FR01Inits-d.xml" but I changed it to use my SORTIE GUI parameter file


#### Sortie Output ####

out_path <- "C:/Users/erinc/Documents/SortieWorkshop2022/Example1/Outputs/"
plotID <- c("FR01rsortie") #list the plots you ran
# Use ExtractFiles to untar the detailed output file
if (dir.exists(paste0(out_path, "extracted"))) {
  # if there's already an extracted folder, don't extract
  # files again
  ListofExtractedFiles <- paste0(out_path, "extracted/", list.files(paste0(out_path,
                                                                           "extracted")))
  ListofExtractedFiles <- grep(".gz", ListofExtractedFiles,
                               invert = TRUE, value = TRUE)
} else {
  # otherwise the function automatically creates it
  ListofExtractedFiles <- extractFiles(itype = 0, exname = out_path)
  ListofExtractedFiles <- grep(".gz", ListofExtractedFiles,
                               invert = TRUE, value = TRUE)
}
for (pl in 1:length(plotID)) {
  # get the file names > 0
  a <- grep(paste0("det_", "([0-9]+)"), grep(plotID[pl], ListofExtractedFiles,
                                             value = TRUE), value = TRUE)
  dt_table <- data.table()
  for (ix in 1:length(a)) {
    print(paste0("parsing: ", a[ix]))
    iy <- strsplit(a[ix], ".xml.gz")[[1]]
    t <- parseXML(a[ix])
    dt <- as.data.table(t)
    dt[, `:=`(timestep = as.numeric(strsplit(iy, "det_")[[1]][2]),
              plotID = plotID[pl])]
    dt_table <- rbind(dt_table, dt, fill = TRUE)
  }
  write.csv(dt_table, paste0(out_path, plotID[pl], "run_outputs.csv"))
}

#getwd()
out_path <- "C:/Users/erinc/Documents/SortieWorkshop2022/Example1/Outputs/GUIextract/"
plotID <- c("FR01rsortie","FR01")

###### IF READING IN OUTPUTS EXTRACTED IN SORTIE ########
#each year has it's own file if batch extract from SORTIE
out_names <- paste0("xy_SBS-01_",plotID,c("_det_"))  # need to change to whatever you added to the file name in the SORTIE GUI. ALSO my name wasn't the same b/c rSORTIE wouldn't work for me so I removed "Inits-d_det_"
out_DT <- data.table()
for(pl in 1:length(plotID)){
  PlID <- plotID[pl]
  yrs <- seq(0,4) #hard coded for 4 years
  for(i in 1:length(yrs)){
    dt <- fread(paste0(out_path,out_names[pl],yrs[i]), sep="\t",
                header=T,na.strings = "--", skip=1)
    dt[,':='(timestep = yrs[i],plotID = PlID)]
    #just keep 1ha of trees
    dt <- dt[X >50 & X <150 & Y>50 & Y <150]
    out_DT <- rbind(out_DT,dt,fill=TRUE)
  }
}
#############
#have a look at the data table
out_DT
tail(out_DT)

#### Example graphs from SORTIE output ####

source("C:/Users/erinc/Documents/SortieWorkshop2022/Example1/R/CarbonFunctions.R")
# Format data table to match biomass calculation code
out_DT <- out_DT[, `:=`(SO_sp, ifelse(Species == "Western_Larch",
                                      "Lw", ifelse(Species == "Douglas_Fir", "Fd", ifelse(Species ==
                                                                                            "Subalpine_Fir", "Bl", ifelse(Species == "Interior_Spruce",
                                                                                                                          "Sx", ifelse(Species == "Lodgepole_Pine", "Pl", ifelse(Species ==
                                                                                                                                                                                   "Trembling_Aspen", "At", ifelse(Species == "Black_Cottonwood",
                                                                                                                                                                                                                   "Ac", ifelse(Species == "Paper_Birch", "Ep", Species)))))))))]
# Format and just keep live trees
out_DT[, `:=`(Tree_class, ifelse(Type == "Seedling" | Type ==
                                   "Sapling" | Type == "Adult", "L", "D"))]
Trees_SO <- out_DT[!is.na(DBH) & Height > 1.3 | !is.na(DBH) &
                     is.na(Height)]
Trees_SO[, `:=`(Tree_class, ifelse(Tree_class == "L", 2, 4))]
# Calculate carbon in live trees by timestep and plot ID
g <- vector()
for (i in 1:nrow(Trees_SO)) {
  g[i] <- TreeCarbonFN(Species = Trees_SO[i, SO_sp], DBH = Trees_SO[i,
                                                                    DBH], HT = Trees_SO[i, Height], Tree_class = Trees_SO[i,
                                                                                                                          Tree_class])
}
#xkg/(100x100m) = xkg/1ha * 1Mg/1000kg = x Mg/1000
Trees_SO[, `:=`(CarbonPerHa, g/1000)]
Trees_SO_live <- Trees_SO[!is.na(CarbonPerHa)]
FR_Sor_trees <- Trees_SO_live[, .(LiveCperHa = sum(CarbonPerHa)),
                              by = c("plotID", "timestep")]
# Graph the trends over time in carbon from SORTIE
library(ggplot2)
ggplot(FR_Sor_trees, aes(x = timestep, y = LiveCperHa, colour = plotID)) +
  geom_point() + theme_minimal() + ylab(expression("Carbon Mg/ha")) +
  xlab("Time since fire") + ylim(0, 200) + theme(strip.text.x = element_text(face = "bold"))
