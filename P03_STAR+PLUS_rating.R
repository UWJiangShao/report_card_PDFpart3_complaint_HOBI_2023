## Run this file in R.
## You may need to install packages: cluster, data.table, tidyverse, openxlsx.


## Define the custom functions.
source("V:/STATE CONTRACTS/TX_EQRO/HOP_TX/TexasReports/Contract_Deliverables/Member_Surveys/Survey Tools/Syntax/Excel macros/MCO Report Cards/kmeans_optimum.r")
source("C:/Users/jiang.shao/Dropbox (UFL)/MCO Report Card - 2024/Program/2. Admin/Program/Function/PercentileAdjust.R")

## Read in source file
outdir <- "C:/Users/jiang.shao/Dropbox (UFL)/MCO Report Card - 2024/Program/4. Complaint/Data/temp_data"
infile <- paste(outdir, "SP_for_analysis.xlsx", sep = "/")
complaints_wb <- loadWorkbook(infile)

SP24_complaints <- read.xlsx(complaints_wb, sheet="SP_for_analysis")

# ##this is not a denominator, should not set low count threshold for it
# SP24_complaints$SPper10kmm[which(SP24_complaints$Count < 30)] <- NA


## Calculate clusters
names(SP24_complaints)[names(SP24_complaints) == "PHI_Plan_Code"] <- "plancode"
complaints_wb <- kmeans_opt(SP24_complaints, outwb = complaints_wb, descr = "SP24_complaints", varlist = "SPper10kmm")


## convert clusters to ratings
SP24_complaints <- read.xlsx(complaints_wb, sheet="SP24_complaints")
SP24_complaints <- PercentileAdjust(SP24_complaints, "SPper10kmm", higher_better = FALSE)


## Output table with input data plus clusters, centers, and ratings
writeData(wb = complaints_wb, sheet = "SP24_complaints", x = SP24_complaints)
saveWorkbook(complaints_wb, infile, overwrite = TRUE)

