library(dplyr)
library(openxlsx)

# Read in the data
# Report card 2022
# SK24 <- read.xlsx("C:\\Users\\jiang.shao\\Dropbox (UFL)\\MCO Report Card - 2024\\Program\\3. Survey\\Data\\Temp_Data\\SK24_out_rate.xlsx", sheet = 2)
# SK23 <- read.xlsx("C:\\Users\\jiang.shao\\Dropbox (UFL)\\3. Survey\\Data\\Temp_Data\\SK23_out.xlsx", sheet = 2)


# data 24
ST24 <- read.xlsx("C:\\Users\\jiang.shao\\Dropbox (UFL)\\MCO Report Card - 2024\\Program\\4. Complaint\\Data\\temp_data\\ST_for_analysis.xlsx", sheet = 2)
SP24 <- read.xlsx("C:\\Users\\jiang.shao\\Dropbox (UFL)\\MCO Report Card - 2024\\Program\\4. Complaint\\Data\\temp_data\\SP_for_analysis.xlsx", sheet = 2)
SK24 <- read.xlsx("C:\\Users\\jiang.shao\\Dropbox (UFL)\\MCO Report Card - 2024\\Program\\4. Complaint\\Data\\temp_data\\SK_for_analysis.xlsx", sheet = 2)

# data 23
ST23 <- read.xlsx("C:\\Users\\jiang.shao\\Dropbox (UFL)\\MCO Report Card - 2024\\Program\\4. Complaint\\Document\\Archive\\2023 Report Card Data\\ST_for_analysis.xlsx", sheet = 2)
SP23 <- read.xlsx("C:\\Users\\jiang.shao\\Dropbox (UFL)\\MCO Report Card - 2024\\Program\\4. Complaint\\Document\\Archive\\2023 Report Card Data\\SP_for_analysis.xlsx", sheet = 2)
SK23 <- read.xlsx("C:\\Users\\jiang.shao\\Dropbox (UFL)\\MCO Report Card - 2024\\Program\\4. Complaint\\Document\\Archive\\2023 Report Card Data\\SK_for_analysis.xlsx", sheet = 2)


# Process STAR
ST23 <- ST23 %>% select(-SAper10kmm_clust)
names(ST23) <- c('plancode', 'count', 'mm', 'count_pct', 'mm_pct', 'ae_ratio', 'score', 'center', 'rating')

ST24 <- ST24 %>% select(-MCONAME, -SERVICEAREA, -STper10kmm_clust)
names(ST24) <- c('plancode', 'count', 'mm', 'count_pct', 'mm_pct', 'ae_ratio', 'score', 'center', 'rating')


compare_datasets <- function(DF23, DF24, threshold) {

  merged_data <- merge(DF23, DF24, by = "plancode", suffixes = c("_23", "_24"), all = TRUE)

  diff_cols <- list()
  sig_cols <- list()

  for(colname in names(DF23)[-1]) {
    diff_colname <- paste0(colname, "_diff")
    diff_cols[[diff_colname]] <- merged_data[[paste0(colname, "_24")]] - merged_data[[paste0(colname, "_23")]]

    sig_colname <- paste0(colname, "_sig")
    sig_cols[[sig_colname]] <- ifelse(abs(diff_cols[[diff_colname]] / merged_data[[paste0(colname, "_23")]]) > threshold, "Yes", "No")
  }

  diff_sig_df <- data.frame(diff_cols, sig_cols)


  final_data <- cbind(merged_data["plancode"], merged_data[, -1], diff_sig_df)

  return(final_data)
}

ST_compare <- compare_datasets(ST23, ST24, threshold = 0.25)



# Process STAR+PLUS
SP23 <- SP23 %>% select(-SPper10kmm_clust)
names(SP23) <- c('plancode', 'count', 'mm', 'count_pct', 'mm_pct', 'ae_ratio', 'score', 'center', 'rating')

SP24 <- SP24 %>% select(-MCONAME, -SERVICEAREA, -SPper10kmm_clust)
names(SP24) <- c('plancode', 'count', 'mm', 'count_pct', 'mm_pct', 'ae_ratio', 'score', 'center', 'rating')

# SP24 <- SP24[!(SP24$plancode %in% c('P1', 'P2')), ]

SP_compare <- compare_datasets(SP23, SP24, threshold = 0.25)


# Process STAR Kids
SK23 <- SK23 %>% select(-SKper10kmm_clust)
names(SK23) <- c('plancode', 'count', 'mm', 'count_pct', 'mm_pct', 'ae_ratio', 'score', 'center', 'rating')

SK24 <- SK24 %>% select(-MCONAME, -SERVICEAREA, -SKper10kmm_clust)
names(SK24) <- c('plancode', 'count', 'mm', 'count_pct', 'mm_pct', 'ae_ratio', 'score', 'center', 'rating')

SK_compare <- compare_datasets(SK23, SK24, threshold = 0.25)


# ########################
write_dataframes_to_excel <- function(df_list, file_name) {
  wb <- createWorkbook()

  for (df_name in names(df_list)) {
    addWorksheet(wb, df_name)
    writeData(wb, sheet = df_name, x = df_list[[df_name]])
  }

  saveWorkbook(wb, file = file_name, overwrite = TRUE)
}

dataframes <- list(
  ST = ST_compare,
  SP = SP_compare,
  SK = SK_compare
)


write_dataframes_to_excel(dataframes, "C:\\Users\\jiang.shao\\Dropbox (UFL)\\MCO Report Card - 2024\\Program\\4. Complaint\\Output\\complaint_comparison_final.xlsx")

