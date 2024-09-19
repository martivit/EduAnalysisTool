# Read ISCED info
info_country_school_structure <- read_ISCED_info(country_assessment, path_ISCED_file)
summary_info_school <- info_country_school_structure$summary_info_school 

label_overall <- if (language_assessment == "French") "Ensemble" else "Overall"
label_female <- if (language_assessment == "French") "Filles" else "Girls"
label_male <- if (language_assessment == "French") "Garcons" else "Boys"


# Read the labeled results table and loa
education_results_table_labelled <- readRDS("output/labeled_results_table.RDS")
loa <- readxl::read_excel(loa_path, sheet = "Sheet1")

# Prepare loa_overage
loa_overage <- loa %>% 
  mutate(group_var = str_replace_all(group_var, ",", " %/% "),
         group_var = str_squish(group_var)) %>% 
  filter(overage)

# Join and filter results
education_results_table_labelled <- education_results_table_labelled %>% 
  right_join(unique(loa_overage %>% select(analysis_var, group_var, overage)))

# Filter for analysis_var_value == "1" and clean up overage column
filtered_education_results_table_labelled <- education_results_table_labelled %>% 
  filter(analysis_var_value == "1") %>% 
  select(-overage)

saveRDS(filtered_education_results_table_labelled, "output/rds_results/access_overage_results.rds")

# Read data helper and process it
data_helper_toverage <- readxl::read_excel(data_helper_table, sheet = "overage")
data_helper_toverage <- data_helper_toverage %>% as.list() %>% map(na.omit) %>% map(c)

# Create the wider table using external functions
wider_table_overage <- filtered_education_results_table_labelled %>% 
  create_education_table_group_x_var(label_overall = label_overall,
                                     label_female = label_female,
                                     label_male = label_male)

order_appearing <- c(label_overall, "ECE", summary_info_school$name_level, unique(wider_table_overage$label_group_var_value)) %>% na.omit() %>% unique()

toverage <- wider_table_overage |> 
  create_education_gt_table(data_helper = data_helper_toverage,
                            order_appearing)


toverage
create_xlsx_education_table(toverage, wb, "overage")

writeFormula(wb, "Table_of_content",
             startRow = 3,
             x = makeHyperlinkString(
               sheet = "overage", row = 1, col = 1,
               text = data_helper_toverage$title
             ))


