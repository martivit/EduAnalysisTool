library(tidyverse)
library(gt)
library(openxlsx)

# Get results
education_results_table_labelled <- readRDS("outputs/labeled_results_table.RDS")
loa <- readxl::read_excel("inputs/edu_analysistools_loa.xlsx", sheet = "Sheet1")

loa_ece <- loa %>% 
  filter(ece)
education_results_table_labelled <- education_results_table_labelled %>% 
  right_join(unique(loa_ece %>% select(analysis_var, ece))) 
# filter results
filtered_education_results_table_labelled <- education_results_table_labelled %>% 
  filter(ece, 
         analysis_var_value != "0", 
         str_detect(group_var,"edu_school_cycle_d", negate = T)) %>% 
  select(-ece)

# gt_helper 
data_helper_t3 <- readxl::read_excel("inputs/edu_table_helper.xlsx", sheet = "ece")

data_helper_t3 <- data_helper_t3 %>% as.list() %>% map(na.omit) %>% map(c)

x3 <- filtered_education_results_table_labelled %>% 
  create_education_table_group_x_var(data_helper$top_spanner[1],
                                      data_helper$top_spanner[2],
                                      data_helper$top_spanner[3]) 

t3 <- x3 |> 
  create_education_gt_table(data_helper = data_helper_t3)


create_xlsx_education_table(t3, wb, "ece")

writeFormula(wb, "Table_of_content",
             startRow = 4,
             x = makeHyperlinkString(
               sheet = "ece", row = 1, col = 1,
               text = "ece"
             ))

