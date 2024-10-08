
#--------------------------------------------------------------------------------------------------------
# Read in the main and loop datasets
main <- read_xlsx(data_file,
                  guess_max = 50000,
                  na = c("NA", "#N/A", "", " ", "N/A"),
                  sheet = main_sheet)

loop <- read_xlsx(data_file,
                  guess_max = 50000,
                  na = c("NA", "#N/A", "", " ", "N/A"),
                  sheet = loop_sheet)

#--------------------------------------------------------------------------------------------------------
# Apply transformations to loop dataset
loop <- loop |>
  # Education from Humind
  add_loop_edu_ind_age_corrected(main = main, id_col_loop = id_col_loop, id_col_main = id_col_main, survey_start_date = survey_start_date, school_year_start_month = school_year_start_month, ind_age = ind_age) |>
  add_loop_edu_access_d(ind_access = ind_access) |>
  add_loop_edu_disrupted_d(occupation = occupation, hazards = hazards, displaced = displaced, teacher = teacher) |>
  
  # from 00_edu_function.R
  
  # Add a column edu_school_cycle with ECE, primary (1 or 2 cycles) and secondary
  add_edu_school_cycle(country_assessment = country_assessment, path_ISCED_file = path_ISCED_file, language_assessment =language_assessment) |>
  
  # IMPORTANT: THE INDICATOR MUST COMPLAY WITH THE MSNA GUIDANCE AND LOGIC --> data/edu_ISCED/UNESCO ISCED Mappings_MSNAcountries_consolidated
  # Add columns to use for calculation of the composite indicators: Net attendance, early-enrollment, overage learners
  add_edu_level_grade_indicators(country_assessment = country_assessment, path_ISCED_file = path_ISCED_file, education_level_grade = education_level_grade, id_col_loop = id_col_loop, pnta = pnta, dnk = dnk) |>
  
  #harmonized variable to use the loa_edu
  add_loop_edu_barrier_d(barrier = barrier)|>
  add_loop_child_gender_d (ind_gender = ind_gender, language_assessment = language_assessment)

# OPTIONAL, non-core indicators, remove if not present in the MSNA
#add_loop_edu_optional_nonformal_d(edu_other_yn = "edu_other_yn",edu_other_type = 'edu_non_formal_type',yes = "yes",no = "no",pnta = "pnta",dnk = "dnk" )|>
#add_loop_edu_optional_community_modality_d(edu_community_modality = "edu_community_modality" )|>

#--------------------------------------------------------------------------------------------------------
# Merge main info into loop dataset
# add strata inf from the main dataframe, IMPORTAN: weight and the main strata
loop <- merge_main_info_in_loop(loop = loop, main = main, id_col_loop = id_col_loop, id_col_main = id_col_main,
                                admin1 = admin1, admin2 = admin2, admin3 = admin3, stratum = stratum, 
                                additional_stratum = additional_stratum, weight = weight_col, 
                                add_col1 = add_col1, add_col2 = add_col2, add_col3 = add_col3, 
                                add_col4 = add_col4, add_col5 = add_col5, add_col6 = add_col6, 
                                add_col7 = add_col7, add_col8 = add_col8)

# keep only school-age children
loop <- loop |> filter(edu_ind_schooling_age_d == 1)
if (country_assessment == "AFG"){
  loop <- loop |> filter(edu_ind_age_corrected != 5)
}
loop_edu_recorded <- loop


#--------------------------------------------------------------------------------------------------------
# Save the final output to an Excel file
loop |> write.xlsx('output/loop_edu_recorded.xlsx')
  




