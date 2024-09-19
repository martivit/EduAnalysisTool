
# Load packages -----------------------------------------------------------
library(impactR.utils)
library(humind)
library(humind.data)
library (presentresults)

# Needed tidyverse packages
library(dplyr)
library(readxl)
library(openxlsx)
library(writexl)
library(tidyr)
library(stringr)
library(tidyverse)
library(tibble)
library(ggplot2)
library(grid)
library(gridExtra)
library(ggtext)
library(srvyr)
library(analysistools)
library(gt)


source ('src/functions/00_edu_helper.R')
source ('src/functions/00_edu_function.R')
source("src/functions/create_education_table_group_x_var.R")
source("src/functions/create_education_xlsx_table.R")

# source('src/01-add_education_indicators.R')
# source('src/02-education_analysis.R')
# source('src/03-education_labeling.R')
# source('src/04-02-make-table-disruptions.R')
# source('src/04-03-make-table-barriers.R')
# source('src/04-04-make-ece-table.R')
# source('src/04-05-make-level-table.R')


## --------------------------
#country_assessment = 'HTI'
#language_assessment = 'French'
country_assessment = 'AFG'
language_assessment = 'English'

## --------------- File paths
#-- input data
# path_ISCED_file <- 'resources/UNESCO ISCED Mappings_MSNAcountries_consolidated.xlsx'
# data_file <- 'input_data/HTI2401-MSNA-DEPARTEMENTS-Clean-dataset.xlsx'
# label_main_sheet <-'Clean Data'
# label_edu_sheet <- 'ind_loop'
path_ISCED_file <- 'resources/UNESCO ISCED Mappings_MSNAcountries_consolidated.xlsx'
data_file <- 'input_data/AFG2403_MSNA_WoAA_2024_clean_data.xlsx'
label_main_sheet <-'AFG2403 MSNA WoAA 2024 MODULE 1'
label_edu_sheet <- 'edu_ind'

# kobo_path <- "input_data/HTI_kobo.xlsx"
# label_survey_sheet <-'survey'
# label_choices_sheet <- 'choices'
# kobo_language_label <- "label::french"
kobo_path <- "input_data/AFG2403_MSNA_WoAA2024_kobo_tool.xlsx"
label_survey_sheet <-'survey'
label_choices_sheet <- 'choices'
kobo_language_label <- "label::English"

#-- input tool
#please modify the group_var according to your context

#loa_path = "input_tool/edu_analysistools_loa.xlsx" 
loa_path = "input_tool/edu_analysistools_loa_AFG.xlsx" 


suffix <- ifelse(language_assessment == 'French', "_FR", "_EN")
data_helper_table <- paste0("input_tool/edu_table_helper", suffix, ".xlsx")
data_helper_table <- ("input_tool/edu_table_helper_EN_AFG.xlsx")

labelling_tool_path <- "input_tool/edu_indicator_labelling.xlsx"

##-------------  definition of variable according to the analysis' context 
# id_col_loop = '_submission__uuid.x' # uuid
# id_col_main = '_uuid' # uuid 
# survey_start_date = 'start'# column with the survey start
# school_year_start_month = 9 # start school year in country
# ind_age = 'ind_age' # individual age variable
# ind_gender = 'ind_gender' # individual gender variable
# pnta = "pnta"
# dnk = "dnk"
# weight_col = 'weight'
id_col_loop = '_submission__uuid' # uuid
id_col_main = '_uuid' # uuid 
survey_start_date = 'start'# column with the survey start
school_year_start_month = 9 # start school year in country
ind_age = 'edu_ind_age' # individual age variable
ind_gender = 'edu_ind_gender' # individual gender variable
pnta = "pnta"
dnk = "dnk"
weight_col = 'weights'


# indicators
ind_access = 'edu_access'
occupation = 'edu_disrupted_occupation'
hazards = 'edu_disrupted_hazards'
displaced = 'edu_disrupted_displaced'
teacher = 'edu_disrupted_teacher'
education_level_grade =  "edu_level_grade"
#barrier = "edu_barrier"
barrier = "resn_no_access"
number_displayed_barrier = 5

# strata --> check consistency with the group_var column  in the loa
# add_col1 = 'setting'
# add_col2 = 'depl_situation_menage'
admin1 = 'admin1'
admin2 = 'admin2'
admin3 = 'admin3'
add_col1 = 'urbanity_setting'
add_col2 = 'forcibly_displaced'
#stratum = 

###################################################################################################

# 1 ----------------- 01-add_education_indicators.R ----------------- 
main_sheet <- label_main_sheet
loop_sheet <- label_edu_sheet
stratum <- NULL
additional_stratum <- NULL
add_col3 <- NULL
add_col4 <- NULL
add_col5 <- NULL
add_col6 <- NULL
add_col7 <- NULL
add_col8 <- NULL
#source('src/01-add_education_indicators.R') ## OUTPUT: output/loop_edu_recorded.xlsx

# 2 ----------------- 02-education_analysis.R ----------------- 
#source('src/02-education_analysis.R') ## OUTPUT: output/grouped_other_education_results_loop.RDS

# 3 ----------------- 03-education_labeling.R ----------------- 
#source('src/03-education_labeling.R')  ## OUTPUT: output/labeled_results_table.RDS  ---- df: education_results_table_labelled

# 4 ----------------- create workbook for tables ----------------- 
wb <- openxlsx::createWorkbook("education_results")
addWorksheet(wb, "Table_of_content")
writeData(wb, sheet = "Table_of_content", x = "Table of Content", startCol = 1, startRow = 1)

# 5 ----------------- 04-01-make-table-access-disruptions.R ----------------- 
source('src/04-01-make-table-access-disruptions.R')

# 6 ----------------- 04-02-make-table-access-overage.R ----------------- 
source('src/04-02-make-table-access-overage.R')

# 7 ----------------- 04-03-make-table-barriers.R ----------------- 
## IMPORTANT: open grouped_other_education_results_loop and copy the first (in decreasing order) 5 edu_barrier_d results in the edu_indicator_labelling_FR/EN.xlsx.
source('src/04-03-make-table-barriers.R')


# 8 ----------------- 04-04-make-ece-table.R ----------------- 
source('src/04-04-make-ece-table.R')


# 9 ----------------- 04-05-make-level-table.R ----------------- 
# To repeat according to the number of levels (except ECE) in the country's school system
level_table = 'level1'
source('src/04-05-make-level-table.R')
level_table = 'level2'
source('src/04-05-make-level-table.R')
level_table = 'level3'
source('src/04-05-make-level-table.R')

openxlsx::saveWorkbook(wb, "output/education_results.xlsx", overwrite = T)
# openxlsx::openXL("output/education_results.xlsx")

# 10 ----------------- 05-01-make-level-table.R ----------------- 
tab_helper <- "access"
results_filtered <- "output/rds_results/access_disruptions_results.rds"
source('src/05-01-make-graphs-and-maps-tables.R')

tab_helper <- "out_of_school"
results_filtered <- "output/rds_results/barriers_results.rds"
source('src/05-01-make-graphs-and-maps-tables.R')

tab_helper <- "ece"
results_filtered <- "output/rds_results/ece_results.rds"
source('src/05-01-make-graphs-and-maps-tables.R')

tab_helper <- "level1"
results_filtered <- "output/rds_results/level1_results.rds"
source('src/05-01-make-graphs-and-maps-tables.R')

tab_helper <- "level2"
results_filtered <- "output/rds_results/level2_results.rds"
source('src/05-01-make-graphs-and-maps-tables.R')

tab_helper <- "level3"
results_filtered <- "output/rds_results/level3_results.rds"
source('src/05-01-make-graphs-and-maps-tables.R')
