education_results_loop <- readRDS(paste0('output/grouped_other_education_results_loop_', country_assessment,'.RDS'))
label_column_kobo_overall <- if (language_assessment == "French") "Ensemble" else "Overall"

kobo_survey <- readxl::read_excel(kobo_path, sheet = label_survey_sheet)
kobo_survey <- kobo_survey %>% 
  filter(if_any(everything(), ~ !is.na(.)),
         !is.na(name),
         !type %in%c("begin_group", "end_group")) 

kobo_choices <- readxl::read_excel(kobo_path, sheet = label_choices_sheet)
kobo_choices <- kobo_choices %>% 
  filter(if_any(everything(), ~ !is.na(.)),
         !is.na(name)) 

update_survey <- readxl::read_excel(labelling_tool_path, sheet = "update_survey") 
matching_type <- kobo_survey %>%
  dplyr::filter(name == barrier) %>%
  dplyr::pull(type)  # Extract the 'type' column value for the matching row

# Step 2: Check that matching_type is found, then replace the string in updated_survey
if (!is.null(matching_type) && length(matching_type) == 1) {
  update_survey <- update_survey %>%
    dplyr::mutate(type = dplyr::if_else(
      type == "select_one edu_barrier_relabel",
      matching_type,
      type
    ))
}

matching_type_nonformal <- NULL
if (!is.null(nonformal_type) && !is.na(nonformal_type)) {
  matching_type_nonformal <- kobo_survey %>%
    dplyr::filter(name == nonformal_type) %>%
    dplyr::pull(type)
}

# Step 4: Replace "select_one edu_nonformal_type" in update_survey if matching_type_nonformal is found
if (!is.null(matching_type_nonformal) && length(matching_type_nonformal) == 1) {
  update_survey <- update_survey %>%
    dplyr::mutate(type = dplyr::if_else(
      type == "select_one edu_nonformal_type",
      matching_type_nonformal,
      type
    ))
}


update_survey <- update_survey %>% 
  filter(if_any(everything(), ~ !is.na(.)))
update_survey <- change_label_based_on_language(update_survey, label_kobo = kobo_language_label, language_assessment)

overall_survey <- tibble::tibble(
  type = "select_one overall",
  name = "overall",
  !!kobo_language_label := label_column_kobo_overall
)

update_choices <- readxl::read_excel(labelling_tool_path, sheet = "update_choices")
update_choices <- update_choices %>% 
  filter(if_any(everything(), ~ !is.na(.)))
update_choices <- change_label_based_on_language(update_choices, label_kobo = kobo_language_label, language_assessment)

overall_choices <- tibble::tibble(list_name = "overall",
                                  name = "overall",
                                  !!kobo_language_label := label_column_kobo_overall)
                                  
updated_survey <- bind_rows(kobo_survey, update_survey, overall_survey)

updated_choices <- bind_rows(kobo_choices, update_choices, overall_choices)

education_results_loop$analysis_key %>% duplicated() %>% sum()

#2 add labels
review_kobo_labels_results <- review_kobo_labels(updated_survey,
                                                 updated_choices,
                                                 results_table = education_results_loop, 
                                                 label_column = kobo_language_label)

duplicated_listname_label <- review_kobo_labels_results |> 
  filter(comments == "Kobo choices sheet has duplicated labels in the same list_name.")

kobo_choices_fixed <- updated_choices |>
  group_by(list_name)  |> 
  mutate(!!sym(kobo_language_label) := case_when(
    list_name %in% duplicated_listname_label$list_name ~ paste(!!sym(kobo_language_label), row_number()),
    TRUE ~ !!sym(kobo_language_label)
  )) |> 
  ungroup()

review_kobo_labels_results <- review_kobo_labels(updated_survey,
                                                 kobo_choices_fixed,
                                                 results_table = education_results_loop, 
                                                 label_column = kobo_language_label)

type_debug <- updated_survey %>% 
  mutate(row_id = row_number()) %>% 
  tidyr::separate_wider_delim(
    type,
    delim = " ",
    names = c("q_type", "list_name"),
    too_many = "debug",   # <— this is the important part
    too_few  = "debug"
  )


label_dictionary <- create_label_dictionary(updated_survey, 
                                            kobo_choices_fixed, 
                                            results_table = education_results_loop, 
                                            label_column = kobo_language_label)

education_results_table_labelled <- add_label_columns_to_results_table(
  education_results_loop,
  label_dictionary
)
nrow(education_results_table_labelled ) == nrow(education_results_loop)
education_results_table_labelled %>% saveRDS(paste0("output/labeled_results_table_",country_assessment,".RDS"))


  

