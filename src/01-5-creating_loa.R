
# Read the dataset with indicators and loa
loop <- readxl::read_xlsx(paste0('output/loop_edu_recorded_',country_assessment,'.xlsx'))

## ----------------------   CREATING THE LOA   ----------------------------------------------
filtered_vars <- list()
loa_filtered <- loa %>%
  dplyr::filter({
    purrr::map_lgl(analysis_var, function(var) {
      if (var %in% colnames(loop)) {
        TRUE  # Keep the variable if it exists in loop
      } else {
        filtered_vars <<- append(filtered_vars, var)  # Track the filtered variable
        FALSE  # Filter out the variable if it doesn't exist in loop
      }
    })
  })


# Print the filtered variables for debugging
if (length(filtered_vars) > 0) {
  message("Filtered out the following analysis_var as they are not present in loop columns:")
  print(filtered_vars)
}


strata_vars <- mget(strata_var_names, envir = .GlobalEnv, ifnotfound = NA) %>%
  purrr::discard(is.null) %>%
  purrr::discard(is.na)

strata_vars <- c(strata_vars, "young_adult")


model_stratum_rows <- loa_filtered %>%
  dplyr::filter(stringr::str_detect(group_var, "model_stratum"))

# Loop over each stratum variable and create modified rows
for (stratum_value in strata_vars) {
  # Create modified rows by replacing "model_stratum" with the current stratum_value
  modified_rows <- model_stratum_rows %>%
    dplyr::mutate(group_var = stringr::str_replace_all(group_var, "model_stratum", stratum_value))
  
  # Append modified rows to loa_filtered
  loa_filtered <- dplyr::bind_rows(loa_filtered, modified_rows)
}

## WGQ analysis
if (!is.null(wsg_seeing) && !is.na(wsg_seeing) &&
    !is.null(wsg_hearing) && !is.na(wsg_hearing) &&
    !is.null(wsg_walking) && !is.na(wsg_walking) &&
    !is.null(wsg_remembering) && !is.na(wsg_remembering) &&
    !is.null(wsg_selfcare) && !is.na(wsg_selfcare) &&
    !is.null(wsg_communicating) && !is.na(wsg_communicating)) {
  
  #strata_wsg <- c('wgq_dis_3', 'wgq_dis_2', 'disagg_pop_wgq_dis_3', 'disagg_pop_wgq_dis_2') ## for MMR
  strata_wsg <- c('wgq_dis_3', 'wgq_dis_2')
  
  model_stratum_rows_limited <- model_stratum_rows %>%
    dplyr::filter(!stringr::str_detect(analysis_var, "wgq"))
  
  for (stratum_value in strata_wsg) {
    # Create modified rows by replacing "model_stratum" with the current stratum_value
    modified_rows <- model_stratum_rows_limited %>%
      dplyr::mutate(group_var = stringr::str_replace_all(group_var, "model_stratum", stratum_value))
    
    # Append modified rows to loa_filtered
    loa_filtered <- dplyr::bind_rows(loa_filtered, modified_rows)
  }
}


loa_country <- loa_filtered %>%
  dplyr::filter(!stringr::str_detect(group_var, "model_stratum"))

loa_country <- loa_filtered %>%
  dplyr::filter(!stringr::str_detect(group_var, "model_stratum")) %>%
  # make sure we compare strings, and keep rows with NA safely
  dplyr::mutate(
    analysis_var = as.character(analysis_var),
    group_var    = as.character(group_var)
  ) %>%
  # drop rows where group_var includes analysis_var
  dplyr::filter(!coalesce(stringr::str_detect(group_var, stringr::fixed(analysis_var)), FALSE))%>%
  dplyr::distinct()

loa_country <- loa_country %>%
  dplyr::filter(!stringr::str_detect(group_var, "disagg_pop_access"))
loa_country %>%  write.csv(paste0('input_tool/loa_analysis_', country_assessment,'.csv'))

