
# Read the dataset with indicators and loa
loop <- read_xlsx("output/loop_edu_recorded.xlsx")

filtered_vars <- list()

# Loop over the analysis_var in loa and check if it exists in the column names of loop
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

# Add Overall variable to help in data viz
loop$overall <- "overall"


# Convert loop to survey design
design_loop <- loop |>
  as_survey_design(weights = weight_col)

results_loop_weigthed <- create_analysis(
  design_loop,
  loa = loa_filtered,
  sm_separator =  ".")

results_loop_weigthed$results_table %>%  write.csv('output/analysis_key_output.csv')
results_loop_weigthed %>%
  saveRDS("output/analysis_key_output.RDS")


# group other select ones.
vars_to_group <- results_loop_weigthed$results_table %>% 
  group_by(analysis_type,analysis_var,group_var, group_var_value) %>% 
  mutate(rank = dplyr::dense_rank(desc(stat)),
         other_to_group = analysis_var_value == "other" | rank > 5 ) %>%
  ungroup() %>%
  filter(group_var == "overall", 
         analysis_var %in% c("edu_barrier_d"),
         other_to_group) %>% 
  select(analysis_var, analysis_var_value, other_to_group) %>% unique()


to_group <- results_loop_weigthed$results_table %>% 
  left_join(vars_to_group) %>% 
  filter(other_to_group) %>% 
  select(-other_to_group)
to_keep <- results_loop_weigthed$results_table %>% 
  left_join(vars_to_group, ) %>% 
  filter(is.na(other_to_group)) %>% 
  select(-other_to_group)

(nrow(to_group) + nrow(to_keep) )== nrow(results_loop_weigthed$results_table)

summary_other <- to_group %>% 
  group_by(analysis_type,analysis_var,group_var, group_var_value) %>% 
  summarise(stat = sum(stat),
            n_total = max(n_total)) %>% 
  mutate(analysis_var_value = "other")

summary_other %>% 
  separate_wider_delim(cols = c("group_var", "group_var_value"),delim = " %/% ",cols_remove = F,names_sep = "___", too_few = "align_start") %>% 
  mutate(analysis_key = paste(analysis_type, 
                              "@/@",
                              analysis_var,
                              "%/%",
                              analysis_var_value,
                              "@/@",
                              group_var___1, 
                              "%/%",
                              group_var_value___1,
                              "-/-",
                              group_var___2,
                              "%/%",
                              group_var_value___2),
         analysis_key = str_remove_all(analysis_key, " -/- NA %/% NA")) %>%
  select(-all_of(c("group_var___1","group_var___2", "group_var_value___1","group_var_value___2"))) %>% 
  rename(group_var = group_var___group_var, 
         group_var_value = group_var_value___group_var_value)->summary_other

grouped_other_education_results_loop<- to_keep %>% 
  bind_rows(summary_other) |> 
  ungroup() 

# Ensure no duplicates in analysis_key
duplicated_keys <- grouped_other_education_results_loop$analysis_key %>% duplicated() %>% sum()
if (duplicated_keys > 0) {
  message("There are ", duplicated_keys, " duplicates in analysis keys.")
}

grouped_other_education_results_loop %>% saveRDS("output/grouped_other_education_results_loop.RDS")

  

