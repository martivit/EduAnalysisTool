# Function to read a specific sheet and retrieve non-empty values for a country
get_country_data <- function(file_path, sheet_name, country_code) {
  # Read the sheet
  data <- read_excel(file_path, sheet = sheet_name)

  # Filter rows based on the country_code
  country_data <- data %>%
    filter(country_assessment == country_code)

  # Convert to a named list, setting any completely empty or NA values to NULL
  list_data <- lapply(country_data, function(x) {
    # Check if the column is entirely empty or contains only NAs/empty strings
    if (all(is.na(x) | x == "")) {
      return(NULL)
    } else {
      return(x)
    }
  })

  # Unlist any single-element vectors to simplify the structure
  list_data <- lapply(list_data, function(x) {
    if (length(x) == 1) x[[1]] else x
  })

  return(list_data)
}
##--
get_strata_variables <- function(file_path, sheet_name, country_code) {
  # Read the sheet
  data <- read_excel(file_path, sheet = sheet_name)

  # Filter the data based on the country_code
  country_data <- data %>%
    filter(country_assessment == country_code)

  # List of column names to be converted into variables
  columns_to_extract <- colnames(country_data)

  # Also build a plain named list (used for validation below), independent of
  # the assign() side effect, so validation doesn't depend on stale globals
  # left over from a previous country/run.
  list_data <- list()

  # Loop through each column and assign the values to variables in the global environment
  for (column_name in columns_to_extract) {
    value <- country_data[[column_name]]

    # Assign NULL if the value is empty or NA
    if (is.na(value) || value == "") {
      value <- NULL
    }

    list_data[[column_name]] <- value

    # Dynamically assign the variable in the global environment
    assign(column_name, value, envir = .GlobalEnv)
  }

  return(list_data)
}

##-- Fail-fast checks so a missing/misconfigured input_tool/01_metadata/metadata_edu.xlsx
##-- produces one clear message instead of a silent NULL or a cryptic downstream error.

check_metadata_row_exists <- function(file_path, sheet_name, country_code) {
  data <- read_excel(file_path, sheet = sheet_name)
  if (!"country_assessment" %in% names(data)) {
    stop(sprintf(
      "Metadata file '%s', sheet '%s' has no 'country_assessment' column.",
      file_path, sheet_name
    ))
  }
  if (!country_code %in% data$country_assessment) {
    stop(sprintf(
      paste0(
        "No row for country_assessment = '%s' found in sheet '%s' of '%s'.\n",
        "Add a row for '%s' to that sheet (see the 'instructions' sheet and the ",
        "'00L' example row in input_tool/01_metadata/example_metadata_edu.xlsx)."
      ),
      country_code, sheet_name, file_path, country_code
    ))
  }
  invisible(TRUE)
}

check_required_fields <- function(list_info_general, list_variables, list_strata, country_code) {
  required_general <- c(
    "dataset", "label_main_sheet", "label_edu_sheet", "language_assessment",
    "label_survey_sheet", "label_choices_sheet", "kobo_language_label"
  )
  required_variables <- c(
    "id_col_main", "id_col_loop", "survey_start_date", "school_year_start_month",
    "yes", "no", "pnta", "dnk", "weight_col", "ind_age", "ind_gender", "ind_access",
    "teacher", "hazards", "displaced", "education_level_grade", "barrier"
  )
  required_strata <- c("admin1", "admin2", "admin3", "stratum", "additional_stratum")

  missing <- character(0)
  for (field in required_general) {
    if (is.null(list_info_general[[field]])) missing <- c(missing, paste0("general$", field))
  }
  for (field in required_variables) {
    if (is.null(list_variables[[field]])) missing <- c(missing, paste0("variables$", field))
  }
  for (field in required_strata) {
    if (is.null(list_strata[[field]])) missing <- c(missing, paste0("strata_variables$", field))
  }

  if (length(missing) > 0) {
    stop(sprintf(
      paste0(
        "input_tool/01_metadata/metadata_edu.xlsx is missing %d required value(s) for country_assessment = '%s':\n",
        "  - %s\n",
        "Fill these in (see the 'instructions' sheet in input_tool/01_metadata/example_metadata_edu.xlsx) and rerun."
      ),
      length(missing), country_code, paste(missing, collapse = "\n  - ")
    ))
  }
  invisible(TRUE)
}

################################################################################################################
metadata_file_path <- "input_tool/01_metadata/metadata_edu.xlsx"
general_sheet_name <- "general"
variables_sheet_name <- "variables"
strata_sheet_name <- "strata_variables"

if (!file.exists(metadata_file_path)) {
  stop(sprintf(
    paste0(
      "Metadata file not found at '%s'.\n",
      "Create it by copying input_tool/01_metadata/example_metadata_edu.xlsx to that path ",
      "and filling in a row for country_assessment = '%s' (see its 'instructions' sheet)."
    ),
    metadata_file_path, country_assessment
  ))
}

check_metadata_row_exists(metadata_file_path, general_sheet_name, country_assessment)
check_metadata_row_exists(metadata_file_path, variables_sheet_name, country_assessment)
check_metadata_row_exists(metadata_file_path, strata_sheet_name, country_assessment)

list_info_general          <- get_country_data(metadata_file_path, general_sheet_name, country_assessment)
list_variables             <- get_country_data(metadata_file_path, variables_sheet_name, country_assessment)
list_strata_variables      <- get_strata_variables(metadata_file_path, strata_sheet_name, country_assessment)

check_required_fields(list_info_general, list_variables, list_strata_variables, country_assessment)
