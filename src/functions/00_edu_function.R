
##----------------------------------------------------------------------------------------------------------
add_edu_school_cycle <- function(roster, country_assessment = 'BFA', path_ISCED_file, edu_ind_age_corrected = 'edu_ind_age_corrected', language_assessment) {
  # Read school structure information for the specified country
  info_country_school_structure <- read_ISCED_info(country_assessment, path_ISCED_file)
  
  summary_info_school <- info_country_school_structure$summary_info_school    # DataFrame 1: level code, Learning Level, starting age, duration
  levels_grades_ages <- info_country_school_structure$levels_grades_ages     # DataFrame 2: level code, Learning Level, Year/Grade, Theoretical Start age, limit age
  
  # Adjust limit age in levels_grades_ages
  levels_grades_ages <- levels_grades_ages %>%
    dplyr::mutate(limit_age = starting_age + 2)
  
  # Compute ending ages for each educational level in summary_info_school
  summary_info_school <- summary_info_school %>%
    mutate(
      ending_age = if_else(
        level_code == max(level_code),  # Check if it's the last level
        starting_age + duration -1 ,       # For the last level
        starting_age + duration - 1     # For all other levels
      )
    )
  
  conditions <- list()
  
  # Find the starting age for primary education dynamically from the dataframe
  primary_start_age <- summary_info_school %>%
    filter(level_code == "level1") %>%  # Dynamically filter for "level1" instead of hardcoding "primary"
    pull(starting_age) %>%
    min()  # Get the minimum starting age for level1 (primary)
  
  # Loop through each row of the summary_info_school to create conditions
  for (i in seq_len(nrow(summary_info_school))) {
    level_info <- summary_info_school[i, ]
    starting_age <- level_info$starting_age
    ending_age <- level_info$ending_age
    name_level <- level_info$name_level  # Dynamically fetch the level name
    
    if (level_info$level_code == "level0") {
      # Special case for ECE (set age to 1 year before primary start)
      ece_age <- primary_start_age - 1
      if (language_assessment == "French") {
        name_with_age_range <- paste0("prescolaire – ", ece_age, " ans")
      } else {
        name_with_age_range <- paste0("ECE – ", ece_age, " years old")
      }
    } else {
      # Dynamically generate the string with the name and age range for other levels
      if (language_assessment == "French") {
        name_with_age_range <- paste0(name_level, " – ", starting_age, " jusqu'à ", ending_age, " ans")
      } else {
        name_with_age_range <- paste0(name_level, " – ", starting_age, " to ", ending_age, " years old")
      }
    }
    
    # Append the condition to the list
    conditions[[length(conditions) + 1]] <- expr(
      edu_ind_age_corrected >= !!starting_age & edu_ind_age_corrected <= !!ending_age ~ !!name_with_age_range
    )
  }
  
  # Add a default condition for any age outside the defined ranges
  conditions[[length(conditions) + 1]] <- expr(TRUE ~ NA_character_)
  
  # Apply all conditions using case_when in a single mutate to determine the school cycle with age range
  roster <- roster %>%
    mutate(edu_school_cycle_d = dplyr::case_when(!!!conditions))
  
  return(roster)
}
##------


##----------------------------------------------------------------------------------------------------------
add_edu_level_grade_indicators  <- function(roster,
                                            country_assessment = 'BFA',
                                            path_ISCED_file,
                                            education_level_grade = 'education_level_grade',
                                            edu_ind_age_corrected= 'edu_ind_age_corrected',
                                            id_col_loop = 'uuid',
                                            pnta = "pnta",
                                            dnk = "dnk"){
  if (is.null(education_level_grade)) {
    warning("education_level_grade is NULL. Returning the roster unchanged.")
    return(roster)
  }
  
  
  ind_access = 'edu_ind_access_d'
  info_country_school_structure <- read_ISCED_info(country_assessment, path_ISCED_file)
  summary_info_school <- info_country_school_structure$summary_info_school    # DataFrame 1: level code, Learning Level, starting age, duration
  levels_grades_ages <-  info_country_school_structure$levels_grades_ages     # DataFrame 2: level code, Learning Level, Year/Grade, Theoretical Start age, limit age
  
  
  # 'name_level_grade' is the new column name intended to provide a clearer description of the education levels and grades based on the school system
  roster <- roster %>%
    mutate(name_level_grade = !!sym(education_level_grade))
  roster <- roster %>%
    mutate(name_level_grade = case_when(
      name_level_grade %in% c(pnta, dnk) ~ NA_character_,
      TRUE ~ name_level_grade
    ))
  
  ## ----- levels_grades_ages manipulation
  # new column in levels_grades_ages df: limit_age = starting_age + 2. Used to calculate the overage learners
  levels_grades_ages <- levels_grades_ages %>%
    dplyr::mutate(limit_age = starting_age + 2)
  
  # Build summary_info_school equivalent
  summary_info_school <- summary_info_school %>%
    mutate(
      ending_age = if_else(
        level_code == max(level_code), # Check if it's the last level
        starting_age + duration,      # For the last level
        starting_age + duration - 1    # For all other levels
      )
    )
  
  ## left join to merge additional details from levels_grades_ages into roster based on matching 'name_level_grade' values.
  # 'anti_join' to find and isolate records in roster that do not have a corresponding match in levels_grades_ages based on 'name_level_grade'.
  # If unmatched grades are found, a warning message is then constructed, explicitly listing all unique unmatched 'name_level_grade' values found
  roster <- left_join(roster, levels_grades_ages, by = "name_level_grade") %>%
    select(all_of(id_col_loop), everything())
  
  unmatched_grades <- anti_join(roster, levels_grades_ages, by = "name_level_grade") %>%
    filter(!is.na(name_level_grade) & name_level_grade != "")
  
  if (nrow(unmatched_grades) > 0) {
    unmatched_list <- unique(unmatched_grades$name_level_grade)
    warning_message <- sprintf("A level and grade were recorded in the data that are not present in the list of levels and grades coded for the country. Please review the unmatched 'name_level_grade' values: %s",
                               paste(unmatched_list, collapse = ", "))
    warning(warning_message)
  }
  
  
  ## ------ Dynamically create info data frames for each school level based on the number of levels
  school_level_infos <- list()
  # Extract unique level codes sorted if needed
  unique_levels <- sort(unique(summary_info_school$level_code))
  # Iterate through each row of summary_info_school to populate school_level_infos
  for (i in seq_len(nrow(summary_info_school))) {
    level_info <- summary_info_school[i, ]
    level_code <- level_info$level_code
    
    # Create a list for each level with the required information
    school_level_info <- list(
      level = level_code,
      starting_age = level_info$starting_age,
      ending_age = if_else(level_info$level_code == max(summary_info_school$level_code),
                           level_info$starting_age + level_info$duration, # If it's the last level, do not subtract 1
                           level_info$ending_age) # For all other levels, use the ending_age as is
    )
    # Assign to school_level_infos using level_code as the name
    school_level_infos[[level_code]] <- school_level_info
  }
  ## ---- Ensure continuous age ranges between levels and all levels being present
  validate_age_continuity_and_levels(school_level_infos, unique_levels)
  validate_level_code_name_consistency(summary_info_school)
  validate_grade_continuity_within_levels(levels_grades_ages)
  
  ## Adjusting level_code, name_level, and grade Based on ind_access
  # If ind_access for a record is either NA or 0. the values in level_code, name_level, and grade for that record are set to NA.
  # This effectively removes specific educational details when there is no access to education, ensuring that subsequent data analysis on these columns only considers valid, relevant educational data.
  roster <- roster %>%
    mutate(across(c(level_code, name_level, grade), ~ case_when(
      ind_access == 0 | edu_ind_schooling_age_d == 0 ~ NA_character_,
      TRUE ~ .
    ))) %>%
    mutate(across(c(starting_age, limit_age), ~ case_when(
      ind_access == 0 | edu_ind_schooling_age_d == 0 ~ NA_real_,
      TRUE ~ .
    )))
  
  
  # remove level 0
  filtered_levels <- unique_levels[-1]
  true_age_col <- "edu_ind_age_corrected"  # Direct assignment
  
  
  for (level in filtered_levels) {
    # Extract info for current level
    starting_age <- as.numeric(school_level_infos[[level]]$starting_age)
    ending_age <- as.numeric(school_level_infos[[level]]$ending_age)
    
    # Define dynamic column names
    age_col_name <- paste0('edu_', level, "_age_d")
    
    # Assign values to the dynamic column
    roster[[age_col_name]] <- ifelse(is.na(roster[[true_age_col]]) | roster$edu_ind_schooling_age_d == 0,
                                     NA_integer_,
                                     ifelse(roster[[true_age_col]] >= starting_age & roster[[true_age_col]] <= ending_age, 1, 0))
  }
  
  ## ----- NUM and DEN for:  % of children (one year before the official primary school entry age) who are attending an early childhood education program or primary school
  roster <- roster %>%
    mutate(
      # Adjust age conditionally, checking for NA in true_age_col or edu_ind_schooling_age_d
      edu_level1_minus_one_age_d = if_else(is.na(!!sym(true_age_col)) | edu_ind_schooling_age_d == 0,
                                           NA_integer_,
                                           if_else(!!sym(true_age_col) == (school_level_infos[['level1']]$starting_age - 1), 1, 0)),
      
      edu_attending_level0_level1_and_level1_minus_one_age_d = ifelse(
        edu_level1_minus_one_age_d == 0,  # If edu_level1_minus_one_age_d is 0, set to NA
        NA_integer_,
        ifelse(
          edu_level1_minus_one_age_d == 1 &  is.na(level_code), 0,
          ifelse(edu_level1_minus_one_age_d == 1 &
                   (!!sym(true_age_col) == (school_level_infos[['level1']]$starting_age - 1) &
                      (level_code == 'level0' | level_code == 'level1')),
                 1, NA_integer_)
        )
      ),
      edu_attending_level1_and_level1_minus_one_age_d = ifelse(
        edu_level1_minus_one_age_d == 0,  # If edu_level1_minus_one_age_d is 0, set to NA
        NA_integer_,
        ifelse(
          edu_level1_minus_one_age_d == 1 & is.na(level_code), 0,  # If no level_code and edu_level1_minus_one_age_d is 1, set to 0
          ifelse(
            edu_level1_minus_one_age_d == 1 &
              (!!sym(true_age_col) == (school_level_infos[['level1']]$starting_age - 1) &
                 level_code == 'level0'),  # If level_code is 'level0', set to 0
            0,
            ifelse(
              edu_level1_minus_one_age_d == 1 &
                (!!sym(true_age_col) == (school_level_infos[['level1']]$starting_age - 1) &
                   level_code == 'level1'),  # If level_code is 'level1', set to 1
              1,
              NA_integer_  # Default to NA for other cases
            )
          )
        )
      )
    )
  
  
  
  
  ## ----- NUM and DEN for:  Net attendance rate (adjusted) - % of school-aged children of level school age currently attending levels
  level_numeric <- seq_along(filtered_levels)
  names(level_numeric) <- filtered_levels
  
  for (level in filtered_levels) {
    starting_age <- as.numeric(school_level_infos[[level]]$starting_age)
    ending_age <- as.numeric(school_level_infos[[level]]$ending_age)
    
    # Create dynamic column names
    higher_levels_numeric <- gsub("level", "",  paste(filtered_levels[which(filtered_levels >= level)], collapse = ""))
    attending_col_name <- paste0("edu_attending_level", higher_levels_numeric, "_and_", level, "_age_d")
    age_col_name <- paste0('edu_', level, "_age_d")
    
    # Vectorized comparison for level_code using single square brackets
    roster[[attending_col_name]] <- dplyr::case_when(
      
      # Condition 1: If the age for this level is 0, assign NA
      roster[[age_col_name]] == 0 ~ NA_integer_,
     
      
      # Condition 2: If the age for this level is 1 and no level code exists, assign 0
      roster[[age_col_name]] == 1 & is.na(roster$level_code) ~ 0,
      # Added Condition: If the level_code is "level0", always assign 0
      roster[[age_col_name]] == 1 & roster$level_code == "level0" ~ 0,
      
      # Condition 3: If the age is 1 and the level_code is the current level or higher, assign 1
      roster[[age_col_name]] == 1 &
        level_numeric[roster$level_code] >= level_numeric[[level]] ~ 1,
      
      # Condition 4: If the age is 1 and the level_code is lower than the current level, assign 0
      roster[[age_col_name]] == 1 &
        level_numeric[roster$level_code] < level_numeric[[level]] ~ 0
    )
  }
    
    
  
  
  filtered_levels_overage <- filtered_levels[filtered_levels %in% c("level1", "level2", "level3")]
  #filtered_levels_overage <- filtered_levels[filtered_levels %in% c("level1", "level2")]
  
  ## ----- NUM and DEN for: Percentage of school-aged children attending school who are at least 2 years above the intended age for grade: primary/lower secondary
  
  # Loop through each level to set flags for attendance at each level
  for (level in filtered_levels_overage) {
    accessing_level_col_name <- paste0('edu_attending_', level, '_d')
    roster[[accessing_level_col_name]] <- if_else(roster[['level_code']] == level, 1, 0, missing = NA_real_)
  }
  
  # Loop through each level to calculate the numerator for overage learners
  for (level in filtered_levels_overage) {
    overage_level_col_name <- paste0('edu_', level, "_overage_learners_d")
    
    roster[[overage_level_col_name]] <- ifelse(
      roster[['level_code']] == level, 
      ifelse((roster[[true_age_col]] - roster[['limit_age']]) >= 0, 1, 0), 
      NA
    )
  }
  
  roster <- roster %>%
    mutate(across(c(
      edu_level1_overage_learners_d,
      edu_level2_overage_learners_d
      #edu_level3_overage_learners_d,
    ),
    ~ as.numeric(.)))
  
  
  roster <- roster %>%
    mutate(across(c(edu_level1_overage_learners_d,
    ),
    ~ case_when(
      edu_ind_schooling_age_d == 0  ~ NA_real_,
      #. == 0 ~ NA_real_,  # Additional check to set 0 values to NA_real_
      TRUE ~ .
    )
    ))
  # roster <- roster %>%
  #   mutate(across(c(edu_attending_level0_level1_and_level1_minus_one_age_d,
  #                   edu_attending_level1_and_level1_minus_one_age_d,
  #                   edu_attending_level123_and_level1_age_d,
  #                   edu_attending_level23_and_level2_age_d,
  #                   edu_attending_level3_and_level3_age_d,
  #                   edu_attending_level1_d,
  #                   edu_attending_level2_d,
  #                   edu_level1_overage_learners_d,
  #                   edu_level2_overage_learners_d
  #                   ),
  #                   ~ case_when(
  #                     ind_access == 0  ~ NA_real_,
  #                     . == 0 ~ NA_real_,  # Additional check to set 0 values to NA_real_
  #                     TRUE ~ .
  #                   )
  #   ))
  
  
  
  return(roster)
}##------


##----------------------------------------------------------------------------------------------------------
add_loop_edu_barrier_d <- function(
    df,
    barrier = "edu_barrier"
){
  #----- Checks
  
  # Check if the variable is in the data frame
  if_not_in_stop(df, c(barrier), "df")
  
  # Check if new colnames are in the dataframe and throw a warning if they are
  barrier_d <- paste0('edu_barrier', "_d")
  if (barrier_d %in% colnames(df)) {
    rlang::warn(paste0(barrier_d, " already exists in df. It will be replaced."))
  }
  
  
  # Mutate with case_when to handle the condition when edu_ind_schooling_age_d == 0
  df <- df %>%
    dplyr::mutate(
      !!barrier_d := dplyr::case_when(
        edu_ind_schooling_age_d == 0 ~ NA_character_,  # If edu_ind_schooling_age_d == 0, set to NA_character_
        TRUE ~ as.character(!!rlang::sym(barrier))  # Otherwise, keep the original character value
      )
    )
  
  return(df)
}
##------

##----------------------------------------------------------------------------------------------------------
add_loop_child_gender_d <- function(
    df,
    ind_gender = "ind_gender",
    language_assessment = 'English'
){
  #----- Checks
  
  # Check if the variable is in the data frame
  if_not_in_stop(df, c(ind_gender), "df")
  
  # Check if new colnames are in the dataframe and throw a warning if they are
  child_gender_d <- 'child_gender_d'
  if (child_gender_d %in% colnames(df)) {
    rlang::warn(paste0(child_gender_d, " already exists in df. It will be replaced."))
  }
  
  # Determine the labels based on the language of assessment
  if (language_assessment == 'French') {
    female_label <- "Filles"
    male_label <- "Garcons"
  } else {
    female_label <- "Girls"
    male_label <- "Boys"
  }
  
  # Mutate with case_when to handle the gender classification
  df <- df %>%
    dplyr::mutate(
      !!child_gender_d := dplyr::case_when(
        !!rlang::sym(ind_gender) %in% c("femme", "Féminin", "feminin", "female", "Female", "woman", "girl", "2") ~ female_label,  
        !!rlang::sym(ind_gender) %in% c("homme", "Masculin", "masculin", "male", "man", "Male", "boy", "1") ~ male_label,
        TRUE ~ as.character(!!rlang::sym(ind_gender))  # Otherwise, keep the original character value
      )
    )
  
  return(df)
}
##------

##----------------------------------------------------------------------------------------------------------
add_loop_edu_optional_nonformal_d <- function(
    loop,
    edu_other_yn = NULL,
    edu_other_type = NULL,
    yes = "yes",
    no = "no",
    pnta = "pnta",
    dnk = "dnk",
    ind_schooling_age_d = "edu_ind_schooling_age_d"
){
  # Check if at least one of the variables is provided
  if (is.null(edu_other_yn) && is.null(edu_other_type)) {
    stop("At least one of 'edu_other_yn' or 'edu_other_type' must be provided.")
  }
  
  # Check if 'ind_schooling_age_d' is in the data frame
  if_not_in_stop(loop, ind_schooling_age_d, "loop")
  
  #------ Process 'edu_other_yn' if not NULL
  if (!is.null(edu_other_yn)) {
    if_not_in_stop(loop, edu_other_yn, "loop")
    
    # Recode 'edu_other_yn_d' based on conditions
    loop <- loop %>%
      dplyr::mutate(
        edu_other_yn_d = dplyr::case_when(
          !!rlang::sym(ind_schooling_age_d) == 0 ~ NA_real_,
          !!rlang::sym(ind_schooling_age_d) == 1 & !!rlang::sym(edu_other_yn) == yes ~ 1,
          !!rlang::sym(ind_schooling_age_d) == 1 & !!rlang::sym(edu_other_yn) == no ~ 0,
          !!rlang::sym(ind_schooling_age_d) == 1 & !!rlang::sym(edu_other_yn) %in% c(pnta, dnk) ~ NA_real_,
          TRUE ~ NA_real_
        )
      )
  }
  
  #------ Process 'edu_other_type' if not NULL
  if (!is.null(edu_other_type)) {
    if_not_in_stop(loop, edu_other_type, "loop")
    
    # Check if new column 'edu_other_type_d' already exists and warn if it will be replaced
    edu_other_type_d <- "edu_other_type_d"
    if (edu_other_type_d %in% colnames(loop)) {
      rlang::warn(paste0(edu_other_type_d, " already exists in df. It will be replaced."))
    }
    
    # Rename 'edu_other_type' column by appending "_d"
    loop <- loop %>%
      dplyr::mutate(
        !!edu_other_type_d := !!rlang::sym(edu_other_type)
      )
  }
  
  return(loop)
}



##----------------------------------------------------------------------------------------------------------
add_loop_edu_optional_community_modality_d <- function(
    loop,
    edu_community_modality = "edu_community_modality" ,
    ind_schooling_age_d = "edu_ind_schooling_age_d"
){
  
  # Check if the variable is in the data frame
  if_not_in_stop(loop, edu_community_modality, "loop")
  if_not_in_stop(loop, ind_schooling_age_d, "loop")
  
  
  # Check if new colnames are in the main dataframe and throw a warning if they are
  edu_community_modality_d <- paste0('edu_community_modality', "_d")
  if (edu_community_modality_d %in% colnames(loop)) {
    rlang::warn(paste0(edu_community_modality_d, " already exists in df. It will be replaced."))
  }
  #------ Rename Columns
  
  # Rename the columns by appending "_d"
  loop <- loop %>%
    dplyr::mutate(
      !!edu_community_modality_d := !!rlang::sym(edu_community_modality)
    )
  
  return(loop)
}##------
