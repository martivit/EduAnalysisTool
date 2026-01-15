# Read results
disruptions_results <- readRDS(results_filtered)

# Adds the grouping variables for the graphs
disruptions_results_for_graphs <- disruptions_results %>%
  tidyr::separate_wider_delim(
    cols = all_of(c("label_group_var", "label_group_var_value")),
    " %/% ",
    names_sep = "_",
    too_few = "align_start"
  ) %>%
  mutate(
    label_group_var_2 = if_else(is.na(label_group_var_2), ind_gender, label_group_var_2),
    label_group_var_value_2 = if_else(is.na(label_group_var_value_2), label_overall, label_group_var_value_2)
  ) %>%
  mutate(main_analysis_variable = case_when(
    label_analysis_var == data_helper[[tab_helper]]$access_column ~ "Access",
    label_analysis_var %in% data_helper[[tab_helper]]$profile_columns ~ "Profile - dummy type",
    label_analysis_var_value %in% data_helper[[tab_helper]]$profile_columns ~ "Profile - choice type"
  ))

# Turn into factor to control the ordering
order_appearing <- c(label_overall, labels_with_ages, unique(disruptions_results_for_graphs$label_group_var_value_1)) %>%
  na.omit() %>%
  unique()
gender_order <- c(label_overall, label_female, label_male)

disruptions_results_for_graphs <- disruptions_results_for_graphs %>%
  mutate(
    label_analysis_var = factor(label_analysis_var, levels = unique(label_analysis_var)),
    label_analysis_var_value = factor(label_analysis_var_value, levels = unique(label_analysis_var_value)),
    label_group_var_1 = factor(label_group_var_1, levels = unique(label_group_var_1)),
    label_group_var_value_1 = factor(label_group_var_value_1, levels = order_appearing),
    label_group_var_2 = factor(label_group_var_2, levels = unique(label_group_var_2)),
    label_group_var_value_2 = factor(label_group_var_value_2, levels = gender_order),
    label_information = case_when(
      main_analysis_variable == "Profile - choice type" ~ label_analysis_var_value,
      TRUE ~ label_analysis_var
    )
  )

## ---------
stratum_value <- get("stratum", envir = .GlobalEnv)
#additional_stratum_value <- get("additional_stratum", envir = .GlobalEnv)

# stratum_value and additional_stratum_value are not NULL
include_values <- c()
if (!is.null(stratum_value)) include_values <- c(include_values, stratum_value)
#if (!is.null(additional_stratum_value)) include_values <- c(include_values, additional_stratum_value)

# Check if all wsg_* variables are not NULL or NA, then add strata_wsg if condition is met
if (!is.null(wsg_seeing) && !is.na(wsg_seeing) &&
    !is.null(wsg_hearing) && !is.na(wsg_hearing) &&
    !is.null(wsg_walking) && !is.na(wsg_walking) &&
    !is.null(wsg_remembering) && !is.na(wsg_remembering) &&
    !is.null(wsg_selfcare) && !is.na(wsg_selfcare) &&
    !is.null(wsg_communicating) && !is.na(wsg_communicating)) {
  
  strata_wsg <- c('wgq_dis_3', 'wgq_dis_2')
  include_values <- c(include_values, strata_wsg)
}

# Filter to keep only rows where group_var contains any value from include_values
no_admin_level <- disruptions_results_for_graphs %>%
  filter(str_detect(group_var, paste(include_values, collapse = "|")))

no_admin_level <- no_admin_level %>%
  filter(!str_detect(group_var, "prov_urbanity"))
no_admin_level <- no_admin_level %>%
  filter(!str_detect(group_var, "region_urbanity"))
##--------


# Type 1 plots - Indicators x 3 gender x 1 dissag
## Split by analysis var and group variable 1
type1_group_by_results <- no_admin_level |>
  group_by(analysis_type, label_information, label_group_var_1, label_group_var_value_1)
type1_group_id <- type1_group_by_results |>
  group_keys()
type1_group_results <- type1_group_by_results |>
  group_split()


## Creates the plots
type1_plots <- type1_group_results %>%
  map(~ .x %>%
        ggplot2::ggplot(ggplot2::aes(
          x = label_group_var_value_2,
          y = stat,
          fill = label_group_var_value_2
        )) +
        ggplot2::geom_col(
          position = "dodge"
        ) +
        geom_text(aes(label = scales::percent(stat)), vjust = -0.5) +
        theme_impact() +
        theme_barplot() +
        ggplot2::labs(
          title = stringr::str_wrap(
            paste(
              unique(.x$label_information),
              "%/%",
              unique(.x$label_group_var_value_1)
            ),
            50
          ),
          x = stringr::str_wrap(unique(.x$label_information), 50),
          fill = stringr::str_wrap(unique(.x$label_group_var_2), 20)
        ))

## Create a naming vector to save the plots
type1_file_names <- paste0("output/plots_",country_assessment,"/", tab_helper, "/type_1/", 1:length(type1_plots), "type_1_plot.png")

## Save the plots
map2(type1_file_names, type1_plots, ~ ggsave(
  filename = .x,
  plot = .y,
  width = 8,
  bg = "white",
  height = 4,
  units = "in"
))

## Write plots index
type1_group_id %>% write.csv(paste0("output/plots_",country_assessment,"/", tab_helper, "/type_1/", "type_1_index.csv"))

# Type 2 plots - Profile per gender
## Split by label_group_var_value_1 and label_group_var_value_2
disruptions_only <- no_admin_level %>%
  filter(str_detect(main_analysis_variable, "Profile"))

disruptions_only <- disruptions_only[!(disruptions_only$analysis_var %in% c("e_incident_trajet", "e_incident_ecol")), ]

type2_group_by_results <- disruptions_only |>
  group_by(analysis_type, label_group_var_value_1, label_group_var_value_2)
type2_group_id <- type2_group_by_results |>
  group_keys()
type2_group_results <- type2_group_by_results |>
  group_split()

if (tab_helper == "out_of_school") {
  palette_to_use <- impact_palettes$tol_palette
} else {
  palette_to_use <- impact_palettes$reach_palette
}
type2_plots <- type2_group_results |>
  map(~ .x %>%
        ggplot2::ggplot(ggplot2::aes(
          x = label_information,
          y = stat,
          fill = str_wrap(label_information, width = 20)
        )) +
        ggplot2::geom_col(
          position = "dodge"
        ) +
        geom_text(aes(label = scales::percent(x = stat, accuracy = 1L)), vjust = -0.5) +
        ggplot2::labs(
          title = stringr::str_wrap(
            paste(
              "Profile for ",
              unique(.x$group_var_value)
            ),
            50
          ),
          fill = stringr::str_wrap(unique(.x$main_analysis_variable), 20),
          x = element_blank()
        ) +
        theme_impact() +
        theme_barplot(palette_to_use) +
        theme(
          axis.line = element_blank(),
          axis.text.x = element_blank()
        ))
## Create a naming vector to save the plots
type2_file_names <- paste0("output/plots_",country_assessment,"/", tab_helper, "/type_2/", 1:length(type2_plots), "type_2_plot.png")

## Save the plots
map2(type2_file_names, type2_plots, ~ ggsave(
  filename = .x,
  plot = .y,
  width = 8,
  bg = "white",
  height = 4,
  units = "in"
))
## Write plots index
type2_group_id %>% write.csv(paste0("output/plots_",country_assessment,"/", tab_helper, "/type_2/", "type_2_index.csv"))

# Type 3 plots -  - Indicators x dissag x 1 gender
## Split by label_group_var_value_1 and label_group_var_value_2
type3_group_by_results <- no_admin_level |>
  group_by(analysis_type, label_information, label_group_var_1, label_group_var_value_2)
type3_group_id <- type3_group_by_results |>
  group_keys()
type3_group_results <- type3_group_by_results |>
  group_split()

type3_plots <- type3_group_results |>
  map(~ .x %>%
        ggplot2::ggplot(ggplot2::aes(
          x = label_group_var_value_1,
          y = stat,
          fill = str_wrap(label_group_var_value_1, width = 20)
        )) +
        ggplot2::geom_col(
          position = "dodge"
        ) +
        geom_text(aes(label = scales::percent(x = stat, accuracy = 1L)), vjust = -0.5) +
        ggplot2::labs(
          title = stringr::str_wrap(
            paste(
              unique(.x$label_information),
              "for the ",
              unique(.x$label_group_var_value_2)
            ),
            50
          ),
          fill = stringr::str_wrap(unique(.x$label_group_var_1), 20),
          x = element_blank()
        ) +
        theme(
          axis.line = element_blank(),
          axis.text.x = element_blank()
        ) +
        theme_impact() +
        theme_barplot())
## Create a naming vector to save the plots
type3_file_names <- paste0("output/plots_",country_assessment,"/", tab_helper, "/type_3/", 1:length(type3_plots), "type_3_plot.png")

## Save the plots
map2(type3_file_names, type3_plots, ~ ggsave(
  filename = .x,
  plot = .y,
  width = 8,
  bg = "white",
  height = 4,
  units = "in"
))

## Write plots index
type3_group_id %>% write.csv(paste0("output/plots_",country_assessment,"/", tab_helper, "/type_3/", "type_3_index.csv"))

# Tables for maps
# Removes admin level (should be maps?)
only_admin_level <- disruptions_results_for_graphs %>%
  filter(str_detect(group_var, "admin1"))


only_admin_level <- only_admin_level %>%
  unite(
    col = map_analysis_var,
    label_information, label_group_var_value_2, remove = F, sep = " %/% "
  )

disruptions_table_for_maps <- only_admin_level %>%
  create_table_for_map(
    number_classes = 5,
    group_var_value_column = "label_group_var_value_1",
    analysis_var_column = "map_analysis_var"
  )
disruptions_table_for_maps %>%
  write.csv(paste0("output/table_for_maps/", tab_helper, "_table_for_maps", country_assessment, ".csv"))
