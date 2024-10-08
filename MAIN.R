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

## --------------------------
country_assessment = 'HTI'
language_assessment = 'French'

## --------------- File paths
#-- input data
path_ISCED_file <- 'resources/UNESCO ISCED Mappings_MSNAcountries_consolidated.xlsx'
data_file <- 'input_data/HTI2401-MSNA-DEPARTEMENTS-Clean-dataset.xlsx'
label_main_sheet <-'Clean Data'
label_edu_sheet <- 'ind_loop'

kobo_path <- "input_data/HTI_kobo.xlsx"
label_survey_sheet <-'survey'
label_choices_sheet <- 'choices'
kobo_language_label <- "label::french"

#-- input tool
# please modify the group_var according to your context

loa_path = "input_tool/edu_analysistools_loa.xlsx"

suffix <- ifelse(language_assessment == "French", "_FR", "_EN")
data_helper_table <- paste0("input_tool/edu_table_helper", suffix, ".xlsx")

labelling_tool_path <- "input_tool/edu_indicator_labelling.xlsx"

## -------------  definition of variable according to the analysis' context
id_col_loop = '_submission__uuid.x' # uuid
id_col_main = '_uuid' # uuid
survey_start_date = 'start'# column with the survey start
school_year_start_month = 9 # start school year in country
ind_age = 'ind_age' # individual age variable
ind_gender = 'ind_gender' # individual gender variable
pnta = "pnta"
dnk = "dnk"
weight_col <- "weights"

# indicators
ind_access <- "edu_access"
occupation <- "edu_disrupted_occupation"
hazards <- "edu_disrupted_hazards"
displaced <- "edu_disrupted_displaced"
teacher <- "edu_disrupted_teacher"
education_level_grade <- "edu_level_grade"
barrier = "edu_barrier"
number_displayed_barrier <- 5

# strata --> check consistency with the group_var column  in the loa
add_col1 = 'setting'
admin1 <- "admin1"
admin2 <- "admin2"
admin3 <- "admin3"
# stratum =

label_overall <- if (language_assessment == "French") "Ensemble" else "Overall"
label_female <- if (language_assessment == "French") "Filles" else "Girls"
label_male <- if (language_assessment == "French") "Garcons" else "Boys"
label_edu_school_cycle <- if (language_assessment == "French") "Cycle Scolaire Assigné par Âge" else "Age-Assigned School Cycle"

# Read ISCED info
info_country_school_structure <- read_ISCED_info(country_assessment, path_ISCED_file)
summary_info_school <- info_country_school_structure$summary_info_school

labels_with_ages <- summary_info_school %>%
  rowwise() %>%
  mutate(label = extract_label_for_level_ordering(summary_info_school, cur_data(), language_assessment)) %>%
  pull(label)

# Read the loa
loa <- readxl::read_excel(loa_path, sheet = "Sheet1")

# Read data helper and process it
data_helper_sheets <- readxl::excel_sheets(data_helper_table)
data_helper <- data_helper_sheets %>%
  map(~ read_excel(data_helper_table, sheet = .x)) |>
  set_names(data_helper_sheets)
data_helper <- data_helper |>
  map(~ .x |>
    as.list() %>%
    map(na.omit) %>%
    map(c))

##################################################################################################

# 1 ----------------- 01-add_education_indicators.R -----------------
main_sheet <- label_main_sheet
loop_sheet <- label_edu_sheet
stratum <- NULL
additional_stratum <- NULL
add_col2 <- NULL
add_col3 <- NULL
add_col4 <- NULL
add_col5 <- NULL
add_col6 <- NULL
add_col7 <- NULL
add_col8 <- NULL
source('src/01-add_education_indicators.R') ## OUTPUT: output/loop_edu_recorded.xlsx

# 2 ----------------- 02-education_analysis.R -----------------
source('src/02-education_analysis.R') ## OUTPUT: output/grouped_other_education_results_loop.RDS

# 3 ----------------- 03-education_labeling.R -----------------
source('src/03-education_labeling.R')  ## OUTPUT: output/labeled_results_table.RDS  ---- df: education_results_table_labelled

# 4 ----------------- create workbook for tables -----------------
education_results_table_labelled <- readRDS("output/labeled_results_table.RDS")

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
  "level4" = 9
)

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

openxlsx::saveWorkbook(wb, "output/education_results.xlsx", overwrite = T)
openxlsx::openXL("output/education_results.xlsx")

# 6 ----------------- 05-01-make-level-table.R -----------------
# To repeat according to the number of tabs in the data_helper
tab_helper <- "access"
results_filtered <- "output/rds_results/access_results.rds"
source("src/05-01-make-graphs-and-maps-tables.R")

tab_helper <- "overaged"
results_filtered <- "output/rds_results/overaged_results.rds"
source("src/05-01-make-graphs-and-maps-tables.R")

tab_helper <- "out_of_school"
results_filtered <- "output/rds_results/out_of_school_results.rds"
source("src/05-01-make-graphs-and-maps-tables.R")

tab_helper <- "ece"
results_filtered <- "output/rds_results/ece_results.rds"
source("src/05-01-make-graphs-and-maps-tables.R")

tab_helper <- "level1"
results_filtered <- "output/rds_results/level1_results.rds"
source("src/05-01-make-graphs-and-maps-tables.R")

tab_helper <- "level2"
results_filtered <- "output/rds_results/level2_results.rds"
source("src/05-01-make-graphs-and-maps-tables.R")

tab_helper <- "level3"
results_filtered <- "output/rds_results/level3_results.rds"
source("src/05-01-make-graphs-and-maps-tables.R")
