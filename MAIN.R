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

# Disaggregation levels are read from the strata_variables sheet's
# strata_lvl_1..strata_lvl_15 columns for country_assessment (see
# src/00-getting-info-country.R). Only strata_lvl_1 is mandatory; the rest
# may be left blank (get_strata_variables()/mget() already drop unset levels).
strata_var_names <- paste0("strata_lvl_", 1:15)

##---------------- READING INFO AND VARIABLES FROM  matadata.xlsx
source("src/00-getting-info-country.R")
language_assessment = list_info_general$language_assessment

## --------------- File paths
# Stops with a clear message naming the file and the metadata field that produced it,
# instead of letting readxl fail later with a generic "file does not exist" error.
require_input_file <- function(path, field_description) {
  if (!file.exists(path)) {
    stop(sprintf(
      "Required file not found: '%s' (%s). Check the corresponding value in input_tool/01_metadata/metadata_edu.xlsx.",
      path, field_description
    ))
  }
  invisible(TRUE)
}

#-- input data
path_ISCED_file <- "resources/UNESCO ISCED Mappings_MSNAcountries_consolidated.xlsx"
require_input_file(path_ISCED_file, "ISCED mapping file, path hardcoded in MAIN.R")

data_file <- paste0("DATA/",country_assessment, "/",list_info_general$dataset)
require_input_file(data_file, "general$dataset in input_tool/01_metadata/metadata_edu.xlsx, combined with DATA/<country_assessment>/")
label_main_sheet <- list_info_general$label_main_sheet
label_edu_sheet  <- list_info_general$label_edu_sheet

kobo_path <- paste0("DATA/",country_assessment, "/",list_info_general$dataset)
label_survey_sheet  <-  list_info_general$label_survey_sheet
label_choices_sheet <-  list_info_general$label_choices_sheet
kobo_language_label <-  list_info_general$kobo_language_label

# Optional pcode columns (admin1/2/3), merged into loop alongside the strata
# levels in 01-add_education_indicators.R. NULL (and simply not merged) if left
# blank in metadata_edu.xlsx.
adm1_pcode_col <- list_info_general$adm1_pcode_colum
adm2_pcode_col <- list_info_general$adm2_pcode_colum
adm3_pcode_col <- list_info_general$adm3_pcode_colum

#-- input tool
# please modify the group_var according to your context

loa_path <- if (!is.null(list_info_general$loa_file)) {
  paste0("input_tool/03_loa/", list_info_general$loa_file)
} else {
  warning("general$loa_file is blank for country_assessment = '", country_assessment, "' in input_tool/01_metadata/metadata_edu.xlsx; ",
          "falling back to the shared example LOA (input_tool/03_loa/edu_analysistools_loa_starting_kit.xlsx). ",
          "Set a country-specific loa_file if this isn't intended.")
  "input_tool/03_loa/edu_analysistools_loa_starting_kit.xlsx"
}
require_input_file(loa_path, "general$loa_file in input_tool/01_metadata/metadata_edu.xlsx (blank falls back to the starting-kit LOA)")

suffix <- ifelse(language_assessment == "French", "_FR", "_EN")
data_helper_table <- paste0("input_tool/02_edu_table/edu_table_helper", suffix,'_', country_assessment,".xlsx")
require_input_file(data_helper_table, "derived from general$language_assessment and country_assessment; expected in input_tool/02_edu_table/")

labelling_tool_path <- "input_tool/edu_indicator_labelling.xlsx"
require_input_file(labelling_tool_path, "labelling tool, path hardcoded in MAIN.R")

## -------------  definition of variable according to the analysis' context
id_col_loop = list_variables$id_col_loop
id_col_main = list_variables$id_col_main
survey_start_date = list_variables$survey_start_date
school_year_start_month = list_variables$school_year_start_month # start school year in country
ind_age = list_variables$ind_age # individual age variable
ind_gender = list_variables$ind_gender # individual gender variable
pnta = list_variables$pnta
dnk = list_variables$dnk
yes = list_variables$yes
no = list_variables$no
weight_col <- list_variables$weight_col
schooling_start_age <- if (!is.null(list_variables$schooling_start_age)) list_variables$schooling_start_age else 5 # optional metadata field; defaults to 5 if blank
schooling_end_age <- if (!is.null(list_variables$schooling_end_age)) list_variables$schooling_end_age else 17 # optional metadata field; defaults to 17 if blank

#------------- indicators
ind_access <- list_variables$ind_access
occupation <- list_variables$occupation
hazards <- list_variables$hazards
displaced <- list_variables$displaced
teacher <- list_variables$teacher
education_level_grade <- list_variables$education_level_grade
barrier = list_variables$barrier
number_displayed_barrier <- if (!is.null(list_variables$number_displayed_barrier)) list_variables$number_displayed_barrier else 15 # optional metadata field; defaults to 15 if blank
# non formal
nonformal <-list_variables$nonformal
nonformal_type <-list_variables$nonformal_type
#wgs
wsg_seeing <-list_variables$wsg_seeing
wsg_hearing <-list_variables$wsg_hearing
wsg_walking <-list_variables$wsg_walking
wsg_remembering <-list_variables$wsg_remembering
wsg_selfcare <-list_variables$wsg_selfcare
wsg_communicating <-list_variables$wsg_communicating
no_difficulty <-list_variables$no_difficulty
some_difficulty <-list_variables$some_difficulty
lot_of_difficulty <-list_variables$lot_of_difficulty
cannot_do <-list_variables$cannot_do



label_overall <- if (language_assessment == "French") "Ensemble" else "Overall"
label_female <- if (language_assessment == "French") "Filles" else "Girls"
label_male <- if (language_assessment == "French") "Garcons" else "Boys"
label_edu_school_cycle <- if (language_assessment == "French") "Cycle Scolaire Assigné par Âge" else "Age-Assigned School Cycle"

# Read ISCED info
country_code <- str_sub(country_assessment, 1, 3)
info_country_school_structure <- read_ISCED_info(country_code, path_ISCED_file)
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

source("src/01-5-creating_loa.R") ## OUTPUT: input_tool/loa_analysis_<country_assessment>.csv

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

