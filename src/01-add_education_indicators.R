
#--------------------------------------------------------------------------------------------------------
# Read in the main and loop datasets
main <- readxl::read_xlsx(data_file,
                  na = c("NA", "#N/A", "", " ", "N/A"),
                  sheet = main_sheet, guess_max = 10000)

loop <- readxl::read_xlsx(data_file,
                  na = c("NA", "#N/A", "", " ", "N/A"),
                  sheet = loop_sheet, guess_max = 10000)

#survey_start_date = 'today'

#check if start is NULL
if (is.null(survey_start_date) || is.na(survey_start_date)) {
  main$start <- as.POSIXct("2024-06-01 11:54:54.574")
  survey_start_date = 'start'
}
if (country_assessment == "MOZ") {
  main[[survey_start_date]] <- substr(main[[survey_start_date]], 1, 10)
  replacement_date <- "2025-08-20"
  
  # identify missing or invalid values
  invalid <- is.na(main[[survey_start_date]]) |
    main[[survey_start_date]] == "" |
    is.na(as.Date(main[[survey_start_date]], format = "%Y-%m-%d"))
  
  # fill them
  main[[survey_start_date]][invalid] <- replacement_date
}
if (country_assessment == "ETH") {
  main[[survey_start_date]] <- substr(main[[survey_start_date]], 1, 10)
  replacement_date <- "2024-07-20"
  
  # identify missing or invalid values
  invalid <- is.na(main[[survey_start_date]]) |
    main[[survey_start_date]] == "" |
    is.na(as.Date(main[[survey_start_date]], format = "%Y-%m-%d"))
  
  # fill them
  main[[survey_start_date]][invalid] <- replacement_date
}
#main <- main %>%
  #mutate(survey_start_date = as_date(ymd_hms(survey_start_date)))


occupation_col <- if (!is.null(list_variables$occupation)) paste0(list_variables$occupation, "_d") else NULL
hazards_col <- paste0(list_variables$hazards, "_d")
displaced_col <- paste0(list_variables$displaced, "_d")
teacher_col <- paste0(list_variables$teacher, "_d")

loop <- loop %>%
  mutate(!!ind_age := as.numeric(.data[[ind_age]]))


if (country_assessment == "MMR") {
  columns_to_convert <- c(
    "edu_access_only_formal",
    "edu_access_only_nonformal",
    "edu_access_formal_OR_structured_nonformal",
    "edu_access_formal_AND_nonformal",
    "edu_access_formal_OR_nonformal"
  )
  
  loop <- loop %>%
    mutate(across(all_of(columns_to_convert), ~ as.numeric(.)))
}
#--------------------------------------------------------------------------------------------------------
# Apply transformations to loop dataset
loop <- loop |>
  # Education from Humind
  add_loop_edu_ind_age_corrected(main = main, id_col_loop = id_col_loop, id_col_main = id_col_main, survey_start_date = survey_start_date, 
                                 school_year_start_month = school_year_start_month, ind_age = ind_age, schooling_start_age = 5) |>
  add_loop_edu_access_d(ind_access = ind_access,  pnta = pnta, dnk = dnk, yes= yes,no =no) |>
  add_loop_edu_disrupted_d(attack  = occupation, hazards = hazards, displaced = displaced, teacher = teacher, levels = c(yes, no, dnk, pnta))
  
  
loop <- loop %>%
    dplyr::rename(
      edu_disrupted_hazards_d = !!rlang::sym(hazards_col),
      edu_disrupted_displaced_d = !!rlang::sym(displaced_col),
      edu_disrupted_teacher_d = !!rlang::sym(teacher_col)
  )

# Conditionally rename occupation if it is not NULL
if (!is.null(occupation_col)) {
    loop <- loop %>%
      dplyr::rename(edu_disrupted_occupation_d = !!rlang::sym(occupation_col))
}

# from 00_edu_function.R
loop <- loop |>
  # Add a column edu_school_cycle with ECE, primary (1 or 2 cycles) and secondary
  add_edu_school_cycle(country_assessment = country_code, path_ISCED_file = path_ISCED_file, language_assessment =language_assessment) |>

# IMPORTANT: THE INDICATOR MUST COMPLAY WITH THE MSNA GUIDANCE AND LOGIC --> data/edu_ISCED/UNESCO ISCED Mappings_MSNAcountries_consolidated
# Add columns to use for calculation of the composite indicators: Net attendance, early-enrollment, overage learners
  add_edu_level_grade_indicators(country_assessment = country_code, path_ISCED_file = path_ISCED_file, education_level_grade = education_level_grade, id_col_loop = id_col_loop, pnta = pnta, dnk = dnk)

#harmonized variable to use the loa_edu
loop <- loop |>
  add_loop_edu_barrier_d(barrier = barrier)|>
  add_loop_child_gender_d (ind_gender = ind_gender, language_assessment = language_assessment)

# OPTIONAL, non-core indicators, remove if not present in the MSNA
#add_loop_edu_optional_nonformal_d(edu_other_yn = "edu_other_yn",edu_other_type = 'edu_non_formal_type',yes = "yes",no = "no",pnta = "pnta",dnk = "dnk" )|>

if (!is.null(nonformal) && !is.na(nonformal)) {
    loop <- loop |>
      add_loop_edu_optional_nonformal_d(
        edu_other_yn = nonformal, 
        edu_other_type = nonformal_type, 
        pnta = pnta, 
        dnk = dnk, 
        yes = yes,
        no = no
      )
  }




############## WGS!!

if (!is.null(wsg_seeing) && !is.na(wsg_seeing) &&
    !is.null(wsg_hearing) && !is.na(wsg_hearing) &&
    !is.null(wsg_walking) && !is.na(wsg_walking) &&
    !is.null(wsg_remembering) && !is.na(wsg_remembering) &&
    !is.null(wsg_selfcare) && !is.na(wsg_selfcare) &&
    !is.null(wsg_communicating) && !is.na(wsg_communicating)) {
  loop <- loop |>
    add_loop_wgq_ss (ind_age = 'edu_ind_age_corrected', vision = wsg_seeing, hearing = wsg_hearing,
                     mobility = wsg_walking, cognition = wsg_remembering, self_care = wsg_selfcare, communication = wsg_communicating, 
                     no_difficulty = no_difficulty, some_difficulty = some_difficulty, lot_of_difficulty = lot_of_difficulty, cannot_do = cannot_do, 
                     undefined = c(dnk, pnta, 'refused_to_answer'))
}

if (country_assessment == "MMR") {
  loop <- loop %>%
    mutate(
      school_cycle_pop = NA_character_,
      disagg_pop_wgq_dis_3 = NA_character_,
      disagg_pop_wgq_dis_2 = NA_character_,
      disagg_pop_access = NA_character_
    )
}
if (country_assessment == "AFG") {
  loop <- loop %>%
    mutate(
      coping_barrier = NA_character_
    )
}
#--------------------------------------------------------------------------------------------------------
# Merge main info into loop dataset
# add strata inf from the main dataframe, IMPORTAN: weight and the main strata
check_and_set_merge_column <- function(loop, main_col) {
  if (is.null(main_col) || main_col %in% colnames(loop)) NA_character_ else main_col
}
  

add_cols_tot = c()
if (country_assessment == "UKR") {
  # everything you want to pull from 'main'
  add_cols_tot <- c(
    "D_7_edu_disrupted_displacement",
    "D_3_edu_modality",
    "D_6_edu_disrupted_school_damage",
    "G_2_edu_disrupted_air_alerts",
    "G_3_edu_support_time",
    "K_20_utility_interrupt",
    "K_22_internet_hours",
    "J_2_conflict_exposure_shelling",
    "J_3_conflict_exposure_shelling_freq",
    "J_4_conflict_exposure_attacks",
    "J_5_conflict_exposure_attacks_freq",
    "J_6_gen_safety_incidents",
    "J_6_0_gen_safety_incidents_other",
    "J_8_risk_concern",
    "J_9_leave_concern",
    "K_10_shelter_damage",
    "K_11_shelter_damage_repaired",
    "K_12_shelter_damage_repaired_reasons",
    "K_12_1_shelter_damage_repaired_reasons_other",
    "K_13_shelter_damage_type"

  )
}
if (country_assessment == "DRC") {
  # everything you want to pull from 'main'
  add_cols_tot <- c(
    "edu_disrupted_attack_afc")}
if (country_assessment == "CAR") {
  # everything you want to pull from 'main'
  add_cols_tot <- c(
    "edu_barrier_2nd_reason")}
if (country_assessment == "AFG") {
  # everything you want to pull from 'main'
  add_cols_tot <- c(
    "children_schooling_type"
    
  )}
if (country_assessment == "MOZ") {
  # everything you want to pull from 'main'
  add_cols_tot <- c("edu_ind_has_impairment",
    "barrier_impairament"
    
  )}
if (country_assessment == "MMR") {
  # everything you want to pull from 'main'
  add_cols_tot <- c('edu_community_modality'
                    
  )}
if (country_assessment == "SOM") {
  # everything you want to pull from 'main'
  add_cols_tot <- c('edu_program_type'
                    
  )}
if (country_assessment == "SDN") {
  # everything you want to pull from 'main'
  add_cols_tot <- c('schl_learnin_enviro'
                    
  )}
if (country_assessment == "SYR") {
  # everything you want to pull from 'main'
  add_cols_tot <- c('edu_access_syr', "edu_acceptable_conditions", "edu_barrier_syr", 
                    "edu_ind_not_enrolled", "edu_ind_not_enrolled", "edu_other_type_syr",
                    "edu_other_yn_syr"
                    
  )}
if (country_assessment == "LBN") {
  # everything you want to pull from 'main'
  add_cols_tot <- c('edu_disrupted_financial', 'formal_school_type', 
                    'edu_access_past', 'edu_enrolment_past'

  )}
if (country_assessment == "BFA") {
  # everything you want to pull from 'main'
  add_cols_tot <- c('e_incident_trajet', 'e_incident_ecol', "e_abandon"
  )}

#modality_column <- "edu_community_modality"  # already set above
modality_column <- "edu_community_modality"  # already set above
barrier_multiple_ssd <- "edu_barrier_sm"  # already set above
barrier_multiple_ukr <- "D_5_edu_barrier_sm"  # already set above
barrier_multiple_eth <- "edu_barrier"  # already set above
concern_multiple_sdn <- "alternative_education"  # already set above
barrier_multiple_sdn <- "barriers_education"  # already set above
barrier_multiple_syr <- "edu_barriers_conditions"  # already set above
barrier_multiple_bfa <- "e_educ_non_formel_type"  # already set above



# gather your legacy add_col1...add_col9
candidates <- c(add_col1, add_col2, add_col3, add_col4,
                add_col5, add_col6, add_col7, add_col8, add_col9)

# 1) combine BOTH sources (drop NULLs + dedupe)
wish <- unique(c(Filter(Negate(is.null), candidates), add_cols_tot))

modality_cols <- names(main)[
  grepl(paste0("^", modality_column, "([_/\\.].*|$)"), names(main))
]

if (length(modality_cols)) {
  wish <- unique(c(wish, modality_cols))
}
if (country_assessment == "SSD") {
  barrier_sm_cols <- names(main)[
    grepl(paste0("^", barrier_multiple_ssd, "([_/\\.].*|$)"), names(loop))
  ]
  if (length(barrier_sm_cols)) {
    wish <- unique(c(wish, barrier_sm_cols))
  }
}
if (country_assessment == "UKR") {
  barrier_sm_cols <- names(main)[
    grepl(paste0("^", barrier_multiple_ukr, "([_/\\.].*|$)"), names(loop))
  ]
  if (length(barrier_sm_cols)) {
    wish <- unique(c(wish, barrier_sm_cols))
  }
}
if (country_assessment == "ETH") {
  barrier_sm_cols <- names(main)[
    grepl(paste0("^", barrier_multiple_eth, "([_/\\.].*|$)"), names(loop))
  ]
  if (length(barrier_sm_cols)) {
    wish <- unique(c(wish, barrier_sm_cols))
  }
}
if (country_assessment == "SYR") {
  barrier_sm_cols <- names(main)[
    grepl(paste0("^", barrier_multiple_syr, "([_/\\.].*|$)"), names(loop))
  ]
  if (length(barrier_sm_cols)) {
    wish <- unique(c(wish, barrier_sm_cols))
  }
}
if (country_assessment == "SDN") {
  barrier2_sm_cols <- names(main)[
    grepl(paste0("^", concern_multiple_sdn, "([_/\\.].*|$)"), names(loop))
  ]
  if (length(barrier2_sm_cols)) {
    wish <- unique(c(wish, barrier2_sm_cols))
  }
}
if (country_assessment == "SDN") {
  barrier_sm_cols <- names(main)[
    grepl(paste0("^", barrier_multiple_sdn, "([_/\\.].*|$)"), names(loop))
  ]
  if (length(barrier_sm_cols)) {
    wish <- unique(c(wish, barrier_sm_cols))
  }
}
if (country_assessment == "BFA") {
  barrier_sm_cols <- names(main)[
    grepl(paste0("^", barrier_multiple_bfa, "([_/\\.].*|$)"), names(loop))
  ]
  if (length(barrier_sm_cols)) {
    wish <- unique(c(wish, barrier_sm_cols))
  }
}

# 2) only merge columns that are NOT already in loop
#    (this guarantees we won’t drop/replace existing loop columns)
add_cols <- setdiff(wish, colnames(loop))
#add_cols <- wish
# 3) call the merge (disable regex auto-includes to avoid re-merging existing cols)
loop <- merge_main_info_in_loop(
  loop = loop, main = main,
  id_col_loop = id_col_loop, id_col_main = id_col_main,
  admin1 = admin1, admin2 = admin2, admin3 = admin3,
  stratum = stratum, additional_stratum = additional_stratum,
  weight = weight_col,
  add_cols = add_cols,
  include_regex = character(0)   # important if you want to avoid re-merging matches already in loop
)


#columns_to_add <- setdiff(names(main), names(loop))


# loop <- loop %>%
#   left_join(main %>% select(all_of(c(id_col_main, columns_to_add))), 
#             by = setNames(id_col_main, id_col_loop))

if (country_assessment == "MMR") {
  loop <- loop %>%
    mutate(
      school_cycle_pop = paste(pop_group, edu_school_cycle_d, sep = "#"),
      disagg_pop_wgq_dis_3 = paste(pop_group, wgq_dis_3, sep = "#"),
      disagg_pop_wgq_dis_2 = paste(pop_group, wgq_dis_2, sep = "#"),
      disagg_pop_access= paste(pop_group, edu_ind_access_d, sep = "#")
    )
}
#if (country_assessment == "AFG") {
  #loop <- loop %>%
   # mutate(
     # coping_barrier = paste0(!!rlang::sym(add_col4), "#", edu_barrier_d)
    #)
#}
# keep only school-age children
loop <- loop |>
  dplyr::filter(edu_ind_schooling_age_d == 1) |>
  dplyr::mutate(
    young_adult = dplyr::case_when(
      edu_ind_age_corrected %in% c(15,16, 17) ~ "15 - 17 y.o.",
      TRUE ~ "< 15 y.o."
    )
  )


loop <- loop |> filter(edu_ind_schooling_age_d == 1)
 if (country_assessment == "AFG"){
   loop <- loop |> filter(edu_ind_age_corrected != 5)
 }

loop_edu_recorded <- loop


#--------------------------------------------------------------------------------------------------------
# Save the final output to an Excel file
loop |> write.xlsx(paste0('output/loop_edu_recorded_',country_assessment,'.xlsx'))
  




