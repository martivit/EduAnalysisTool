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
  
  # Loop through each column and assign the values to variables in the global environment
  for (column_name in columns_to_extract) {
    value <- country_data[[column_name]]
    
    # Assign NULL if the value is empty or NA
    if (is.na(value) || value == "") {
      value <- NULL
    }
    
    # Dynamically assign the variable in the global environment
    assign(column_name, value, envir = .GlobalEnv)
  }
  
  return(TRUE)
}

################################################################################################################
metadata_file_path <- "../metadata_edu.xlsx"
general_sheet_name <- "general"
variables_sheet_name <- "variables"
strata_sheet_name <- "strata_variables"


list_info_general          <- get_country_data(metadata_file_path, general_sheet_name, country_assessment)
list_variables             <- get_country_data(metadata_file_path, variables_sheet_name, country_assessment)
get_strata_variables (metadata_file_path, strata_sheet_name, country_assessment)
