# Get correct label level
if (tab_helper == "ece") {
  label_level <- extract_label_for_level(summary_info_school, label_level_code = "level0", language_assessment = language_assessment)
} else {
  label_level <- extract_label_for_level(summary_info_school, label_level_code = tab_helper, language_assessment = language_assessment)
}

# Prepare the LOA for the specific level
loa_level <- loa_country %>%
  mutate(
    group_var = str_replace_all(group_var, ",", " %/% "),
    group_var = str_squish(group_var)
  ) %>%
  filter(!!sym(tab_helper))


# Join education results with LOA filtered by tab_helper
filtered_education_results_table_labelled <- education_results_table_labelled %>%
  right_join(unique(loa_level %>% select(analysis_var, group_var, !!sym(tab_helper))))


# Filter results
filtered_education_results_table_labelled <- filtered_education_results_table_labelled %>%
  filter(
    !!sym(tab_helper),
    analysis_var_value != "0",
    str_detect(group_var_value, label_level)
  ) %>%
  select(-!!sym(tab_helper))

# Separate level table data
tab_helper_only <- filtered_education_results_table_labelled %>%
  filter(group_var %in% c("edu_school_cycle_d", paste0("edu_school_cycle_d %/% ", "child_gender_d")))

tab_helper_other <- filtered_education_results_table_labelled %>%
  filter(!group_var %in% c("edu_school_cycle_d", paste0("edu_school_cycle_d %/% ", "child_gender_d"))) %>%
  mutate(
    group_var = str_remove_all(group_var, "edu_school_cycle_d( %/% )*"),
    group_var_value = str_remove_all(group_var_value, paste0(label_level, "( %/% )*")),
    label_group_var = str_remove_all(label_group_var, paste0(label_edu_school_cycle, "( %/% )*")),
    label_group_var_value = str_remove_all(label_group_var_value, paste0(label_level, "( %/% )*"))
  )

# Combine both parts of the level table
all_tab_helper <- rbind(tab_helper_only, tab_helper_other)

saveRDS(all_tab_helper, paste0("output/rds_results/", tab_helper, "_results_", country_assessment, ".rds"))

x4 <- all_tab_helper %>%
  create_education_table_group_x_var(
    label_overall = label_overall,
    label_female = label_female,
    label_male = label_male
  )

order_appearing <- c(label_overall, label_level, unique(wider_table$label_group_var_value)) %>%
  na.omit() %>%
  unique()

t4 <- x4 %>%
  create_education_gt_table(data_helper = data_helper[[tab_helper]], order_appearing)

create_xlsx_education_table(t4, wb, tab_helper)
t4

row_number <- row_number_lookup[[tab_helper]]

# Add a hyperlink to the table of content
writeFormula(wb, "Table_of_content",
  startRow = row_number,
  x = makeHyperlinkString(
    sheet = tab_helper, row = 1, col = 1,
    text = data_helper[[tab_helper]]$title
  )
)
