

change_label <- function(
    kobo_path,
    label_survey_sheet,
    label_choices_sheet, 
    labeling_path,
    language = 'English',
    label_column_kobo = "label::french"
) {

  education_results_loop <- readRDS("output/grouped_other_education_results_loop.RDS")
  label_column_kobo_overall <- if (language == "French") "Ensemble" else "Overall"
  
  
  kobo_survey <- readxl::read_excel(kobo_path, sheet = label_survey_sheet)
  kobo_survey <- kobo_survey %>% 
    filter(if_any(everything(), ~ !is.na(.)),
           !is.na(name),
           !type %in%c("begin_group", "end_group")) 
  
  kobo_choices <- readxl::read_excel(kobo_path, sheet = label_choices_sheet)
  kobo_choices <- kobo_choices %>% 
    filter(if_any(everything(), ~ !is.na(.)),
           !is.na(name)) 
  
  update_survey <- readxl::read_excel(labeling_path, sheet = "update_survey") 
  update_survey <- update_survey %>% 
    filter(if_any(everything(), ~ !is.na(.)))
  
  overall_survey <- tibble::tibble(
    type = "select_one overall",
    name = "overall",
    !!label_column_kobo := label_column_kobo_overall
  )
  
  update_choices <- readxl::read_excel(labeling_path, sheet = "update_choices")
  update_choices <- update_choices %>% 
    filter(if_any(everything(), ~ !is.na(.)))
  
  overall_choices <- tibble::tibble(list_name = "overall",
                                    name = "overall",
                                    !!label_column_kobo := label_column_kobo_overall)
                                    
  updated_survey <- bind_rows(kobo_survey, update_survey, overall_survey)
  
  updated_choices <- bind_rows(kobo_choices, update_choices, overall_choices)
  
  education_results_loop$analysis_key %>% duplicated() %>% sum()
  
  
  
  #2 add labels
  review_kobo_labels_results <- review_kobo_labels(updated_survey,
                                                   updated_choices,
                                                   results_table = education_results_loop, 
                                                   label_column = label_column_kobo)

  duplicated_listname_label <- review_kobo_labels_results |> 
    filter(comments == "Kobo choices sheet has duplicated labels in the same list_name.")
  
  kobo_choices_fixed <- updated_choices |>
    group_by(list_name)  |> 
    mutate(!!sym(label_column_kobo) := case_when(
      list_name %in% duplicated_listname_label$list_name ~ paste(!!sym(label_column_kobo), row_number()),
      TRUE ~ !!sym(label_column_kobo)
    )) |> 
    ungroup()
  
  review_kobo_labels_results <- review_kobo_labels(updated_survey,
                                                   kobo_choices_fixed,
                                                   results_table = education_results_loop, 
                                                   label_column = label_column_kobo)
  review_kobo_labels_results
  label_dictionary <- create_label_dictionary(updated_survey, 
                                              kobo_choices_fixed, 
                                              results_table = education_results_loop, 
                                              label_column = label_column_kobo)
  
  #label_dictionary$dictionary_choices <- label_dictionary$dictionary_choices %>%
  #  mutate(name_survey = ifelse(name_survey == "edu_barrier", "edu_barrier_d", name_survey))
  
  #label_dictionary$dictionary_choices <- label_dictionary$dictionary_choices %>%
  #  mutate(across(everything(), ~ ifelse(name_survey == "edu_barrier_d", str_replace_all(., "[()]", "--"), .)))
  
  
  education_results_table_labelled <- add_label_columns_to_results_table(
    education_results_loop,
    label_dictionary
  )
  nrow(education_results_table_labelled ) == nrow(education_results_loop)
  education_results_table_labelled %>% saveRDS("output/labeled_results_table.RDS")
  
  
  
}
