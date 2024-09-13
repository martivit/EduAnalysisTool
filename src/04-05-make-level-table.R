create_level_education_table <- function(
    level_table = 'level1',
    loa_file = "input_tool/edu_analysistools_loa.xlsx",
    data_helper_file = "input_tool/edu_table_helper_FR.xlsx",
    path_ISCED_file, 
    gender_var = 'ind_gender',
    language= 'English'
) {

  label_overall <- if (language == "French") "Ensemble" else "Overall"
  label_female <- if (language == "French") "Féminin / femme" else "Female / woman"
  label_male <- if (language == "French") "Masculin / homme" else "Male / man"
  
  
  # Read the labeled results table and loa
  education_results_table_labelled <- readRDS("output/labeled_results_table.RDS")
  loa <- readxl::read_excel(loa_file, sheet = "Sheet1")
  
  # Read ISCED info
  info_country_school_structure <- read_ISCED_info(country_assessment, path_ISCED_file)
  summary_info_school <- info_country_school_structure$summary_info_school    # DataFrame 1

  label_level = summary_info_school$name_level[summary_info_school$level_code == level_table]
  
  
  # Prepare the LOA for the specific level
  loa_level <- loa %>%
    mutate(group_var = str_replace_all(group_var, ",", " %/% "),
           group_var = str_squish(group_var)) %>%
    filter(!!sym(level_table)) 
  
  
  # Join education results with LOA filtered by level_table
  education_results_table_labelled <- education_results_table_labelled %>%
    right_join(unique(loa_level %>% select(analysis_var, group_var, !!sym(level_table))))
  
  
  # Filter results
  filtered_education_results_table_labelled <- education_results_table_labelled %>%
    filter(!!sym(level_table), 
           analysis_var_value != "0", 
           str_detect(group_var_value, label_level)) %>%
    select(-!!sym(level_table))
  
  # Read data helper and process it
  data_helper_t4 <- readxl::read_excel(data_helper_file, sheet = level_table)
  data_helper_t4 <- data_helper_t4 %>% as.list() %>% map(na.omit) %>% map(c)
  
  # Separate level table data
  level_table_only <- filtered_education_results_table_labelled %>%
    filter(group_var %in% c("edu_school_cycle_d", paste0("edu_school_cycle_d %/% ", gender_var)))
  
  level_table_other <- filtered_education_results_table_labelled %>%
    filter(!group_var %in% c("edu_school_cycle_d", paste0("edu_school_cycle_d %/% ", gender_var))) %>%
    mutate(group_var = str_remove_all(group_var, "edu_school_cycle_d( %/% )*"),
           group_var_value = str_remove_all(group_var_value, paste0(label_level, "( %/% )*")), 
           label_group_var = str_remove_all(label_group_var, "edu_school_cycle_d( %/% )*"), 
           label_group_var_value = str_remove_all(label_group_var_value, paste0(label_level, "( %/% )*")))
  
  # Combine both parts of the level table
  all_level_table <- rbind(level_table_only, level_table_other)
  
  
  x4 <- all_level_table %>%
    create_education_table_group_x_var(
      label_overall = label_overall,
      label_female = label_female,
      label_male = label_male
    )
  
  
  t4 <-  x4 %>%
    create_education_gt_table(data_helper = data_helper_t4)
  
  create_xlsx_education_table(t4, wb, level_table)
  
  row_number <- case_when(
    level_table == "level1" ~ 5,
    level_table == "level2" ~ 6,
    level_table == "level3" ~ 7,
    level_table == "level4" ~ 8,
    TRUE ~ NA_real_
  )
  
  
  # Add a hyperlink to the table of content
  writeFormula(wb, "Table_of_content",
               startRow = row_number,
               x = makeHyperlinkString(
                 sheet = level_table, row = 1, col = 1,
                 text = data_helper_t4$title
               ))
  
  
}
