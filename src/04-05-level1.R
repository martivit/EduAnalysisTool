library(tidyverse)
library(gt)
library(openxlsx)

# Get results
education_results_table_labelled <- readRDS("outputs/labeled_results_table.RDS")
loa <- readxl::read_excel("inputs/edu_analysistools_loa.xlsx", sheet = "Sheet1")

loa_level1 <- loa %>% 
  filter(level1)
education_results_table_labelled <- education_results_table_labelled %>% 
  right_join(unique(loa_level1 %>% select(analysis_var, level1))) 
# filter results
filtered_education_results_table_labelled <- education_results_table_labelled %>% 
  filter(level1, 
         analysis_var_value != "0", 
         str_detect(group_var,"edu_school_cycle_d", negate = T)) %>% 
  select(-level1)

# gt_helper 
data_helper_t4 <- readxl::read_excel("inputs/edu_table_helper.xlsx", sheet = "level1")

data_helper_t4 <- data_helper_t4 %>% as.list() %>% map(na.omit) %>% map(c)

x4 <- filtered_education_results_table_labelled %>% 
  create_education_table_group_x_var(data_helper$top_spanner[1],
                                      data_helper$top_spanner[2],
                                      data_helper$top_spanner[3]) 

t4 <-  x4 %>%
  create_education_gt_table(data_helper = data_helper_t4)

create_xlsx_education_table(t4, wb, "level1")

writeFormula(wb, "Table_of_content",
             startRow = 5,
             x = makeHyperlinkString(
               sheet = "level1", row = 1, col = 1,
               text = "level1"
             ))
openxlsx::saveWorkbook(wb, "outputs/education_results.xlsx", overwrite = T)

