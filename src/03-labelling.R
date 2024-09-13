library(tidyverse)
library(presentresults)

education_results_loop <- readRDS("output/grouped_other_education_results_loop.RDS")

kobo_survey <- readxl::read_excel("input_data/HTI_kobo.xlsx", sheet = "survey")
kobo_survey <- kobo_survey %>% 
  filter(if_any(everything(), ~ !is.na(.)),
         !is.na(name),
         !type %in%c("begin_group", "end_group")) 

kobo_choices <- readxl::read_excel("input_data/HTI_kobo.xlsx", sheet = "choices")
kobo_choices <- kobo_choices %>% 
  filter(if_any(everything(), ~ !is.na(.)),
         !is.na(name)) 

update_survey <- readxl::read_excel("input_tool/edu_indicator_labelling.xlsx", sheet = "update_survey") 
update_survey <- update_survey %>% 
  filter(if_any(everything(), ~ !is.na(.)))

overall_survey <- tibble::tibble(type = "select_one overall",
                                 name = "overall",
                                 `label::french` = "Ensemble")

update_choices <- readxl::read_excel("input_tool/edu_indicator_labelling.xlsx", sheet = "update_choices")
update_choices <- update_choices %>% 
  filter(if_any(everything(), ~ !is.na(.)))

overall_choices <- tibble::tibble(list_name = "overall",
                                  name = "overall",
                                  `label::french` = "Ensemble")

updated_survey <- bind_rows(kobo_survey, update_survey, overall_survey)

# updated_survey <- updated_survey %>% mutate(name = if_else(name == "edu_barrier", "edu_barrier_d", name))
updated_choices <- bind_rows(kobo_choices, update_choices, overall_choices)

education_results_loop$analysis_key %>% duplicated() %>% sum()

#2 add labels
review_kobo_labels_results <- review_kobo_labels(updated_survey,
                                                 updated_choices,
                                                 results_table = education_results_loop, 
                                                 label_column = "label::french")
review_kobo_labels_results

duplicated_listname_label <- review_kobo_labels_results |> 
  filter(comments == "Kobo choices sheet has duplicated labels in the same list_name.")

kobo_choices_fixed <- updated_choices |>
  group_by(list_name)  |> 
  mutate(`label::french` = case_when(
    list_name %in% duplicated_listname_label$list_name ~ paste(`label::french`, row_number()),
    TRUE ~ `label::french`
  ))  |> 
  ungroup()

review_kobo_labels_results <- review_kobo_labels(updated_survey,
                                                 kobo_choices_fixed,
                                                 results_table = education_results_loop, 
                                                 label_column = "label::french")
review_kobo_labels_results
label_dictionary <- create_label_dictionary(updated_survey, 
                                            kobo_choices_fixed, 
                                            results_table = education_results_loop, 
                                            label_column = "label::french")


education_results_table_labelled <- add_label_columns_to_results_table(
  education_results_loop,
  label_dictionary
)
nrow(education_results_table_labelled ) == nrow(education_results_loop)
education_results_table_labelled %>% saveRDS("output/labeled_results_table.RDS")

