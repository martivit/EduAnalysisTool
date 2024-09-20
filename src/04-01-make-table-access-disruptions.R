# Read ISCED info
info_country_school_structure <- read_ISCED_info(country_assessment, path_ISCED_file)
summary_info_school <- info_country_school_structure$summary_info_school 

label_overall <- if (language_assessment == "French") "Ensemble" else "Overall"
label_female <- if (language_assessment == "French") "Filles" else "Girls"
label_male <- if (language_assessment == "French") "Garcons" else "Boys"


# Read the labeled results table and loa
education_results_table_labelled <- readRDS("output/labeled_results_table.RDS")
loa <- readxl::read_excel(loa_path, sheet = "Sheet1")

# Prepare loa_access
loa_access <- loa %>% 
  mutate(group_var = str_replace_all(group_var, ",", " %/% "),
         group_var = str_squish(group_var)) %>% 
  filter(access)

# Join and filter results
education_results_table_labelled <- education_results_table_labelled %>% 
  right_join(unique(loa_access %>% select(analysis_var, group_var, access)))

# Filter for analysis_var_value == "1" and clean up access column
filtered_education_results_table_labelled <- education_results_table_labelled %>% 
  filter(analysis_var_value == "1") %>% 
  select(-access)

saveRDS(filtered_education_results_table_labelled, "output/rds_results/access_disruptions_results.rds")

# Read data helper and process it
data_helper_t1 <- readxl::read_excel(data_helper_table, sheet = "access")
data_helper_t1 <- data_helper_t1 %>% as.list() %>% map(na.omit) %>% map(c)

# Create the wider table using external functions
wider_table <- filtered_education_results_table_labelled %>% 
  create_education_table_group_x_var(label_overall = label_overall,
                                     label_female = label_female,
                                     label_male = label_male)

labels_with_ages <- summary_info_school %>%
  rowwise() %>%
  mutate(label = extract_label_for_level_ordering(summary_info_school, cur_data())) %>%
  pull(label)


order_appearing <- c( label_overall, labels_with_ages,  unique(wider_table$label_group_var_value) ) %>%na.omit() %>%unique()

#order_appearing <- c(label_overall, "ECE", summary_info_school$name_level, unique(wider_table$label_group_var_value)) %>% na.omit() %>% unique()

t1 <- wider_table |> 
  create_education_gt_table(data_helper = data_helper_t1,
                            order_appearing)


t1
create_xlsx_education_table(t1, wb, "access")

writeFormula(wb, "Table_of_content",
             startRow = 2,
             x = makeHyperlinkString(
               sheet = "access", row = 1, col = 1,
               text = data_helper_t1$title
             ))


