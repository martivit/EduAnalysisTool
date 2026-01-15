# Prepare loa_level
loa_level <- loa_country %>%
  mutate(
    group_var = str_replace_all(group_var, ",", " %/% "),
    group_var = str_squish(group_var)
  ) %>%
  filter(!!sym(tab_helper))

# Join and filter results
filtered_education_results_table_labelled <- education_results_table_labelled %>%
  right_join(unique(loa_level %>% select(analysis_var, group_var, !!sym(tab_helper))))

# Filter for analysis_var_value == "1" and clean up access column
filtered_education_results_table_labelled <- filtered_education_results_table_labelled %>%
  filter(
    !!sym(tab_helper),
    analysis_var_value != "0"
  ) %>%
  select(-!!sym(tab_helper))

filtered_education_results_table_labelled <- filtered_education_results_table_labelled %>%
  filter(
    !analysis_var_value %in% c("dnk", "pnta", "no", "rarely", "none")
  )

filtered_education_results_table_labelled <- filtered_education_results_table_labelled %>%
  filter(!str_detect(group_var_value, "% NA"))

filtered_education_results_table_labelled <- filtered_education_results_table_labelled %>%
  filter(label_analysis_var != 
           "G.4. During the 2025 school year, what was the **main reason [child] did not access formal school**?")


#filtered_education_results_table_labelled <- filtered_education_results_table_labelled %>%
  #filter(!str_detect(group_var_value, regex("other|pnta", ignore_case = TRUE)))

saveRDS(filtered_education_results_table_labelled, paste0("output/rds_results/", tab_helper, "_results_", country_assessment, ".rds"))

#filtered_education_results_table_labelled <- filtered_education_results_table_labelled %>% slice(1:3121)
#filtered_education_results_table_labelled <- filtered_education_results_table_labelled %>%
  #filter(str_detect(tolower(group_var), "edu_school_cycle_d"))


# 
# create_education_table_group_x_var2 <- function(filtered_results,
#                                                 label_overall = "Overall",
#                                                 label_female = "Female / woman",
#                                                 label_male = "Male / man") {
#   filtered_results %>%
#     select(label_analysis_var, label_analysis_var_value, label_group_var, label_group_var_value, stat, n_total) %>%
#     tidyr::separate_wider_delim(
#       cols = all_of(c("label_group_var", "label_group_var_value")),
#       delim = " %/% ",
#       names_sep = " %/% ",
#       too_few = "align_start"
#     ) %>%
#     mutate(`label_group_var_value %/% 2` = ifelse(is.na(`label_group_var_value %/% 2`),
#                                                   label_overall,
#                                                   `label_group_var_value %/% 2`
#     )) %>%
#     # Drop all columns with %/% 3
#     select(-matches("%/% 3")) %>%
#     rename(
#       label_group_var = `label_group_var %/% 1`,
#       label_group_var_value = `label_group_var_value %/% 1`
#     ) -> x1
#   
#   # Save intermediate result for debugging
#   saveRDS(x1, "debug_intermediate_data.rds")
#   
#   x1 %>%
#     pivot_wider(
#       names_from = c("label_group_var_value %/% 2", "label_analysis_var", "label_analysis_var_value"),
#       values_from = c("stat", "n_total"),
#       names_glue = "{`label_group_var_value %/% 2`} %/% {label_analysis_var} %/% {label_analysis_var_value} %/% {.value}"
#     ) %>%
#     select(
#       "label_group_var", "label_group_var_value",
#       starts_with(label_overall),
#       starts_with(label_female),
#       starts_with(label_male)
#     )
# }
#"G.4. During the 2025 school year, what was the **main reason [child] did not access formal school**?"


# Create the wider table using external functions
wider_table <- filtered_education_results_table_labelled %>%
  create_education_table_group_x_var(
    label_overall = label_overall,
    label_female = label_female,
    label_male = label_male
  )



if (tab_helper == "non_formal") {
  
  # 1. Convert "NULL" -> NA only in character columns
  wider_table <- wider_table %>%
    mutate(across(where(is.character), ~ na_if(., "NULL")))
  
  # 2. Figure out which columns (after the first two) we actually want to check
  cols_to_check <- names(wider_table)[-c(1, 2)]
  # remove any list-columns from this check to avoid errors
  cols_to_check <- cols_to_check[!map_lgl(wider_table[cols_to_check], is.list)]
  
  # 3. Keep rows where at least one of these columns is NOT NA
  wider_table <- wider_table %>%
    filter(if_any(all_of(cols_to_check), ~ !is.na(.)))
}

# x1 <- readRDS("debug_intermediate_data.rds")
# glimpse(x1)
# duplicates <- x1 %>%
#   group_by(
#     label_group_var, 
#     label_group_var_value, 
#     `label_group_var_value %/% 2`,
#     label_analysis_var, 
#     label_analysis_var_value
#   ) %>%
#   filter(n() > 1) %>%
#   ungroup()
# 
# # View duplicates
# print(duplicates)
# 
# duplicates %>%
#   arrange(label_group_var, label_group_var_value, label_analysis_var) %>%
#   print(n = 50)
# 
# 
# 
# x1 %>%
#   count(
#     label_group_var,
#     label_group_var_value,
#     `label_group_var_value %/% 2`,
#     label_analysis_var,
#     label_analysis_var_value
#   ) %>%
#   filter(n > 1)
# 
# 


if (tab_helper == "non_formal" && (country_assessment == "MMR" || country_assessment == "DRC")) {
  
  numeric_columns <- names(wider_table)[-c(1, 2)]  # Exclude first two columns
  
  wider_table[, numeric_columns] <- lapply(wider_table[, numeric_columns], function(col) {
    sapply(col, function(x) {
      if (is.double(x)) {
        return(x[1])  # Extract first numeric value if it's a double
      } else if (is.list(x) && length(x) == 1 && is.double(x[[1]])) {
        return(x[[1]])  # Extract from list containing one double
      } else {
        return(NA)  # Set NA if neither condition is met
      }
    })
  })
  
  
  wider_table <- wider_table[-c(49:56), ]
 

}

if ("Overall %/% % of school-aged children accessing education outside of formal schools during the 2024-2025 school year %/% always %/% stat" %in% colnames(wider_table)) {
  wider_table <- wider_table %>%
    filter(!is.na(`Overall %/% % of school-aged children accessing education outside of formal schools during the 2024-2025 school year %/% 1 %/% stat`))
}

if ("Overall %/% % of school-aged children accessing education outside of formal schools during the 2024-2025 school year %/% 1 %/% stat" %in% colnames(wider_table)) {
  wider_table <- wider_table %>%
    filter(!is.na(`Overall %/% % of school-aged children accessing education outside of formal schools during the 2024-2025 school year %/% 1 %/% stat`))
}
if ("Ensemble %/% % d'enfants accédant à l'éducation en dehors des écoles formelles %/% 1 %/% stat" %in% colnames(wider_table)) {
  print('i am here')
  wider_table <- wider_table %>%
    filter(!is.na(`Ensemble %/% % d'enfants accédant à l'éducation en dehors des écoles formelles %/% 1 %/% stat`))
}
wider_table <- wider_table[, colSums(!is.na(wider_table)) > 0]

order_appearing <- c(label_overall, labels_with_ages, unique(wider_table$label_group_var_value)) %>%
  na.omit() %>%
  unique()

t1 <- wider_table |>
  create_education_gt_table(
    data_helper = data_helper[[tab_helper]],
    order_appearing
  )

t1
create_xlsx_education_table(t1, wb, tab_helper)

if (tab_helper == 'access' || tab_helper == 'out_of_school' || tab_helper == 'overaged'){
  row_number <- row_number_lookup[[tab_helper]]
}
#

# Add a hyperlink to the table of content
writeFormula(wb, "Table_of_content",
             startRow = row_number,
             x = makeHyperlinkString(
               sheet = tab_helper, row = 1, col = 1,
               text = data_helper[[tab_helper]]$title
             )
)

