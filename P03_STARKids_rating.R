## Run this file in R.
## You may need to install packages: cluster, data.table, tidyverse, openxlsx.


## Define the custom functions.
source("V:/STATE CONTRACTS/TX_EQRO/HOP_TX/TexasReports/Contract_Deliverables/Member_Surveys/Survey Tools/Syntax/Excel macros/MCO Report Cards/kmeans_optimum.r")
source("C:/Users/jiang.shao/Dropbox (UFL)/MCO Report Card - 2024/Program/2. Admin/Program/Function/PercentileAdjust.R")

## Read in source file
outdir <- "C:/Users/jiang.shao/Dropbox (UFL)/MCO Report Card - 2024/Program/4. Complaint/Data/temp_data"
infile <- paste(outdir, "SK_for_analysis.xlsx", sep = "/")
complaints_wb <- loadWorkbook(infile)

SK24_complaints <- read.xlsx(complaints_wb, sheet="SK_for_analysis")

# ##this is not a denominator, should not set low count threshold for it
# SK24_complaints$SKper10kmm[which(SK24_complaints$Count < 30)] <- NA


## Calculate clusters
names(SK24_complaints)[names(SK24_complaints) == "PHI_Plan_Code"] <- "plancode"
complaints_wb <- kmeans_opt(SK24_complaints, outwb = complaints_wb, descr = "SK24_complaints", varlist = "SKper10kmm")


## convert clusters to ratings
SK24_complaints <- read.xlsx(complaints_wb, sheet="SK24_complaints")
SK24_complaints <- PercentileAdjust(SK24_complaints, "SKper10kmm", higher_better = FALSE)


## Output table with input data plus clusters, centers, and ratings
writeData(wb = complaints_wb, sheet = "SK24_complaints", x = SK24_complaints)
saveWorkbook(complaints_wb, infile, overwrite = TRUE)

