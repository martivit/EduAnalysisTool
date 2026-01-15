# Define a function to process the metadata file and return required lists
process_metadata <- function(metadata_file_path, general_sheet_name, indicator_sheet_name) {
  
  # Read the general sheet
  general_data <- read_excel(metadata_file_path, sheet = general_sheet_name)
  
  # Create a named list of countries and their languages
  country_language_list <- general_data %>%
    filter(availability == "yes") %>%
    select(country_assessment, language_assessment) %>%
    deframe()
  
  # Create a separate list of available countries
  available_countries <- general_data %>%
    filter(availability == "yes") %>%
    pull(country_assessment)
  
  # Read the indicators sheet
  indicator_data <- read_excel(metadata_file_path, sheet = indicator_sheet_name)
  variable_data <- read_excel(metadata_file_path, sheet = variables_sheet_name)
  strata_variable_data <- read_excel(metadata_file_path, sheet = strata_sheet_name)
  pop_group_data <- read_excel(metadata_file_path, sheet = pop_group_sheet_name)
  setting_data <- read_excel(metadata_file_path, sheet = setting_sheet_name)
  
  # Create a named list of countries and their languages
  admin1_list <- strata_variable_data %>%
    select(country_assessment, admin1) %>%
    deframe()
  pop_group_list <- strata_variable_data %>%
    select(country_assessment, pop_group) %>%
    deframe()
  host_list <- pop_group_data %>%
    select(country_assessment, host) %>%
    deframe()
  idp_list <- pop_group_data %>%
    select(country_assessment, IDP) %>%
    deframe()
  idp_host_list <- pop_group_data %>%
    select(country_assessment, IDP1) %>%
    deframe()
  idp_camp_list <- pop_group_data %>%
    select(country_assessment, IDP2) %>%
    deframe()
  ret_list <- pop_group_data %>%
    select(country_assessment, returnees) %>%
    deframe()
  refugee_list <- pop_group_data %>%
    select(country_assessment, refugee) %>%
    deframe()
  col1_list <-strata_variable_data %>%
    select(country_assessment, col1) %>%
    deframe()
  col2_list <-strata_variable_data %>%
    select(country_assessment, col2) %>%
    deframe()
  col3_list <-strata_variable_data %>%
    select(country_assessment, col3) %>%
    deframe()
  col4_list <-strata_variable_data %>%
    select(country_assessment, col4) %>%
    deframe()
  setting_list  <-setting_data %>%
    select(country_assessment, setting) %>%
    deframe()
  urban_list  <-setting_data %>%
    select(country_assessment, urban) %>%
    deframe()
  rural_list  <-setting_data %>%
    select(country_assessment, rural) %>%
    deframe()
  camp_list  <-setting_data %>%
    select(country_assessment, camp) %>%
    deframe()
  informal_list  <-setting_data %>%
    select(country_assessment, informal) %>%
    deframe()
  other_setting_list  <-setting_data %>%
    select(country_assessment, other) %>%
    deframe()
  
  barrier_orginal_name_list <- variable_data %>%
    select(country_assessment, barrier) %>%
    deframe()
  
  
  # Create a named list with indicator names and their labels
  indicator_label_list <- indicator_data %>%
    select(name, label) %>%
    deframe()
  
  indicators_list <- indicator_data %>%
    pull(name)
  
  # Return all the lists as a named list
  return(list(
    country_language_list = country_language_list,
    available_countries = available_countries,
    indicator_label_list = indicator_label_list,
    indicators_list = indicators_list,
    admin1_list = admin1_list,
    pop_group_list = pop_group_list,
    host_list = host_list,
    idp_list = idp_list,
    idp_host_list = idp_host_list,
    idp_camp_list = idp_camp_list,
    ret_list = ret_list,
    refugee_list = refugee_list,
    barrier_orginal_name_list = barrier_orginal_name_list,
    col1_list = col1_list,
    col2_list = col2_list,
    col3_list = col3_list,
    col4_list = col4_list,
    setting_list = setting_list,
    urban_list = urban_list,
    rural_list = rural_list,
    camp_list=camp_list,
    informal_list=informal_list,
    
    other_setting_list = other_setting_list
  ))
}

metadata_file_path <- "input_global/metadata_edu_global.xlsx"
general_sheet_name <- "general"
variables_sheet_name <- "variables"
strata_sheet_name <- "strata_variables"
indicator_sheet_name <-'indicators'
pop_group_sheet_name <-'pop_group_names'
pop_group_label_sheet_name <-'pop_group_string'
setting_sheet_name <-'setting_name'


results <- process_metadata(metadata_file_path, general_sheet_name, indicator_sheet_name)
country_language_list <-results$country_language_list
available_countries <-results$available_countries 
indicator_label_list <-  results$indicator_label_list
indicator_list <- results$indicators_list
pop_group_list <- results$pop_group_list
admin1_list <- results$admin1_list
host_list<- results$host_list
idp_list <- results$idp_list
idp_host_list<- results$idp_host_list
idp_camp_list <- results$idp_camp_list
ret_list <- results$ret_list
refugee_list <- results$refugee_list
barrier_orginal_name_list <- results$barrier_orginal_name_list
col1_list<- results$col1_list
col2_list<- results$col2_list
col3_list<- results$col3_list
col4_list<- results$col4_list
setting_list <- results$setting_list
urban_list <- results$urban_list
rural_list <- results$rural_list
camp_list<- results$camp_list
informal_list<- results$informal_list
other_setting_list<- results$other_setting_list













