# Function to read a specific sheet and retrieve non-empty values for a country
get_country_data <- function(file_path, sheet_name, country_code) {
  # Read the sheet
  data <- read_excel(file_path, sheet = sheet_name)
  
  # Filter rows based on the country_code
  country_data <- data %>%
    filter(country == country_code)
  
  # Remove empty columns
  country_data <- country_data %>%
    select_if(~any(!is.na(.)))
  
  # Convert the non-empty values into a list
  list_data <- lapply(country_data, function(x) ifelse(is.na(x), NULL, x))
  
  return(list_data)
}
