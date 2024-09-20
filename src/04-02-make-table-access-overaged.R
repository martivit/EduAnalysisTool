# Read ISCED info
info_country_school_structure <- read_ISCED_info(country_assessment, path_ISCED_file)
summary_info_school <- info_country_school_structure$summary_info_school 

label_overall <- if (language_assessment == "French") "Ensemble" else "Overall"
label_female <- if (language_assessment == "French") "Filles" else "Girls"
label_male <- if (language_assessment == "French") "Garcons" else "Boys"


# Read the labeled results table and loa
education_results_table_labelled <- readRDS("output/labeled_results_table.RDS")
loa <- readxl::read_excel(loa_path, sheet = "Sheet1")

# Prepare loa_overaged
loa_overaged <- loa %>% 
  mutate(group_var = str_replace_all(group_var, ",", " %/% "),
         group_var = str_squish(group_var)) %>% 
  filter(overaged)

# Join and filter results
education_results_table_labelled <- education_results_table_labelled %>% 
  right_join(unique(loa_overaged %>% select(analysis_var, group_var, overaged)))

# Filter for analysis_var_value == "1" and clean up overaged column
filtered_education_results_table_labelled <- education_results_table_labelled %>% 
  filter(analysis_var_value == "1") %>% 
  select(-overaged)

saveRDS(filtered_education_results_table_labelled, "output/rds_results/access_overaged_results.rds")

# Read data helper and process it
data_helper_toveraged <- readxl::read_excel(data_helper_table, sheet = "overaged")
data_helper_toveraged <- data_helper_toveraged %>% as.list() %>% map(na.omit) %>% map(c)

# Create the wider table using external functions
wider_table_overaged <- filtered_education_results_table_labelled %>% 
  create_education_table_group_x_var(label_overall = label_overall,
                                     label_female = label_female,
                                     label_male = label_male)

labels_with_ages <- summary_info_school %>%
  rowwise() %>%
  mutate(label = extract_label_for_level_ordering(summary_info_school, cur_data())) %>%
  pull(label)

order_appearing <- c( label_overall, labels_with_ages,  unique(wider_table$label_group_var_value) ) %>%na.omit() %>%unique()


toveraged <- wider_table_overaged |> 
  create_education_gt_table(data_helper = data_helper_toveraged,
                            order_appearing)


toveraged
create_xlsx_education_table(toveraged, wb, "overaged")

writeFormula(wb, "Table_of_content",
             startRow = 3,
             x = makeHyperlinkString(
               sheet = "overaged", row = 1, col = 1,
               text = data_helper_toveraged$title
             ))


