library(presentresults)
library(tidyverse)
disruptions_results <- readRDS("output/rds_results/disruptions_results.rds")
# disruptions_results <- disruptions_results %>% 
#   mutate(across(tidyr::matches("^(group_var)"), \(x) if_else(str_count(x, "%/%") > 0, 
#                                                              x,
#                                                              paste(x, "overall", sep = " %/% "))),
#          across(tidyr::matches("^(label_group_var)"), \(x) if_else(str_count(x, "%/%") > 0, 
#                                                              x,
#                                                              paste(x, "Overall", sep = " %/% "))),
#          main_group_var = str_extract(group_var, "^[^%]+"),
#          main_group_var_value = str_extract(group_var_value, "^[^%]+"),
#          main_analysis_var = if_else(str_detect(analysis_var, "edu_disrupted_"), 
#                                      "edu_disrupted",
#                                      analysis_var))


disruptions_results %>% 
  group_by(analysis_type, analysis_var, main_group_var, main_group_var_value) %>% 
  group_split() -> results_var_x_group

initial_list %>% 
  map(~ .x %>%
  ggplot2::ggplot() +
  ggplot2::geom_col(
    ggplot2::aes(
      x = label_analysis_var_value,
      y = stat,
      fill = label_group_var_value
    ),
    position = "dodge"
  ) +
  ggplot2::labs(
    title = stringr::str_wrap(unique(.x$label_analysis_var), 50),
    x = stringr::str_wrap(unique(.x$label_analysis_var), 50),
    fill = stringr::str_wrap(unique(.x$label_group_var), 20)
  ) + 
  theme_impact() +
  theme_barplot()) -> aa
aa_names <- paste("output/plots/", 1:length(aa), "-plot.png") 

map2(aa_names, aa, ~ggsave(filename = .x, 
                           plot = .y,   
                           width = 8,
                           bg = "white",
                           height = 4, 
                           units = "in"))


disruptions_results %>% 
  group_by(analysis_type,  main_analysis_var, group_var_value) %>% 
  group_split() -> results_group_x_var
results_group_x_var |>
  map(~ .x |> 
  ggplot2::ggplot() +
  ggplot2::geom_col(
    ggplot2::aes(
      x = label_analysis_var,
      y = stat,
      fill = label_analysis_var
    ),
    position = "dodge") +
  ggplot2::labs(
    title = stringr::str_wrap(unique(.x$label_analysis_var), 50),
    x = stringr::str_wrap(unique(.x$label_group_var_value), 50),
    fill = stringr::str_wrap(unique(.x$main_analysis_var), 20)
  ) +
  theme_impact() +
  theme_barplot() +
  theme(axis.text.x = element_blank())
  ) -> bb
bb[[1]]
bb_names <- paste("output/plots/", 1:length(bb), "-group_x_var_plot.png") 

map2(bb_names, bb, ~ggsave(filename = .x, 
                           plot = .y,   
                           width = 8,
                           bg = "white",
                           height = 4, 
                           units = "in"))
