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
                                                label_male = "Male / man"){
  filtered_results %>% 
    select(label_analysis_var,label_analysis_var_value, label_group_var, label_group_var_value, stat, n_total) %>% 
    tidyr::separate_wider_delim(cols = all_of(c("label_group_var", "label_group_var_value")),
                                " %/% ", 
                                names_sep = " %/% ", 
                                too_few = "align_start") %>% 
    mutate(`label_group_var_value %/% 2` = ifelse(is.na(`label_group_var_value %/% 2`), 
                                                  label_overall, 
                                                  `label_group_var_value %/% 2`)) %>% 
    select(-"label_group_var %/% 2") %>%
    rename(label_group_var = `label_group_var %/% 1`,
           label_group_var_value = `label_group_var_value %/% 1`) -> x1
  
  x1  %>% 
    pivot_wider(names_from = c("label_group_var_value %/% 2","label_analysis_var","label_analysis_var_value"), 
                values_from = c("stat", "n_total"), names_glue = "{`label_group_var_value %/% 2`} %/% {label_analysis_var} %/% {label_analysis_var_value} %/% {.value}",
    ) %>%
    select("label_group_var", "label_group_var_value",
           starts_with(label_overall),
           starts_with(label_female),
           starts_with(label_male)) 
}



create_education_gt_table <- function(wide_table, data_helper) {
  gt_table <- wide_table %>%
    group_by(label_group_var) %>%
    gt()
  for (i in data_helper$overall_gender) {
    
    for (j in data_helper$profile_columns) {
      gt_table <- gt_table |> 
        gt::tab_spanner(label = j,
                        columns = matches(paste(i, j, sep = ".*")),
                        id = paste(i, j, sep = "-"))
    }
    
    gt_table <- gt_table |> 
      gt::tab_spanner(label = data_helper$profile_label,
                      columns = matches(paste(i, data_helper$profile_columns, sep = ".*")),
                      id = paste(i, "profile", sep = "-")) |> 
      gt::tab_spanner(label = data_helper$access_label,
                      columns = contains(paste(i, data_helper$access_column, sep = " %/% ")), 
                      id = paste(i, data_helper$access_column, sep = "-")) |> 
      gt::tab_spanner(label = i,columns = starts_with(i))
  }
  gt_table <-   gt_table |>
    gt::cols_label_with(everything(), fn = \(x) x |>  str_replace_all("^(.* %/% )", "")) |>
    fmt_percent(contains("stat")) %>%
    tab_header(data_helper$title)
}

