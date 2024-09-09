library(tidyverse)
library(srvyr)
library(analysistools)
library(dplyr)
library(readxl)
library(openxlsx)
library(writexl)
library(tidyr)
library(stringr)
library(tibble)
library(ggplot2)
library(grid)
library(gridExtra)
library(ggtext)


# Read the dataset with indicators and loa
loa <- read.csv("input_tool/edu_analysistools_loa_HTI.csv", na.strings = "")
loop <- read_xlsx("output/loop_edu_recorded.xlsx")

loop$weight <- 1
filtered_vars <- list()

# Loop over the analysis_var in loa and check if it exists in the column names of loop
loa_filtered <- loa %>%
  dplyr::filter({
    purrr::map_lgl(analysis_var, function(var) {
      if (var %in% colnames(loop)) {
        TRUE  # Keep the variable if it exists in loop
      } else {
        filtered_vars <<- append(filtered_vars, var)  # Track the filtered variable
        FALSE  # Filter out the variable if it doesn't exist in loop
      }
    })
  })


# Print the filtered variables for debugging
if (length(filtered_vars) > 0) {
  message("Filtered out the following analysis_var as they are not present in loop columns:")
  print(filtered_vars)
}



# Convert loop to survey design
design_loop <- loop |>
  as_survey_design(weights = weight)


results_loop_weigthed <- create_analysis(
  design_loop,
  loa = loa_filtered,
  sm_separator =  ".")




results_loop_weigthed$results_table %>%  write.csv('output/analysis_key_output.csv')
results_loop_weigthed %>%
  saveRDS("output/analysis_key_output.RDS")

