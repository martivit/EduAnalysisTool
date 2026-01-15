


# Function to process a single country
process_country <- function(country_code, language_assessment, path_ISCED_file, binary_data) {
  # Load ISCED structure for the country
  info_country_school_structure <- read_ISCED_info(country_code, path_ISCED_file)
  summary_info_school <- info_country_school_structure$summary_info_school
  
  # Compute the ending age for each level
  summary_info_school <- summary_info_school %>%
    mutate(ending_age = starting_age + duration - 1)
  
  # Get the primary start age
  primary_start_age <- summary_info_school %>%
    filter(level_code == "level1") %>%
    pull(starting_age) %>%
    min()
  
  # Add the label_key_output column
  summary_info_school <- summary_info_school %>%
    rowwise() %>%
    mutate(
      label_key_output = {
        if (level_code == "level0") {
          # Special case for ECE
          ece_age <- primary_start_age - 1
          if (language_assessment == "French") {
            paste0("prescolaire – ", ece_age, " ans")
          } else {
            paste0("ECE – ", ece_age, " years old")
          }
        } else {
          # General case for other levels
          if (language_assessment == "French") {
            paste0(name_level, " – ", starting_age, " jusqu'à ", ending_age, " ans")
          } else {
            paste0(name_level, " – ", starting_age, " to ", ending_age, " years old")
          }
        }
      }
    ) %>%
    ungroup()
  
  # Create a mapping dictionary
  mapping_level_country <- summary_info_school %>%
    select(label_key_output, level_code) %>%
    deframe()
  
  # Process the binary_data for the current country
  binary_data <- binary_data %>%
    rowwise() %>%
    mutate(
      group_var_value = {
        if (!is.na(group_var_value) && country == country_code) {
          updated_value <- group_var_value
          for (key in names(mapping_level_country)) {
            # Replace the key with the corresponding level_code in the group_var_value
            updated_value <- gsub(key, mapping_level_country[[key]], updated_value)
          }
          updated_value  # Return the updated value
        } else {
          group_var_value  # Keep the original for other countries or NA values
        }
      }
    ) %>%
    ungroup()
  
  return(binary_data)
}





get_percentage <- function(data, analysis_var,group_var, group_var_value, country) {
  data %>%
    filter(
      analysis_var == !!analysis_var,
      group_var_value == !!group_var_value,
      country == !!country
    ) %>%
    mutate(Percentage = stat * 100) %>%
    pull(Percentage) # Extracts the percentage value
}

get_percentage_indicator <- function(data, analysis_var, group_var, country, gender = NULL) {
  filtered_data <- data %>%
    filter(
      analysis_var == !!analysis_var,
      group_var == !!group_var,
      country == !!country
    )
  
  if (!is.null(gender)) {
    filtered_data <- filtered_data %>%
      filter(str_detect(group_var_value, gender))
  }
  
  filtered_data %>%
    mutate(Percentage = stat * 100) %>%
    pull(Percentage) # Extracts the percentage value
}

create_age_group_data <- function(data, analysis_var, group_var,gender, country) {
  # Filter the relevant rows
  filtered_data <- data %>%
    filter(
      analysis_var == !!analysis_var,  # Match the analysis_var
      group_var == !!group_var,        # Filter edu_school_cycle_d
      country == !!country             # Match the country
    )
  
  # Initialize an empty list to store results
  extracted_data <- list()
  
  # Loop over each row in the filtered data
  for (i in seq_len(nrow(filtered_data))) {
    extracted_data[[i]] <- list(
      index = i,
      group_var_value = filtered_data$group_var_value[i],
      stat = round(filtered_data$stat[i] * 100, 1) # Convert stat to percentage and round
    )
  }
  
  # Convert the list to a data frame for easier viewing
  result_df <- do.call(rbind, lapply(extracted_data, as.data.frame))
  return(result_df)
}
create_age_group_data_gender <- function(data, analysis_var, group_var, gender, country) {
  # Filter the relevant rows for the overall data
  filtered_data <- data %>%
    filter(
      analysis_var == !!analysis_var,  # Match the analysis_var
      group_var == !!group_var,        # Match the group_var
      country == !!country             # Match the country
    )
  
  # Filter the relevant rows for gender-specific data
  gender_filtered_data <- filtered_data %>%
    filter(str_detect(group_var_value, gender))  # Check if group_var_value contains the gender string
  
  # Prepare the gender-specific data frame
  gender_result_df <- gender_filtered_data %>%
    mutate(
      stat = round(stat * 100, 1),  # Convert stat to percentage and round
      gender = gender               # Add the gender label
    ) %>%
    select(group_var_value, stat, gender)  # Keep only relevant columns
  
  return(gender_result_df)
}

