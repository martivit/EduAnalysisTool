# Read the labeled results table and loa
education_results_table_labelled <- readRDS("output/labeled_results_table.RDS")
loa <- readxl::read_excel(loa_path, sheet = "Sheet1")

# Prepare loa_level
loa_level <- loa %>% 
  mutate(group_var = str_replace_all(group_var, ",", " %/% "),
         group_var = str_squish(group_var)) %>% 
  filter(!!sym(level_table)) 

# Join and filter results
education_results_table_labelled <- education_results_table_labelled %>% 
  right_join(unique(loa_level %>% select(analysis_var, group_var, !!sym(level_table))))

# Filter for analysis_var_value == "1" and clean up access column
filtered_education_results_table_labelled <- education_results_table_labelled %>% 
  filter(!!sym(level_table), 
       analysis_var_value != "0") %>%
  select(-!!sym(level_table))

saveRDS(filtered_education_results_table_labelled, paste0("output/rds_results/",level_table,"_results.rds"))

# Read data helper and process it
data_helper_t1 <- readxl::read_excel(data_helper_table, sheet = level_table)
data_helper_t1 <- data_helper_t1 %>% as.list() %>% map(na.omit) %>% map(c)

# Create the wider table using external functions
wider_table <- filtered_education_results_table_labelled %>% 
  create_education_table_group_x_var(label_overall = label_overall,
                                     label_female = label_female,
                                     label_male = label_male)


order_appearing <- c( label_overall, labels_with_ages,  unique(wider_table$label_group_var_value) ) %>%na.omit() %>%unique()

t1 <- wider_table |> 
  create_education_gt_table(data_helper = data_helper_t1,
                            order_appearing)


t1
create_xlsx_education_table(t1, wb, level_table)

row_number <- row_number_lookup[[level_table]]

# Add a hyperlink to the table of content
writeFormula(wb, "Table_of_content",
             startRow = row_number,
             x = makeHyperlinkString(
               sheet = level_table, row = 1, col = 1,
               text = data_helper_t1$title
             ))


