
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

source ('src/functions/00_edu_helper.R')
source ('src/functions/00_edu_function.R')
source('src/01-add_education_indicators.R')
source('src/02-education_analysis.R')
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

#-- input tool
#please modify the group_var according to your context

loa_path = "input_tool/edu_analysistools_loa.xlsx" 

suffix <- ifelse(language_assessment == 'French', "_FR", "_EN")
data_helper_table <- paste0("input_tool/edu_table_helper", suffix, ".xlsx")

labelling_tool_path <- "input_tool/edu_indicator_labelling.xlsx"

##-------------  definition of variable according to the analysis' context 
id_col_loop = '_submission__uuid.x' # uuid
id_col_main = '_uuid' # uuid 
survey_start_date = 'start'# column with the survery start
school_year_start_month = 9 # start school year in country
ind_age = 'ind_age' # individual age variable
pnta = "pnta"
dnk = "dnk"


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
                        ind_access = ind_access,occupation = occupation,hazards = hazards,displaced = displaced,teacher = teacher,education_level_grade = education_level_grade,barrier = barrier,barrier_other = barrier_other,
                        admin1 = admin1,admin3 = admin3, add_col1 = add_col1, add_col2 = add_col2)

# 2 -- 02-education_analysis.R
run_education_analysis(loa_path, number_displayed_barrier = number_displayed_barrier)



## IMPORTANT: open grouped_other_education_results_loop and copy the first (in decreasing order) 5 edu_barrier_d results in the edu_indicator_labelling_FR/EN.xlsx.  

