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

# All outputs for this run are written under output/<country_assessment>/, created here so
# every downstream write below (and the matching reads that follow it) can assume it exists.
output_dir <- paste0("output/", country_assessment)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(paste0(output_dir, "/rds_results"), recursive = TRUE, showWarnings = FALSE)
dir.create(paste0(output_dir, "/plots_", country_assessment), recursive = TRUE, showWarnings = FALSE)
dir.create(paste0(output_dir, "/table_for_maps"), recursive = TRUE, showWarnings = FALSE)

# 1 ----------------- 01-add_education_indicators.R -----------------
source("src/01-add_education_indicators.R") ## OUTPUT: output/<country_assessment>/loop_edu_recorded_<country_assessment>.xlsx

source("src/01-5-creating_loa.R") ## OUTPUT: input_tool/03_loa/loa_analysis_<country_assessment>.csv

# 2 ----------------- 02-education_analysis.R -----------------
source("src/02-education_analysis.R") ## OUTPUT: output/<country_assessment>/grouped_other_education_results_loop_<country_assessment>.RDS

# 3 ----------------- 03-education_labeling.R -----------------
source("src/03-education_labeling.R")  ## OUTPUT: output/<country_assessment>/labeled_results_table_<country_assessment>.RDS  ---- df: education_results_table_labelled

# Steps 4-6 (table workbook, per-tab tables, and graphs/maps) have been stripped
# from this branch: src/04-01-make-table-access-overaged-barriers.R,
# src/04-02-make-level-table.R, and src/05-01-make-graphs-and-maps-tables.R are
# untested against the current config-validation/strata changes. See README.md
# for the previous (still-documented, not deleted) usage of those scripts if
# you want to try them against this branch's output.
