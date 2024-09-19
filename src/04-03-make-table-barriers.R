

label_overall <- if (language_assessment == "French") "Ensemble" else "Overall"
label_female <- if (language_assessment == "French") "Filles" else "Girls"
label_male <- if (language_assessment == "French") "Garcons" else "Boys"

# Read the labeled results table and loa
education_results_table_labelled <- readRDS("output/labeled_results_table.RDS")
loa <- readxl::read_excel(loa_path, sheet = "Sheet1")

# Prepare loa_out_of_school
loa_out_of_school <- loa %>%
  filter(out_of_school)

# Join and filter results
education_results_table_labelled <- education_results_table_labelled %>%
  right_join(unique(loa_out_of_school %>% select(analysis_var, out_of_school)))

filtered_education_results_table_labelled <- education_results_table_labelled %>%
  filter(out_of_school, analysis_var_value != "0") %>%
  select(-out_of_school)

saveRDS(filtered_education_results_table_labelled, "output/rds_results/barriers_results.rds")


# Read data helper and process it
data_helper_t2 <- readxl::read_excel(data_helper_table, sheet = "out_of_school")
data_helper_t2 <- data_helper_t2 %>% as.list() %>% map(na.omit) %>% map(c)

# Create the wider table using external functions
x2 <- filtered_education_results_table_labelled %>%
  create_education_table_group_x_var(label_overall = label_overall,
                                     label_female = label_female,
                                     label_male = label_male)

order_appearing <- c(label_overall, "ECE", summary_info_school$name_level, unique(wider_table$label_group_var_value)) %>% na.omit() %>% unique()

t2 <- x2 |> 
  create_education_gt_table(data_helper = data_helper_t2,order_appearing)
t2
create_xlsx_education_table(t2, wb, "out_of_school")

writeFormula(wb, "Table_of_content",
             startRow = 4,
             x = makeHyperlinkString(
               sheet = "out_of_school", row = 1, col = 1,
               text = data_helper_t2$title
             ))


