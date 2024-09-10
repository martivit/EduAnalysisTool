library(tidyverse)
library(gt)
library(openxlsx)

# Get results
education_results_table_labelled <- readRDS("outputs/labeled_results_table.RDS")
loa <- readxl::read_excel("inputs/edu_analysistools_loa.xlsx", sheet = "Sheet1")

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

# gt_helper 
data_helper_t3 <- readxl::read_excel("inputs/edu_table_helper.xlsx", sheet = "ece")

data_helper_t3 <- data_helper_t3 %>% as.list() %>% map(na.omit) %>% map(c)

ece_only <- filtered_education_results_table_labelled %>% 
  filter(group_var %in% c("edu_school_cycle_d", "edu_school_cycle_d %/% ind_gender"))
ece_other <- filtered_education_results_table_labelled %>% 
  filter(!group_var %in% c("edu_school_cycle_d", "edu_school_cycle_d %/% ind_gender")) |> 
  mutate(group_var = str_remove_all(group_var, "edu_school_cycle_d( %/% )*"),
         group_var_value = str_remove_all(group_var_value, "ECE( %/% )*"), 
         label_group_var = str_remove_all(label_group_var, "edu_school_cycle_d( %/% )*"), 
         label_group_var_value = str_remove_all(label_group_var_value, "ECE( %/% )*"))
all_ece <- rbind(ece_only, ece_other)
x3 <- all_ece |> 
  create_education_table_group_x_var() 

t3 <- x3 |> 
  create_education_gt_table(data_helper = data_helper_t3)
t3

create_xlsx_education_table(t3, wb, "ece")

writeFormula(wb, "Table_of_content",
             startRow = 4,
             x = makeHyperlinkString(
               sheet = "ece", row = 1, col = 1,
               text = "ece"
             ))

