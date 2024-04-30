## Run this file in R.
## You may need to install packages: cluster, data.table, tidyverse, openxlsx.


## Define the custom functions.
source("V:/STATE CONTRACTS/TX_EQRO/HOP_TX/TexasReports/Contract_Deliverables/Member_Surveys/Survey Tools/Syntax/Excel macros/MCO Report Cards/kmeans_optimum.r")
source("C:/Users/jiang.shao/Dropbox (UFL)/MCO Report Card - 2024/Program/2. Admin/Program/Function/PercentileAdjust.R")

## Read in source file
outdir <- "C:/Users/jiang.shao/Dropbox (UFL)/MCO Report Card - 2024/Program/4. Complaint/Data/temp_data"
infile <- paste(outdir, "ST_for_analysis.xlsx", sep = "/")
complaints_wb <- loadWorkbook(infile)

ST24_complaints <- read.xlsx(complaints_wb, sheet="ST_for_analysis")

# ##this is not a denominator, should not set low count threshold for it
# ST24_complaints$STper10kmm[which(ST24_complaints$Count < )] <- NA


## Calculate clusters
names(ST24_complaints)[names(ST24_complaints) == "PHI_Plan_Code"] <- "plancode"

complaints_wb <- kmeans_opt(ST24_complaints, outwb = complaints_wb, descr = "ST24_complaints", varlist = "STper10kmm")

## convert clusters to ratings
ST24_complaints <- read.xlsx(complaints_wb, sheet="ST24_complaints")
ST24_complaints <- PercentileAdjust(ST24_complaints, "STper10kmm", higher_better = FALSE)


## Output table with input data plus clusters, centers, and ratings
writeData(wb = complaints_wb, sheet = "ST24_complaints", x = ST24_complaints)
saveWorkbook(complaints_wb, infile, overwrite = TRUE)

