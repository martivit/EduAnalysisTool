#' Create a wide table with Overall, female and male as columns
#'
#' @param filtered_results results table filtered for value of interest
#' @param label_overall Label for overall group, default is "Overall"
#' @param label_female Label for female group, default is "Female / woman"
#' @param label_male Label for male group, default is "Male / man"
#'
#' @return A wide table with rows groups, columns the variables for the overall groups, female and
#' male.
#' @export
#'
#' @examples
create_education_table_group_x_var <- function(filtered_results,
                                               label_overall = "Overall",
                                               label_female = "Female / woman",
                                               label_male = "Male / man") {
  filtered_results %>%
    select(label_analysis_var, label_analysis_var_value, label_group_var, label_group_var_value, stat, n_total) %>%
    tidyr::separate_wider_delim(
      cols = all_of(c("label_group_var", "label_group_var_value")),
      " %/% ",
      names_sep = " %/% ",
      too_few = "align_start"
    ) %>%
    mutate(`label_group_var_value %/% 2` = ifelse(is.na(`label_group_var_value %/% 2`),
      label_overall,
      `label_group_var_value %/% 2`
    )) %>%
    select(-"label_group_var %/% 2") %>%
    rename(
      label_group_var = `label_group_var %/% 1`,
      label_group_var_value = `label_group_var_value %/% 1`
    ) -> x1

  x1 %>%
    pivot_wider(
      names_from = c("label_group_var_value %/% 2", "label_analysis_var", "label_analysis_var_value"),
      values_from = c("stat", "n_total"), names_glue = "{`label_group_var_value %/% 2`} %/% {label_analysis_var} %/% {label_analysis_var_value} %/% {.value}",
    ) %>%
    select(
      "label_group_var", "label_group_var_value",
      starts_with(label_overall),
      starts_with(label_female),
      starts_with(label_male)
    )
}

create_education_gt_table <- function(wide_table, data_helper, order_appearing) {
  gt_table <- wide_table %>%
    arrange(
      factor(label_group_var_value, levels = order_appearing)
    ) |>
    group_by(label_group_var) %>%
    gt()
  
  for (i in data_helper$overall_gender) {
    for (j in data_helper$profile_columns) {
      #print(j)
      gt_table <- gt_table |>
        gt::tab_spanner(
          label = j,
          columns = matches(paste(i, j, sep = ".*")),
          id = paste(i, j, sep = "-")
        )
    }
    # # Build and print the profile pattern
    # profile_pattern <- paste(i, data_helper$profile_columns, sep = ".*")
    # print(paste("Profile pattern for", i, ":", profile_pattern))  # Debug print
    # 
    # # Build and print the access pattern
    # access_pattern <- paste(i, data_helper$access_column, sep = " %/% ")
    # print(paste("Access pattern for", i, ":", access_pattern))  # Debug print
    # 
    # # Check which columns match the patterns
    # matching_profile_columns <- colnames(wider_table)[grepl(profile_pattern, colnames(wider_table))]
    # matching_access_columns <- colnames(wider_table)[grepl(access_pattern, colnames(wider_table))]
    # 
    # print(paste("Matching profile columns for", i, ":", paste(matching_profile_columns, collapse = ", ")))  # Debug profile columns
    # print(paste("Matching access columns for", i, ":", paste(matching_access_columns, collapse = ", ")))    # Debug access columns
    # 
    # # Debug the columns that start with 'i'
    # starting_with_i <- colnames(wider_table)[startsWith(colnames(wider_table), i)]
    # print(paste("Columns starting with", i, ":", paste(starting_with_i, collapse = ", ")))  # Debug start_with columns
    # 
    # profile_pattern <- paste(i, data_helper$profile_columns, sep = ".*")  # Generates multiple patterns
    # combined_profile_pattern <- paste(profile_pattern, collapse = "|")    # Combine into a single pattern with OR
    # 
    # matching_profile_columns <- colnames(wider_table)[grepl(combined_profile_pattern, colnames(wider_table))]
    # 
    # # Similar for access columns
    # access_pattern <- paste(i, data_helper$access_column, sep = " %/% ")
    # combined_access_pattern <- paste(access_pattern, collapse = "|")
    # 
    # matching_access_columns <- colnames(wider_table)[grepl(combined_access_pattern, colnames(wider_table))]
    
    gt_table <- gt_table |>
      gt::tab_spanner(
        label = data_helper$profile_label,
        columns = matches(paste(i, data_helper$profile_columns, sep = ".*")),
        id = paste(i, "profile", sep = "-")
      ) |>
      gt::tab_spanner(
        label = data_helper$access_label,
        columns = contains(paste(i, data_helper$access_column, sep = " %/% ")),
        id = paste(i, data_helper$access_column, sep = "-")
      ) |>
      gt::tab_spanner(label = i, columns = starts_with(i))
  }
  # print("Column names before renaming:")
  # print(colnames(gt_table))
  
  # Apply the column label transformation and debug the result
  gt_table <- gt_table |>
    gt::cols_label_with(everything(), fn = \(x) {
      # Debugging each column transformation
      new_label <- x |> str_replace_all("^(.* %/% )", "")
      #print(paste("Original column label:", x, "| New column label:", new_label))
      return(new_label)
    }) |>
    
    # Apply percentage formatting and debug which columns are affected
    fmt_percent(contains("stat")) |>
    
    # Add table header and debug the title
    tab_header(title = data_helper$title)
  
  # # Debugging column names after transformation
  # print("Column names after renaming:")
  # print(colnames(gt_table))
}
