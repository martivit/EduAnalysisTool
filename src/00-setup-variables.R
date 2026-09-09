# Disaggregation levels are read from the strata_variables sheet's
# strata_lvl_1..strata_lvl_15 columns for country_assessment (see
# src/00-getting-info-country.R). Only strata_lvl_1 is mandatory; the rest
# may be left blank (get_strata_variables()/mget() already drop unset levels).
strata_var_names <- paste0("strata_lvl_", 1:15)

language_assessment = list_info_general$language_assessment

## --------------- File paths
# Stops with a clear message naming the file and the metadata field that produced it,
# instead of letting readxl fail later with a generic "file does not exist" error.
require_input_file <- function(path, field_description) {
  if (!file.exists(path)) {
    stop(sprintf(
      "Required file not found: '%s' (%s). Check the corresponding value in input_tool/01_metadata/metadata_edu.xlsx.",
      path, field_description
    ))
  }
  invisible(TRUE)
}

#-- input data
path_ISCED_file <- "resources/UNESCO ISCED Mappings_MSNAcountries_consolidated.xlsx"
require_input_file(path_ISCED_file, "ISCED mapping file, path hardcoded in src/00-setup-variables.R")

data_file <- paste0("DATA/",country_assessment, "/",list_info_general$dataset)
require_input_file(data_file, "general$dataset in input_tool/01_metadata/metadata_edu.xlsx, combined with DATA/<country_assessment>/")
label_main_sheet <- list_info_general$label_main_sheet
label_edu_sheet  <- list_info_general$label_edu_sheet

kobo_path <- paste0("DATA/",country_assessment, "/",list_info_general$dataset)
label_survey_sheet  <-  list_info_general$label_survey_sheet
label_choices_sheet <-  list_info_general$label_choices_sheet
kobo_language_label <-  list_info_general$kobo_language_label

# Optional pcode columns (admin1/2/3), merged into loop alongside the strata
# levels in 01-add_education_indicators.R. NULL (and simply not merged) if left
# blank in metadata_edu.xlsx.
adm1_pcode_col <- list_info_general$adm1_pcode_colum
adm2_pcode_col <- list_info_general$adm2_pcode_colum
adm3_pcode_col <- list_info_general$adm3_pcode_colum

#-- input tool
# please modify the group_var according to your context

loa_path <- if (!is.null(list_info_general$loa_file)) {
  paste0("input_tool/03_loa/", list_info_general$loa_file)
} else {
  warning("general$loa_file is blank for country_assessment = '", country_assessment, "' in input_tool/01_metadata/metadata_edu.xlsx; ",
          "falling back to the shared example LOA (input_tool/03_loa/edu_analysistools_loa_starting_kit.xlsx). ",
          "Set a country-specific loa_file if this isn't intended.")
  "input_tool/03_loa/edu_analysistools_loa_starting_kit.xlsx"
}
require_input_file(loa_path, "general$loa_file in input_tool/01_metadata/metadata_edu.xlsx (blank falls back to the starting-kit LOA)")

suffix <- ifelse(language_assessment == "French", "_FR", "_EN")
data_helper_table <- paste0("input_tool/02_edu_table/edu_table_helper", suffix,'_', country_assessment,".xlsx")
require_input_file(data_helper_table, "derived from general$language_assessment and country_assessment; expected in input_tool/02_edu_table/")

labelling_tool_path <- "input_tool/edu_indicator_labelling.xlsx"
require_input_file(labelling_tool_path, "labelling tool, path hardcoded in src/00-setup-variables.R")

## -------------  definition of variable according to the analysis' context
id_col_loop = list_variables$id_col_loop
id_col_main = list_variables$id_col_main
survey_start_date = list_variables$survey_start_date
school_year_start_month = list_variables$school_year_start_month # start school year in country
ind_age = list_variables$ind_age # individual age variable
ind_gender = list_variables$ind_gender # individual gender variable
pnta = list_variables$pnta
dnk = list_variables$dnk
yes = list_variables$yes
no = list_variables$no
weight_col <- list_variables$weight_col
schooling_start_age <- if (!is.null(list_variables$schooling_start_age)) list_variables$schooling_start_age else 5 # optional metadata field; defaults to 5 if blank
schooling_end_age <- if (!is.null(list_variables$schooling_end_age)) list_variables$schooling_end_age else 17 # optional metadata field; defaults to 17 if blank

#------------- indicators
ind_access <- list_variables$ind_access
occupation <- list_variables$occupation
hazards <- list_variables$hazards
displaced <- list_variables$displaced
teacher <- list_variables$teacher
education_level_grade <- list_variables$education_level_grade
barrier = list_variables$barrier
number_displayed_barrier <- if (!is.null(list_variables$number_displayed_barrier)) list_variables$number_displayed_barrier else 15 # optional metadata field; defaults to 15 if blank
# non formal
nonformal <-list_variables$nonformal
nonformal_type <-list_variables$nonformal_type
#wgs
wsg_seeing <-list_variables$wsg_seeing
wsg_hearing <-list_variables$wsg_hearing
wsg_walking <-list_variables$wsg_walking
wsg_remembering <-list_variables$wsg_remembering
wsg_selfcare <-list_variables$wsg_selfcare
wsg_communicating <-list_variables$wsg_communicating
no_difficulty <-list_variables$no_difficulty
some_difficulty <-list_variables$some_difficulty
lot_of_difficulty <-list_variables$lot_of_difficulty
cannot_do <-list_variables$cannot_do



label_overall <- if (language_assessment == "French") "Ensemble" else "Overall"
label_female <- if (language_assessment == "French") "Filles" else "Girls"
label_male <- if (language_assessment == "French") "Garcons" else "Boys"
label_edu_school_cycle <- if (language_assessment == "French") "Cycle Scolaire Assigné par Âge" else "Age-Assigned School Cycle"

# Read ISCED info
country_code <- str_sub(country_assessment, 1, 3)
info_country_school_structure <- read_ISCED_info(country_code, path_ISCED_file)
summary_info_school <- info_country_school_structure$summary_info_school

labels_with_ages <- summary_info_school %>%
  rowwise() %>%
  mutate(label = extract_label_for_level_ordering(summary_info_school, cur_data(), language_assessment)) %>%
  pull(label)

# Read the loa
loa <- readxl::read_excel(loa_path, sheet = "Sheet1")

# Read data helper and process it
data_helper_sheets <- readxl::excel_sheets(data_helper_table)
data_helper <- data_helper_sheets %>%
  map(~ read_excel(data_helper_table, sheet = .x)) |>
  set_names(data_helper_sheets)
data_helper <- data_helper |>
  map(~ .x |>
    as.list() %>%
    map(na.omit) %>%
    map(c))

main_sheet <- label_main_sheet ## Used in 01-add_education_indicators.R
loop_sheet <- label_edu_sheet ## Used in 01-add_education_indicators.R
