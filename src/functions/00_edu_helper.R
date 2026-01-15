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


## ----------------------------------------------------------------------------------------------------------
read_ISCED_info <- function(country_assessment = "BFA", path_ISCED_file) {
  file_school_cycle <- path_ISCED_file ## has to be same of: https://acted.sharepoint.com/:x:/r/sites/IMPACT-Humanitarian_Planning_Prioritization/Shared%20Documents/07.%20Other%20sectoral%20resources%20for%20MSNA/01.%20Education/UNESCO%20ISCED%20Mappings_MSNAcountries_consolidated.xlsx?d=w4925184aeff547aa9687d9ce0e00dd70&csf=1&web=1&e=bFlcvr

  # file_school_cycle <- "inst/extdata/edu_ISCED/resources/UNESCO ISCED Mappings_MSNAcountries_consolidated.xlsx"  ## has to be same of: https://acted.sharepoint.com/:x:/r/sites/IMPACT-Humanitarian_Planning_Prioritization/Shared%20Documents/07.%20Other%20sectoral%20resources%20for%20MSNA/01.%20Education/UNESCO%20ISCED%20Mappings_MSNAcountries_consolidated.xlsx?d=w4925184aeff547aa9687d9ce0e00dd70&csf=1&web=1&e=bFlcvr
  country <- country_assessment
  df <- readxl::read_excel(file_school_cycle, sheet = "Compiled_Levels_Grades")

  # Convert the country input and dataframe columns to lowercase for case-insensitive comparison
  country_input_lower <- tolower(country)

  # Check if the country exists in the dataframe
  if (sum(tolower(df$`country code`) == country_input_lower | tolower(df$country) == country_input_lower) == 0) {
    warning(sprintf("The country '%s' does not exist in the dataset.", country_input_lower))
    return(NULL)
  }

  # Filter data for the specified country by code or name, case-insensitive
  country_df <- dplyr::filter(df, tolower(`country code`) == country_input_lower | tolower(country) == country_input_lower)

  # DataFrame 1: level code, Learning Level, starting age, duration
  summary_info_school <- country_df %>%
    dplyr::group_by(`level code`, `learning level`) %>%
    dplyr::summarise(
      starting_age = min(`theoretical start age`),
      duration = dplyr::n(),
      .groups = "drop"
    )

  # Adjust for level0 duration if both level0 and level1 exist
  if ("level0" %in% summary_info_school$`level code` && "level1" %in% summary_info_school$`level code`) {
    starting_age_level0 <- summary_info_school$starting_age[summary_info_school$`level code` == "level0"]
    starting_age_level1 <- summary_info_school$starting_age[summary_info_school$`level code` == "level1"]
    duration_level0 <- starting_age_level1 - starting_age_level0

    summary_info_school <- summary_info_school %>%
      mutate(duration = ifelse(`level code` == "level0", duration_level0, duration))
  }

  # DataFrame 2: level code, Learning Level, Year/Grade, Theoretical Start age, limit age
  levels_grades_ages <- country_df %>%
    dplyr::select(`level code`, `learning level`, `year-grade`, `theoretical start age`, `name -- for kobo`)

  levels_grades_ages <- levels_grades_ages %>%
    rename(
      level_code = `level code`,
      name_level = `learning level`,
      starting_age = `theoretical start age`,
      name_level_grade = `name -- for kobo`,
      grade = `year-grade`
    )

  summary_info_school <- summary_info_school %>%
    rename(
      level_code = `level code`,
      name_level = `learning level`
    )

  return(list(summary_info_school = summary_info_school, levels_grades_ages = levels_grades_ages))
}
## ------



#------------------------------------------------ Function to Ensure Continuous Age Ranges Between Levels
validate_age_continuity_and_levels <- function(school_level_infos, required_levels) {
  all_levels_df <- bind_rows(school_level_infos, .id = "level")
  # Check for missing levels
  existing_levels <- unique(all_levels_df$level)
  missing_levels <- setdiff(required_levels, existing_levels)
  if (length(missing_levels) > 0) {
    stop(sprintf("Missing required educational levels: %s", paste(missing_levels, collapse = ", ")), call. = FALSE)
  }
  # Sorting might be necessary depending on your data
  all_levels_df <- all_levels_df %>% arrange(starting_age)
  # Continue with the continuity check
  for (i in 2:nrow(all_levels_df)) {
    if (all_levels_df$starting_age[i] != all_levels_df$ending_age[i - 1] + 1) {
      stop(sprintf(
        "Age range discontinuity between levels: %s ends at %d, but %s starts at %d, check the name_level for name_consistency, too",
        all_levels_df$level[i - 1], all_levels_df$ending_age[i - 1],
        all_levels_df$level[i], all_levels_df$starting_age[i]
      ), call. = FALSE)
    }
  }
  return(TRUE)
} #--------------------------------------------------------------------------------------------------------



#------------------------------------------------ Function to Ensure Continuous Age Ranges within Levels
validate_grade_continuity_within_levels <- function(levels_grades_ages) {
  # Check for and correct any NA or "" column names.
  names(levels_grades_ages) <- ifelse(names(levels_grades_ages) == "" | is.na(names(levels_grades_ages)), paste0("V", 1:ncol(levels_grades_ages)), names(levels_grades_ages))

  levels_grades_ages <- levels_grades_ages %>%
    arrange(level_code, starting_age) %>%
    mutate(starting_age = as.numeric(starting_age)) # Ensure starting_age is numeric for comparison.

  unique_levels <- unique(levels_grades_ages$level_code)

  for (level in unique_levels) {
    if (level == "level0") {
      next # Skip level0 as requested.
    }
    grades_in_level <- filter(levels_grades_ages, level_code == level)
    # If there's only one grade in the level, skip the checks.
    if (nrow(grades_in_level) < 2) {
      next
    }

    # Direct comparison for grades with the same starting_age within a level.
    for (i in 1:(nrow(grades_in_level) - 1)) {
      for (j in (i + 1):nrow(grades_in_level)) {
        if (grades_in_level$starting_age[i] == grades_in_level$starting_age[j]) {
          stop(sprintf(
            "Error: Grades '%s' and '%s' within level %s have the same starting age of %d.",
            grades_in_level$name_level_grade[i], grades_in_level$name_level_grade[j], level, grades_in_level$starting_age[i]
          ), call. = FALSE)
        }
      }
    }

    # Check for non-consecutive starting ages.
    for (i in 2:nrow(grades_in_level)) {
      if (grades_in_level$starting_age[i] != grades_in_level$starting_age[i - 1] + 1) {
        stop(sprintf(
          "Continuity error between '%s' and '%s' in level %s: starting ages are not consecutive.",
          grades_in_level$name_level_grade[i - 1], grades_in_level$name_level_grade[i], level
        ), call. = FALSE)
      }
    }
  }

  return(TRUE)
} #--------------------------------------------------------------------------------------------------------

## ---------------------------- Function to switch label based on the language of assessment
change_label_based_on_language <- function(df, label_kobo = "label::English", language_assessment = "English") {
  # Select the appropriate label column based on the language of the assessment
  label_column <- if (language_assessment == "French") "label::french" else "label::english"

  # Check if the selected label column exists in the dataframe
  if (!label_column %in% colnames(df)) {
    stop(paste("The column", label_column, "is not found in the dataframe."))
  }

  # Rename the selected label column to the name specified by 'label_kobo'
  df <- df %>%
    dplyr::rename(!!label_kobo := !!rlang::sym(label_column))

  return(df)
} #--------------------------------------------------------------------------------------------------------


#------------------------------------------------ Function to Ensure consistency between level codes and names
validate_level_code_name_consistency <- function(school_level_infos) {
  # Ensure the input is a dataframe
  if (!is.data.frame(school_level_infos)) {
    stop("The input must be a dataframe.")
  }

  # Check if the dataframe has the required columns
  if (!all(c("level_code", "name_level") %in% names(school_level_infos))) {
    stop("Dataframe must contain the columns: 'level_code' and 'name_level'.")
  }

  # Checking for inconsistent name_level within the same level_code
  inconsistent_levels <- school_level_infos %>%
    group_by(level_code) %>%
    summarise(unique_names = n_distinct(name_level)) %>%
    filter(unique_names > 1)

  if (nrow(inconsistent_levels) > 0) {
    inconsistent_detail <- school_level_infos %>%
      group_by(level_code) %>%
      summarise(name_levels = toString(unique(name_level))) %>%
      filter(level_code %in% inconsistent_levels$level_code)

    print(inconsistent_detail)
    stop("Validation failed due to inconsistencies in level_code and name_level associations.", call. = FALSE)
  } else {
    message("All level_code values are consistently associated with a single name_level. Validation passed.")
  }
} #--------------------------------------------------------------------------------------------------------

#--------------------------------------------------------------------------------------------------------
merge_main_info_in_loop <- function(
    loop,
    main,
    id_col_loop = "uuid",
    id_col_main = "uuid",
    admin1 = "admin1",
    admin2 = NULL,
    admin3 = NULL,
    stratum = NULL,
    additional_stratum = NULL,
    weight = NULL,
    add_cols = NULL,          # character vector of extra columns to bring over
    ...,                      # or pass unnamed character vectors here
    include_regex = c("edu_community_modality", "fsl_lcsi_withdew_children") # auto-include patterns
) {
  # Collect extra columns from ... and merge with add_cols
  dots_cols <- list(...)
  if (length(dots_cols)) {
    dots_cols <- unlist(dots_cols, use.names = FALSE)
    if (!is.null(add_cols)) add_cols <- c(add_cols, dots_cols) else add_cols <- dots_cols
  }
  
  # Base columns to merge from 'main'
  cols_to_merge <- c(
    admin1, admin2, admin3, stratum, additional_stratum, weight,
    add_cols
  )
  cols_to_merge <- unique(cols_to_merge[!is.null(cols_to_merge)])
  
  # Auto-include any columns in 'main' that match the regex patterns
  if (!is.null(include_regex) && length(include_regex) > 0) {
    auto_cols <- unlist(lapply(include_regex, function(rx) {
      grep(rx, colnames(main), value = TRUE)
    }))
    cols_to_merge <- unique(c(cols_to_merge, auto_cols))
  }
  
  # Validate presence in 'main'
  missing_cols <- setdiff(cols_to_merge, colnames(main))
  if (length(missing_cols) > 0) {
    stop(paste0("The following columns are missing in 'main': ",
                paste(missing_cols, collapse = ", ")))
  }
  
  # Remove any of those columns already present in 'loop' to avoid duplicates
  existing_cols_in_loop <- intersect(cols_to_merge, colnames(loop))
  if (length(existing_cols_in_loop) > 0) {
    loop <- dplyr::select(loop, -dplyr::all_of(existing_cols_in_loop))
  }
  
  # Build the reduced 'main' for the join
  main_selected <- dplyr::select(main, dplyr::all_of(unique(c(id_col_main, cols_to_merge))))
  
  # Perform the merge
  if (identical(id_col_loop, id_col_main)) {
    merged_loop <- dplyr::left_join(loop, main_selected, by = id_col_loop)
  } else {
    # by = c("<loop id col>" = "<main id col>")
    merged_loop <- dplyr::left_join(loop, main_selected, by = setNames(id_col_main, id_col_loop))
  }
  
  merged_loop
}
#--------------------------------------------------------------------------------------------------------

#------------ labeling -----------------------------------------------------------------------------
# Function to extract label for a level
extract_label_for_level <- function(summary_info_school, level_info = NULL, label_level_code = NULL, language_assessment) {
  # If level_code is provided, filter the corresponding row from summary_info_school
  if (!is.null(label_level_code)) {
    level_info <- summary_info_school %>%
      filter(level_code == label_level_code) %>%
      slice(1) # Take the first matching row if duplicates exist
  }

  # Ensure that level_info is not empty or NULL
  if (is.null(level_info) || nrow(level_info) == 0) {
    stop("You must provide a valid level_info or level_code.")
  }

  # Extract the starting and ending ages for the level
  starting_age <- level_info$starting_age
  ending_age <- level_info$starting_age + level_info$duration - 1

  # Extract the name_level dynamically
  name_level <- level_info$name_level

  # Special case for ECE (only if level_code == "level0")
  if (level_info$level_code == "level0") {
    primary_start_age <- summary_info_school %>%
      filter(level_code == "level1") %>%
      pull(starting_age) %>%
      min() # Get the minimum starting age for primary

    ece_age <- primary_start_age - 1
    if (language_assessment == "French") {
      label <- paste0("prescolaire – ", ece_age, " ans")
    } else {
      label <- paste0("ECE – ", ece_age, " years old")
    }
  } else {
    # Generate the label with the name and age range for other levels
    if (language_assessment == "French") {
      label <- paste0(name_level, " – ", starting_age, " jusqu'à ", ending_age, " ans")
    } else {
      label <- paste0(name_level, " – ", starting_age, " to ", ending_age, " years old")
    }
  }

  return(label)
}
extract_label_for_level_ordering <- function(summary_info_school, level_info, language_assessment) {
  starting_age <- level_info$starting_age
  ending_age <- if_else(
    level_info$level_code == max(summary_info_school$level_code), # Check if it's the last level
    level_info$starting_age + level_info$duration,
    level_info$starting_age + level_info$duration - 1
  )
  name_level <- level_info$name_level

  if (level_info$level_code == "level0") {
    primary_start_age <- summary_info_school %>%
      filter(level_code == "level1") %>%
      pull(starting_age) %>%
      min()
    ece_age <- primary_start_age - 1
    if (language_assessment == "French") {
      label <- paste0("prescolaire – ", ece_age, " ans")
    } else {
      label <- paste0("ECE – ", ece_age, " years old")
    }
  } else {
    if (language_assessment == "French") {
      label <- paste0(name_level, " – ", starting_age, " jusqu'à ", ending_age, " ans")
    } else {
      label <- paste0(name_level, " – ", starting_age, " to ", ending_age, " years old")
    }
  }

  return(label)
}
#--------------------------------------------------------------------------------------------------------
