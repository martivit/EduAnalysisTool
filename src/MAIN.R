
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

source('src/01-add_education_indicators.R')
source('src/02-education_analysis.R')
source('src/03-education_labeling.R')
source('src/04-02-make-table-disruptions.R')
source('src/04-03-make-table-barriers.R')
source('src/04-04-make-ece-table.R')
source('src/04-05-make-level-table.R')


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
#please modify the group_var according to your context

loa_path = "input_tool/edu_analysistools_loa.xlsx" 

suffix <- ifelse(language_assessment == 'French', "_FR", "_EN")
data_helper_table <- paste0("input_tool/edu_table_helper", suffix, ".xlsx")

labelling_tool_path <- "input_tool/edu_indicator_labelling.xlsx"

##-------------  definition of variable according to the analysis' context 
id_col_loop = '_submission__uuid.x' # uuid
id_col_main = '_uuid' # uuid 
survey_start_date = 'start'# column with the survey start
school_year_start_month = 9 # start school year in country
ind_age = 'ind_age' # individual age variable
ind_gender = 'ind_gender' # individual gender variable
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
barrier = "edu_barrier"
barrier_other = "other_edu_barrier"
number_displayed_barrier = 5

# strata --> check consistency with the group_var column  in the loa
admin1 = 'admin1'
admin3 = 'admin3'
add_col1 = 'setting'
add_col2 = 'depl_situation_menage'
#stratum = 

###################################################################################################

# 1 -- 01-add_education_indicators.R
add_education_indicators(country_assessment = country_assessment, data_file = data_file, path_ISCED_file = path_ISCED_file,
                        main_sheet = label_main_sheet,loop_sheet = label_edu_sheet,
                        id_col_loop = id_col_loop, id_col_main = id_col_main,survey_start_date = survey_start_date,school_year_start_month = school_year_start_month,ind_age = ind_age,pnta = pnta,dnk = dnk,
                        ind_access = ind_access,occupation = occupation,hazards = hazards,displaced = displaced,teacher = teacher,education_level_grade = education_level_grade,barrier = barrier,
                        admin1 = admin1,admin3 = admin3, add_col1 = add_col1, add_col2 = add_col2)

# 2 -- 02-education_analysis.R
run_education_analysis(loa_path, number_displayed_barrier = number_displayed_barrier, weight_col = weight_col)

# 3 -- 03-education_labeling.R
change_label (kobo_path = kobo_path, label_survey_sheet = label_survey_sheet, label_choices_sheet = label_choices_sheet, labeling_path = labelling_tool_path, 
              language = language_assessment, label_column_kobo = kobo_language_label) 

# 4 -- create workbook for tables
wb <- openxlsx::createWorkbook("education_results")
addWorksheet(wb, "Table_of_content")
writeData(wb, sheet = "Table_of_content", x = "Table of Content", startCol = 1, startRow = 1)

# 5 -- 04-02-make-table-disruptions.R
create_access_education_table( loa_file =loa_path,  data_helper_file = data_helper_table, language = language_assessment)

# 6 -- 04-03-make-table-barriers.R
## IMPORTANT: open grouped_other_education_results_loop and copy the first (in decreasing order) 5 edu_barrier_d results in the edu_indicator_labelling_FR/EN.xlsx.  
create_out_of_school_education_table( loa_file =loa_path,  data_helper_file = data_helper_table, language = language_assessment)

# 7 -- 04-04-make-ece-table.R
create_ece_table (loa_file =loa_path,  data_helper_file = data_helper_table, gender_var = ind_gender, language = language_assessment) 

# 8 -- 04-05-make-level-table.R
# To repeat according to the number of levels (except ECE) in the country's school system
create_level_education_table( level_table = 'level1',
                              loa_file =loa_path,  data_helper_file = data_helper_table, path_ISCED_file = path_ISCED_file,  gender_var = ind_gender, language = language_assessment) 
create_level_education_table( level_table = 'level2',
                              loa_file =loa_path,  data_helper_file = data_helper_table, path_ISCED_file = path_ISCED_file,  gender_var = ind_gender, language = language_assessment) 
create_level_education_table( level_table = 'level3',
                              loa_file =loa_path,  data_helper_file = data_helper_table, path_ISCED_file = path_ISCED_file,  gender_var = ind_gender, language = language_assessment) 


openxlsx::saveWorkbook(wb, "output/education_results.xlsx", overwrite = T)
