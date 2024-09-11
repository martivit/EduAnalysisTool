library(tidyverse)
library(gt)
library(openxlsx)
source("src/functions/create_education_table_group_x_var.R")
source("src/functions/create_education_xlsx_table.R")
source ('src/functions/00_edu_helper.R')
source ('src/functions/00_edu_function.R')
path_ISCED_file = 'resources/UNESCO ISCED Mappings_MSNAcountries_consolidated.xlsx'


# Get results
education_results_table_labelled <- readRDS("output/labeled_results_table.RDS")
loa <- readxl::read_excel("input_tool/edu_analysistools_loa.xlsx", sheet = "Sheet1")



info_country_school_structure <- read_ISCED_info("HTI", path_ISCED_file)
summary_info_school <- info_country_school_structure$summary_info_school    # DataFrame 1: level code, Learning Level, starting age, duration
levels_grades_ages <-  info_country_school_structure$levels_grades_ages     # DataFrame 2: level code, Learning Level, Year/Grade, Theoretical Start age, limit age

label_level1 = summary_info_school$name_level[summary_info_school$level_code == "level1"]


loa_level1 <- loa %>% 
  mutate(group_var = str_replace_all(group_var, ",", " %/% "),
         group_var = str_squish(group_var)) %>% 
  filter(level1)
education_results_table_labelled <- education_results_table_labelled %>% 
  right_join(unique(loa_level1 %>% select(analysis_var,group_var, level1))) 
# filter results
filtered_education_results_table_labelled <- education_results_table_labelled %>% 
  filter(level1, 
         analysis_var_value != "0", 
         str_detect(group_var_value, label_level1)) |> 
  select(-level1)

# gt_helper 
data_helper_t4 <- readxl::read_excel("input_tool/edu_table_helper.xlsx", sheet = "level1")

data_helper_t4 <- data_helper_t4 %>% as.list() %>% map(na.omit) %>% map(c)

level1_only <- filtered_education_results_table_labelled %>% 
  filter(group_var %in% c("edu_school_cycle_d", "edu_school_cycle_d %/% ind_gender"))
level1_other <- filtered_education_results_table_labelled %>% 
  filter(!group_var %in% c("edu_school_cycle_d", "edu_school_cycle_d %/% ind_gender")) |> 
  mutate(group_var = str_remove_all(group_var, "edu_school_cycle_d( %/% )*"),
         group_var_value = str_remove_all(group_var_value, paste0(label_level1, "( %/% )*")), 
         label_group_var = str_remove_all(label_group_var, "edu_school_cycle_d( %/% )*"), 
         label_group_var_value = str_remove_all(label_group_var_value, paste0(label_level1, "( %/% )*")))
all_level1 <- rbind(level1_only, level1_other)


x4 <- all_level1 %>% 
  create_education_table_group_x_var() 

t4 <-  x4 %>%
  create_education_gt_table(data_helper = data_helper_t4)

create_xlsx_education_table(t4, wb, "level1")

writeFormula(wb, "Table_of_content",
             startRow = 5,
             x = makeHyperlinkString(
               sheet = "level1", row = 1, col = 1,
               text = "level1"
             ))
openxlsx::saveWorkbook(wb, "output/education_results.xlsx", overwrite = T)

