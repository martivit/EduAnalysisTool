# Load packages -----------------------------------------------------------
library(impactR.utils)
library(humind)
library(presentresults)
library(analysistools)

# Needed tidyverse packages
library(dplyr)
library(readxl)
library(openxlsx)
library(tidyr)
library(stringr)
library(ggplot2)
library(srvyr)
library(gt)

source("src/functions/00_edu_helper.R")
source("src/functions/00_edu_function.R")
source("src/functions/create_education_table_group_x_var.R")
source("src/functions/create_education_xlsx_table.R")
source("src/functions/helpers_x-crisis.R")

# Temporary workaround for a humind column-overwrite issue; see the file's own
# header for what it does and how to remove it once humind ships a fix. Sourced
# conditionally so deleting the file (as part of that cleanup) needs no other change here.
if (file.exists("src/functions/00_safe_add_functions.R")) {
  source("src/functions/00_safe_add_functions.R")
}

## --------------------------
country_assessment = 'AFG' # Add here the 3 leter country code that will be the same in all the files and referecnes

##---------------- READING INFO AND VARIABLES FROM  matadata.xlsx
source("src/00-getting-info-country.R")

# Unpacks list_info_general/list_variables (from 00-getting-info-country.R) into
# the named variables the pipeline scripts use, builds derived paths/labels, and
# reads the ISCED info, LOA, and data helper tables. See src/00-setup-variables.R.
source("src/00-setup-variables.R")

##################################################################################################

# All outputs for this run are written under output/<country_assessment>/, created here so
# every downstream write below (and the matching reads that follow it) can assume it exists.
output_dir <- paste0("output/", country_assessment)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(paste0(output_dir, "/rds_results"), recursive = TRUE, showWarnings = FALSE)
dir.create(paste0(output_dir, "/plots_", country_assessment), recursive = TRUE, showWarnings = FALSE)
dir.create(paste0(output_dir, "/table_for_maps"), recursive = TRUE, showWarnings = FALSE)

# 1 ----------------- 01-add_education_indicators.R -----------------
main_sheet <- label_main_sheet ## Used in 01-add_education_indicators.R
loop_sheet <- label_edu_sheet ## Used in 01-add_education_indicators.R

source("src/01-add_education_indicators.R") ## OUTPUT: output/<country_assessment>/loop_edu_recorded_<country_assessment>.xlsx

source("src/01-5-creating_loa.R") ## OUTPUT: input_tool/03_loa/loa_analysis_<country_assessment>.csv

# 2 ----------------- 02-education_analysis.R -----------------
source("src/02-education_analysis.R") ## OUTPUT: output/<country_assessment>/grouped_other_education_results_loop_<country_assessment>.RDS

# 3 ----------------- 03-education_labeling.R -----------------
source("src/03-education_labeling.R")  ## OUTPUT: output/<country_assessment>/labeled_results_table_<country_assessment>.RDS  ---- df: education_results_table_labelled

# 4 ----------------- create workbook for tables -----------------
education_results_table_labelled <- readRDS(paste0(output_dir, "/labeled_results_table_",country_assessment,".RDS"))

wb <- openxlsx::createWorkbook("education_results")
addWorksheet(wb, "Table_of_content")
writeData(wb, sheet = "Table_of_content", x = "Table of Content", startCol = 1, startRow = 1)

row_number_lookup <- c(
  "access" = 2,
  "overaged" = 3,
  "out_of_school" = 4,
  "ece" = 5,
  "level1" = 6,
  "level2" = 7,
  "level3" = 8,
  "level4" = 9,
  "non_formal" = 10, 
  "wgq" = 11
)
loa_country <- read.csv(paste0("input_tool/03_loa/loa_analysis_", country_assessment,".csv"))

# 5 ----------------- 04-01-make-table-access-disruptions.R -----------------
# To repeat according to the number of tabs in the data_helper
tab_helper <- "access"
source("src/04-01-make-table-access-overaged-barriers.R")

tab_helper <- "overaged"
source("src/04-01-make-table-access-overaged-barriers.R")

## IMPORTANT: open grouped_other_education_results_loop and copy the first (in decreasing order) 5 edu_barrier_d results in the edu_indicator_labelling_FR/EN.xlsx.
tab_helper <- "out_of_school"
source("src/04-01-make-table-access-overaged-barriers.R")

  # 5 ----------------- 04-02-make-level-table.R -----------------
# To repeat according to the number of levels in the country's school system
tab_helper <- "ece"
source("src/04-02-make-level-table.R")

tab_helper <- "level1"
source("src/04-02-make-level-table.R")

tab_helper <- "level2"
source("src/04-02-make-level-table.R")

tab_helper <- "level3"
source("src/04-02-make-level-table.R")

tab_helper <- "non_formal"
source("src/04-01-make-table-access-overaged-barriers.R")



openxlsx::saveWorkbook(wb, paste0(output_dir, "/education_results_",country_assessment, ".xlsx"), overwrite = T)
openxlsx::openXL(paste0(output_dir, "/education_results_",country_assessment,".xlsx"))

# 6 ----------------- 05-01-make-level-table.R -----------------
# To repeat according to the number of tabs in the data_helper
tab_helper <- "access"
results_filtered <- paste0(output_dir, "/rds_results/access_results_", country_assessment, ".rds")
source("src/05-01-make-graphs-and-maps-tables.R")

tab_helper <- "overaged"
results_filtered <- paste0(output_dir, "/rds_results/overaged_results_", country_assessment, ".rds")
source("src/05-01-make-graphs-and-maps-tables.R")

tab_helper <- "out_of_school"
results_filtered <- paste0(output_dir, "/rds_results/out_of_school_results_", country_assessment, ".rds")
source("src/05-01-make-graphs-and-maps-tables.R")

tab_helper <- "ece"
results_filtered <- paste0(output_dir, "/rds_results/ece_results_", country_assessment, ".rds")
source("src/05-01-make-graphs-and-maps-tables.R")

tab_helper <- "level1"
results_filtered <- paste0(output_dir, "/rds_results/level1_results_", country_assessment, ".rds")
source("src/05-01-make-graphs-and-maps-tables.R")

tab_helper <- "level2"
results_filtered <- paste0(output_dir, "/rds_results/level2_results_", country_assessment, ".rds")
source("src/05-01-make-graphs-and-maps-tables.R")

tab_helper <- "level3"
results_filtered <- paste0(output_dir, "/rds_results/level3_results_", country_assessment, ".rds")
source("src/05-01-make-graphs-and-maps-tables.R")

