library(tidyverse)
library(gt)
library(openxlsx)

source("src/functions/create_education_table_group_x_var.R")

# Get results
education_results_table_labelled <- readRDS("output/labeled_results_table.RDS")
loa <- readxl::read_excel("input_tool/edu_analysistools_loa.xlsx", sheet = "Sheet1")
loa_out_of_school <- loa %>% 
  filter(out_of_school)
education_results_table_labelled <- education_results_table_labelled %>% 
  right_join(unique(loa_out_of_school %>% select(analysis_var, out_of_school))) 
# filter results
filtered_education_results_table_labelled <- education_results_table_labelled %>% 
  filter(out_of_school, 
         analysis_var_value != "0") %>% 
  select(-out_of_school)


# gt_helper 
data_helper_t2 <- readxl::read_excel("input_tool/edu_table_helper.xlsx", sheet = "out_of_school")

data_helper_t2 <- data_helper_t2 %>% as.list() %>% map(na.omit) %>% map(c)
data_helper_t2$profile_columns[[2]] <- "Cannot afford education-related costs \\(e.g. tuition, supplies, transportation)"
x2 <- filtered_education_results_table_labelled %>% 
  create_education_table_group_x_var(data_helper_t2$overall_gender[1],
                                     data_helper_t2$overall_gender[2],
                                     data_helper_t2$overall_gender[3]) 


t2 <- x2 |> 
  create_education_gt_table(data_helper = data_helper_t2)
t2
create_xlsx_education_table(t2, wb, "out_of_school")

writeFormula(wb, "Table_of_content",
             startRow = 3,
             x = makeHyperlinkString(
               sheet = "out_of_school", row = 1, col = 1,
               text = "out_of_school"
             ))
