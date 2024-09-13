

create_access_education_table <- function(
    loa_file = "input_tool/edu_analysistools_loa.xlsx",
    data_helper_file = "input_tool/edu_table_helper_FR.xlsx",
    language= 'English'
) {

  label_overall <- if (language == "French") "Ensemble" else "Overall"
  label_female <- if (language == "French") "Féminin / femme" else "Female / woman"
  label_male <- if (language == "French") "Masculin / homme" else "Male / man"
  
  
  # Read the labeled results table and loa
  education_results_table_labelled <- readRDS("output/labeled_results_table.RDS")
  loa <- readxl::read_excel(loa_file, sheet = "Sheet1")
  
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
  
  # Read data helper and process it
  data_helper_t1 <- readxl::read_excel(data_helper_file, sheet = "access")
  data_helper_t1 <- data_helper_t1 %>% as.list() %>% map(na.omit) %>% map(c)
  
  # Create the wider table using external functions
  wider_table <- filtered_education_results_table_labelled %>% 
    create_education_table_group_x_var(label_overall = label_overall,
                                       label_female = label_female,
                                       label_male = label_male)
  
  t1 <- wider_table |> 
    create_education_gt_table(data_helper = data_helper_t1)
  
  
  t1
  create_xlsx_education_table(t1, wb, "access")
  
  writeFormula(wb, "Table_of_content",
               startRow = 2,
               x = makeHyperlinkString(
                 sheet = "access", row = 1, col = 1,
                 text = data_helper_t1$title
               ))
  
}
