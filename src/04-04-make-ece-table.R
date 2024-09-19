
label_overall <- if (language_assessment == "French") "Ensemble" else "Overall"
label_female <- if (language_assessment == "French") "Filles" else "Girls"
label_male <- if (language_assessment == "French") "Garcons" else "Boys"

# Read the labeled results table and loa
education_results_table_labelled <- readRDS("output/labeled_results_table.RDS")
loa <- readxl::read_excel(loa_path, sheet = "Sheet1")


loa_ece <- loa %>%
  mutate(group_var = str_replace_all(group_var, ",", " %/% "),
         group_var = str_squish(group_var)) %>% 
  filter(ece)
education_results_table_labelled <- education_results_table_labelled %>% 
  right_join(unique(loa_ece %>% select(analysis_var,group_var, ece))) 
# filter results
filtered_education_results_table_labelled <- education_results_table_labelled %>% 
  filter(ece, 
         analysis_var_value != "0", 
         str_detect(group_var_value, "ECE")) |> 
  select(-ece)

saveRDS(filtered_education_results_table_labelled, "output/rds_results/ece_results.rds")

# gt_helper 
data_helper_t3 <- readxl::read_excel(data_helper_table, sheet = "ece")

data_helper_t3 <- data_helper_t3 %>% as.list() %>% map(na.omit) %>% map(c)

label_group_ece = paste0("edu_school_cycle_d %/% ",'child_gender_d')

ece_only <- filtered_education_results_table_labelled %>% 
  filter(group_var %in% c("edu_school_cycle_d", label_group_ece))
ece_other <- filtered_education_results_table_labelled %>% 
  filter(!group_var %in% c("edu_school_cycle_d", label_group_ece)) |> 
  mutate(group_var = str_remove_all(group_var, "edu_school_cycle_d( %/% )*"),
         group_var_value = str_remove_all(group_var_value, "ECE( %/% )*"), 
         label_group_var = str_remove_all(label_group_var, "edu_school_cycle_d( %/% )*"), 
         label_group_var_value = str_remove_all(label_group_var_value, "ECE( %/% )*"))
all_ece <- rbind(ece_only, ece_other)

saveRDS(all_ece, "output/rds_results/ece_results.rds")

x3 <- all_ece |> 
  create_education_table_group_x_var(label_overall = label_overall,
                                     label_female = label_female,
                                     label_male = label_male)
order_appearing <- c(label_overall, "ECE", summary_info_school$name_level, unique(wider_table$label_group_var_value)) %>% na.omit() %>% unique()

t3 <- x3 |> 
  create_education_gt_table(data_helper = data_helper_t3,order_appearing)
t3

create_xlsx_education_table(t3, wb, "ece")

writeFormula(wb, "Table_of_content",
             startRow = 5,
             x = makeHyperlinkString(
               sheet = "ece", row = 1, col = 1,
               text = data_helper_t3$title
             ))
