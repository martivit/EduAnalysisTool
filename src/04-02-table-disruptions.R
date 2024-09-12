library(tidyverse)
library(gt)
library(openxlsx)

source("src/functions/create_education_table_group_x_var.R")
source("src/functions/create_education_xlsx_table.R")
# Get results
education_results_table_labelled <- readRDS("output/labeled_results_table.RDS")
loa <- readxl::read_excel("input_tool/edu_analysistools_loa.xlsx", sheet = "Sheet1")
loa_access <- loa %>% 
  mutate(group_var = str_replace_all(group_var, ",", " %/% "),
         group_var = str_squish(group_var)) %>% 
  filter(access)

education_results_table_labelled <- education_results_table_labelled %>% 
  right_join(unique(loa_access %>% select(analysis_var, group_var, access))) 
# filter results
filtered_education_results_table_labelled <- education_results_table_labelled %>% 
  filter(analysis_var_value == "1" ) %>% 
  select(-access)

# gt_helper 
data_helper_t1 <- readxl::read_excel("input_tool/edu_table_helper_FR.xlsx", sheet = "access")

data_helper_t1 <- data_helper_t1 %>% as.list() %>% map(na.omit) %>% map(c)

wider_table <- filtered_education_results_table_labelled %>% 
  create_education_table_group_x_var(label_overall = "Ensemble",
                                     label_female = "Féminin / femme",
                                     label_male = "Masculin / homme") 

t1 <- wider_table |> 
  create_education_gt_table(data_helper = data_helper_t1)


t1
create_xlsx_education_table(t1, wb, "access")

writeFormula(wb, "Table_of_content",
             startRow = 2,
             x = makeHyperlinkString(
               sheet = "access", row = 1, col = 1,
               text = "access"
             ))

