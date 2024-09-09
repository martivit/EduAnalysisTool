
# Load packages -----------------------------------------------------------

#install.packages("pak")
#pak::pak("gnoblet/impactR.utils")
library(impactR.utils)

#Loading humind loads functions
#pak::pak("impact-initiatives-hppu/humind")
library(humind)

# Loading example data
#pak::pak("impact-initiatives-hppu/humind.data")
library(humind.data)
data(dummy_raw_data, package = "humind.data")

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
path_ISCED_file = 'resources/UNESCO ISCED Mappings_MSNAcountries_consolidated.xlsx'
# Prepare datasets --------------------------------------------------------
HTI_file <- 'input_data/HTI2401-MSNA-DEPARTEMENTS-Clean-dataset.xlsx'

main  <- read_xlsx(HTI_file,
                             guess_max = 50000,
                             na = c("NA","#N/A",""," ","N/A"),
                             sheet = 'Clean Data')
loop <- read_xlsx(HTI_file,
                    guess_max = 50000,
                    na = c("NA","#N/A",""," ","N/A"),
                    sheet = 'ind_loop')



# Add indicators ----------------------------------------------------------


loop <- loop |>
  # Education from Humind
  add_loop_edu_ind_age_corrected(main = main,id_col_loop = '_submission__uuid.x', id_col_main = '_uuid', survey_start_date = 'start', school_year_start_month = 9, ind_age = 'ind_age') |>
  add_loop_edu_access_d( ind_access = 'edu_access') |>
  add_loop_edu_disrupted_d (occupation = 'edu_disrupted_occupation', hazards = 'edu_disrupted_hazards', displaced = 'edu_disrupted_displaced', teacher = 'edu_disrupted_teacher')|>

  # from 00_edu_function.R

  # Add a column edu_school_cycle with ECE, primary (1 or 2 cycles) and secondary
  add_edu_school_cycle(country_assessment = 'HTI', path_ISCED_file)|>

  # IMPORTANT: THE INDICATOR MUST COMPLAY WITH THE MSNA GUIDANCE AND LOGIC --> data/edu_ISCED/UNESCO ISCED Mappings_MSNAcountries_consolidated
  # Add columns to use for calculation of the composite indicators: Net attendance, early-enrollment, overage learners
  add_edu_level_grade_indicators(country_assessment = 'HTI', path_ISCED_file, education_level_grade =  "edu_level_grade", id_col_loop = '_submission__uuid.x',  pnta = "pnta",
                                 dnk = "dnk")|>

  #harmonized variable to use the loa_edu
  add_loop_edu_barrier_d( barrier = "edu_barrier", barrier_other = "other_edu_barrier")|>

  # OPTIONAL, non-core indicators, remove if not present in the MSNA
  #add_loop_edu_optional_nonformal_d(edu_other_yn = "edu_other_yn",edu_other_type = 'edu_non_formal_type',yes = "yes",no = "no",pnta = "pnta",dnk = "dnk" )|>
  #add_loop_edu_optional_community_modality_d(edu_community_modality = "edu_community_modality" )|>


  # add strata inf from the main dataframe, IMPORTAN: weight and the main strata
  merge_main_info_in_loop( main, id_col_loop = '_submission__uuid.x', id_col_main = '_uuid',
                          admin1 = 'admin1', admin3 = 'admin3',  add_col1 = 'setting', add_col2 = 'depl_situation_menage'  ) |>
  # keep only school-age children
  filter (edu_ind_schooling_age_d  == 1 )


loop |> write.xlsx('output/loop_edu_recorded.xlsx')
