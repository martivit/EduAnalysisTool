# ANALYSIS GUIDANCE, EDUCATION FOCUSED OUTPUT

**Table of Contents**

1. [Analysis Overview](#analysis-overview)
   - [Analysis of Children Accessing Education](#1-analysis-of-children-accessing-education)
     - [Sub-School-Age Categories Analysis](#sub-school-age-categories-analysis)
   - [Analysis of Children Not Accessing Education](#2-analysis-of-children-not-accessing-education-oos)
2. [Analysis Implementation](#analysis-implementation)  
   - [Repository structure](#0-Repository-structure)
   - [Install functions and load Data](#1-Install-functions-and-load-Data)
   - [Add Education Indicators](#2-Data-preparation)
   - [Indicator analysis](#3-Add-Education-Indicators)
   - [Import Labels](#4-Label-Data)
   - [Final output - I: Tables](#5-Create-Tables)
   - [Final output - II: Graphs](#5-Create-Graphs)


## Content of the Analysis structure 
### Analysis Overview

The analysis should be conducted at the individual level and can be divided into two main categories:<br>
A. <span style="color:blue">**Children accessing education**</span>: Focus on their profiles and the challenges they face while attending school.<br>
B. <span style="color:blue">**Children not accessing education – Out-of-school (OSC)**</span>: Focus on identifying the main barriers preventing their access.<br><br>

#### **1. Analysis of Children Accessing Education**
Two key dimensions are essential for this analysis: access to education and the impact of significant events on education during the school year.<br>

- **Access to education**: Analyse the percentage of children aged 5 to 17 who attended school or any early childhood education program at any time during the 2023-2024 school year.

- **Education disruption**: Assess whether any significant events disrupted education during the school year, with a focus on factors such as:

  - Natural hazards (e.g., floods, cyclones, droughts, wildfires, earthquakes)
  - Teacher absences
  - Schools being used as shelters for displaced persons
  - Schools occupied by armed forces or non-state armed groups (if applicable in your MSNA)

##### Sub-School-Age Categories Analysis
The analysis should account for sub-school-age categories to capture more detailed insights into access to education. These categories can be broken down as follows:<br>

-	**5-year-olds**: Typically one year before the official primary school entry age. Analysis should include access to early childhood education and early enrolment in primary grades (see below).

-	**Primary School Age**: Children who fall within the age range for primary school. Key areas of analysis include access to education, net attendance rates, and over-age attendance (see below).

-	**Secondary School Age**: Children within the age range for secondary education. The focus here should be on access, attendance rates, and over-age attendance, with further breakdowns into lower-secondary and upper-secondary levels as appropriate.

Further distinctions, such as lower-secondary and upper-secondary levels, may be made depending on the specific context and school structure.

Breaking down the important dimension by school-age category:<br>
For **5-year-old** children, analysis should focus on the already mentioned access, disruption, and additionally Early Childhood Education indicators:

-	*ECE Access*: Participation rate in organized learning (one year before the official primary entry age). This refers to the percentage of children attending an early childhood education program or primary school.

-	*Early Enrolment in Primary Grades*: The percentage of children one year before the official primary school entry age attending primary school.

For children in the **primary school-age** category (and similarly for older age groups), access and disruption can be analysed along with:

-	*Net Attendance (adjusted) Rates*: The percentage of school-aged children in primary school, lower secondary, or upper secondary school who are currently attending school.

-	*Over-Age Attendance*: The percentage of school-aged children attending school who are at least two years older than the intended age for their grade, specifically at the primary school level.

**All the mentioned dimensions and indicators should always be disaggregated by gender, and, where possible, by population group and administrative level**

#### **2. Analysis of Children Not Accessing Education, OoS**
Two key dimensions are essential for this analysis: the out-of-school rate and the barriers preventing access to education.

- **Out-of-School Rate**: Analyse the percentage of school-aged children who are not attending any level of education.

- **Barriers to Education**: Identify the main barriers preventing children from attending school.

Following the same logic, the school-age categories and disaggregation need to be applied, measuring these indicators for each of the school-age categories.

**All the mentioned dimensions and indicators should always be disaggregated by gender, and, where possible, by population group and administrative level**


## Analysis Implementation

### 0. Repository structure 

This repository is designed to process and analyze educational data from various sources. It provides a systematic approach to adding indicators, running analyses, and generating tables for different educational metrics. The script is modular and can be adapted for different countries, datasets, and languages.

The Main.R script and repository are organized to follow a systematic approach to process and analyze educational data. The structure is divided into several steps, each corresponding to specific functions or scripts that move the data from clean input to final analysis and output.

### 1. Install packages and source needed functions and Data Preparation

This project uses [renv](https://rstudio.github.io/renv/) to keep everyone on the same package versions, including the GitHub-only packages (`humind`, `analysistools`, `presentresults`, `impactR.utils`) pinned to fixed commits. Open the project in RStudio (or run `setwd()` to the project folder) and run:

```
if (!require(renv)) install.packages("renv")
renv::restore()
```

This installs every package the project needs, at the exact versions recorded in `renv.lock`. Once it finishes:

```
library(humind)
library(analysistools)
library(presentresults)
```

##### If you hit a GitHub API rate limit

`renv::restore()` only contacts GitHub for the packages actually recorded with `Source: GitHub` in `renv.lock` (currently `humind`, `analysistools`, `presentresults`, `impactR.utils`, plus their own GitHub-only dependencies `addindicators` and `cleaningtools`) — it does not re-query GitHub for CRAN packages. If you still hit GitHub's unauthenticated rate limit (60 requests/hour per IP), you have two options:

- **Authenticate**: run `usethis::create_github_token()` to create a personal access token, then `gitcreds::gitcreds_set()` to store it. This raises the limit substantially.
- **Wait it out or switch network**: the limit is per IP and resets hourly; switching wifi/network also gives you a fresh limit.

Avoid `remotes::install_deps()` or `renv::install()` as a workaround — both re-resolve the `Remotes:` field (and re-hit the GitHub API) on every call, even for pure-CRAN packages, and will burn through the rate limit much faster than `renv::restore()` alone.

##### Installing the GitHub-only packages manually

If you need to install just the GitHub-sourced packages by hand (e.g. `renv::restore()` failed partway through and you want to retry only those), install them individually with `remotes::install_github()`, pinned to the same commits recorded in `DESCRIPTION`'s `Remotes:` field:

```r
if (!require(remotes)) install.packages("remotes")

remotes::install_github("impact-initiatives-hppu/humind@956765719018fdb708f168b45fb45866e1dae4ac")
remotes::install_github("impact-initiatives/analysistools@d748f320c41eeaa5619be45457414ffb4f53e78a")
remotes::install_github("impact-initiatives/presentresults@6219392a2983db6c90b5e7cb557db5e052b76fed")
remotes::install_github("impact-initiatives/impactR.utils@880a57ebb0282e377f888f352c746c9bde412e75")
```

`humind` and `analysistools` each pull in one further GitHub-only dependency (`addindicators` and `cleaningtools` respectively) automatically — `remotes` resolves and installs those for you as part of the calls above, so you don't need to install them separately. If those pins ever need to move to a newer commit, update both this list and the `Remotes:` field in `DESCRIPTION` together, then run `renv::snapshot()` to update `renv.lock`.
##### Additional functions 
```
source ('src/functions/00_edu_helper.R')
source ('src/functions/00_edu_function.R')
source("src/functions/create_education_table_group_x_var.R")
source("src/functions/create_education_xlsx_table.R")

source("src/00-getting-info-country.R")
source('src/01-add_education_indicators.R')
source('src/02-education_analysis.R')
source('src/03-education_labeling.R')
source('src/04-01-make-table-access-overaged-barriers.R')
source('src/04-02-make-level-table.R')
source('src/05-01-make-graphs-and-maps-tables.R')
```

### 2. Data preparation

##### Input Data Paths

Define paths to all input data files: Dataset folder and  ISCED mappings
```
path_ISCED_file <- 'resources/UNESCO ISCED Mappings_MSNAcountries_consolidated.xlsx'
data_file <- paste0('DATA/',country_assessment, '/',list_info_general$dataset)
kobo_path <- paste0('DATA/',country_assessment, '/',list_info_general$dataset)


```
Place the dataset at `DATA/<country_assessment>/<filename>` (the filename comes from `general$dataset` in the metadata file). `DATA/` is gitignored, same as `metadata_edu.xlsx` — real survey data is never committed.
The remaining information related to language, Kobo, variables, and indicators must be completed in `input_tool/01_metadata/metadata_edu.xlsx` — a real, filled-in copy of `input_tool/01_metadata/example_metadata_edu.xlsx`, which ships in the repo as the template. `metadata_edu.xlsx` itself is gitignored (it can contain real dataset filenames/column names), so create it by copying the example and filling it in; it's never committed. The example also has an `instructions` sheet documenting every column, whether it's required or optional, and a `00L` ("Lemuria") example row with some fields intentionally left blank so you can see what the configuration-validation error message looks like before running against real data.

If `input_tool/01_metadata/metadata_edu.xlsx` is missing, has no row for `country_assessment`, or is missing a required value, `MAIN.R` stops early with a message naming exactly what's missing instead of failing partway through the pipeline.

#### Input data tools

The education list of analysis defaults to the shared starting kit: input_tool/03_loa/edu_analysistools_loa_starting_kit.xlsx. To use a country-specific LOA file instead, place it in input_tool/03_loa/ and set the `loa_file` column (just the filename) for that country's row in the `general` sheet of `input_tool/01_metadata/metadata_edu.xlsx`; leave it blank to keep using the starting kit.

Please modify the column group_var to reflect the desired disaggregation variable. School-age cycle, edu_school_cycle_d, and gender, ind_gender, are already included.
```
loa_path <- if (!is.null(list_info_general$loa_file)) {
  paste0('input_tool/03_loa/', list_info_general$loa_file)
} else {
  'input_tool/03_loa/edu_analysistools_loa_starting_kit.xlsx'
}

suffix <- ifelse(language_assessment == "French", "_FR", "_EN")
data_helper_table <- paste0("input_tool/02_edu_table/edu_table_helper", suffix, '_', country_assessment, ".xlsx")

labelling_tool_path <- "input_tool/edu_indicator_labelling.xlsx"
```
#### Variables Definition

At the beginning of the Main.R script, specify the country code for this analysis; every other variable (including `language_assessment`) is read from `input_tool/01_metadata/metadata_edu.xlsx` for that country:
```
country_assessment <- "AFG"
```

#### Known limitations

Some indicator logic in `src/01-add_education_indicators.R` (survey-date fixes, a few country-specific column names, extra disaggregation columns) is still hardcoded per country rather than driven by `input_tool/01_metadata/metadata_edu.xlsx`. This is a candidate for a future config-driven refactor; for now, adding a new country there may still require a small code change in that file.

##### Temporary workaround: `safe_add_*` column-overwrite protection

Several `humind` functions (`add_loop_edu_ind_age_corrected()`, `add_loop_edu_access_d()`, `add_loop_edu_disrupted_d()`, `add_loop_wgq_ss()`) and a couple of this project's own local functions (`add_edu_school_cycle()`, `add_edu_level_grade_indicators()`, `add_loop_edu_barrier_d()`, `add_loop_child_gender_d()`, `add_loop_edu_optional_nonformal_d()`) silently overwrite any pre-existing column that happens to share a name with one of their outputs — e.g. a raw survey column called `edu_ind_age_schooling` gets silently replaced by `add_loop_edu_ind_age_corrected()`'s output column of the same name, with the original values lost.

Until this is fixed upstream in `humind`, `src/01-add_education_indicators.R` calls `safe_add_*` wrapper versions of these functions (e.g. `safe_add_loop_edu_ind_age_corrected()` instead of `add_loop_edu_ind_age_corrected()`). Each wrapper has the exact same call signature as the function it wraps; it compares the data before and after the call and, if any pre-existing column was overwritten, preserves the original values under an `_orig` suffix (e.g. `edu_ind_age_schooling_orig`) and updates any pipeline variable that referenced the old column name. The wrapper functions and this protection logic live entirely in `src/functions/00_safe_add_functions.R`, which is sourced conditionally from `MAIN.R` (only if the file exists) so that removing it doesn't require touching `MAIN.R`.

**To remove this workaround once `humind` ships a fix for the underlying issue:**
1. Delete `src/functions/00_safe_add_functions.R`.
2. In `src/01-add_education_indicators.R`, find-and-replace `safe_add_` with `add_`.

No other files need to change — `MAIN.R`'s `source()` call for that file is already conditional on the file existing, and `src/functions/00_edu_helper.R` was never modified by this workaround.

### 3. Add Education Indicators
The function processes the cleaned data by adding relevant education indicators. It adds the following indicators and information:

- Access 

- Education disruption

- School-cycle age categorization: Add a column edu_school_cycle with ECE, primary (1 or 2 cycles) and secondary

- Level-grade composite indicators: Net attendance, early-enrollment, overage learners.

- OPTIONAL non-core indicators, non-formal and community modality

- Merge the loop with the main script to retrieve weight and strata information, such as admin levels, population groups, etc.

- Filter for School-Age Children


The function is defined in **01-add_education_indicators.R**. 

It uses Humind package (https://github.com/impact-initiatives-hppu/humind) and additional education functions defined in 00_edu_function.R
```
source('src/01-add_education_indicators.R')

```
The processed dataset with the recorded education indicators is saved in the *output/loop_edu_recorded.xlsx* file. It serves as the foundation for the further steps.

### 3. Run Education Analysis

This function runs the analysis based on the data with the added indicators. It includes generating summary statistics and applying filters based on predefined variables and thresholds.

It is defined in **02-education_analysis.R**

It uses analysistools::create_analysis() function from the **impact-initiatives/analysistools** package https://github.com/impact-initiatives/analysistools/blob/main/R/create_analysis.R

```
source('src/02-education_analysis.R')
```
The output is saved here: *output/grouped_other_education_results_loop.RDS*

### 4. Label Data

After running the analysis, this function ensures that the correct labels are applied to the indicators for easy interpretation. It converts technical names into user-friendly labels according to the KOBO survey and choices and the edu_indicator_labeling.xlsx
This labeling step is crucial for aligning the analysis output with the desired format for reporting and visualization, ensuring consistency across the dataset and tables.


The function is defined here: **03-education_labeling.R**.

```
source('src/03-education_labeling.R')  ## OUTPUT: output/labeled_results_table.RDS  ---- df: education_results_table_labelled
```
The output is saved here: *output/labeled_results_table.RDS  ---- df: education_results_table_labelled*

### 5. Create Tables 
First create workbook for tables
```
education_results_table_labelled <- readRDS("output/labeled_results_table.RDS")

wb <- openxlsx::createWorkbook("education_results")
addWorksheet(wb, "Table_of_content")
writeData(wb, sheet = "Table_of_content", x = "Table of Content", startCol = 1, startRow = 1)

row_number_lookup <- c(
  "access" = 2,
  "overaged" = 3,
  "out_of_school" = 4,
  "ece" = 5,
  "level1" = 6,
  "level2" = 7,
  "level3" = 8,
  "level4" = 9
)

```

#### Create **Analysis of Children Accessing Education** 

It generates a table showing data on disruptions to education (e.g., due to teacher absence, school occupation, hazards).
```
tab_helper <- "access"
source("src/04-01-make-table-access-overaged-barriers.R")
```
It generates a table showing data on ovaaged learners.
```
tab_helper <- "overaged"
source("src/04-01-make-table-access-overaged-barriers.R")
```
#### Create **Analysis of Children Not Accessing Education, OoS** 

IMPORTANT: open grouped_other_education_results_loop and copy the first (in decreasing order) 5 edu_barrier_d results in the edu_table_helper_FR.xlsx.  
```
tab_helper <- "out_of_school"
source("src/04-01-make-table-access-overaged-barriers.R")
```

#### Create **Early childhood education and early enrolment** 

It generates a table specifically for indicators related to children one year before they reach the age to start primary school.
```
tab_helper <- "ece"
source("src/04-02-make-level-table.R")
```

#### Create **School Attendance Profile** 

To repeat according to the number of levels (except ECE) in the country's school system

```
tab_helper <- "level1"
source("src/04-02-make-level-table.R")

tab_helper <- "level2"
source("src/04-02-make-level-table.R")

tab_helper <- "level3"
source("src/04-02-make-level-table.R")

openxlsx::saveWorkbook(wb, "output/education_results.xlsx", overwrite = T)
openxlsx::openXL("output/education_results.xlsx")
```

#### Final Output and Workbook Creation

A workbook is created using openxlsx, which consolidates all the tables and analysis results into one Excel file. It can be found here: **output/education_results.xlsx**.

It includes a Table of Contents: a summary sheet that hyperlinks to each table in the workbook is created for easy navigation.

### 6. Create Graphs 
```
tab_helper <- "access"
results_filtered <- "output/rds_results/access_results.rds"
source("src/05-01-make-graphs-and-maps-tables.R")

tab_helper <- "overaged"
results_filtered <- "output/rds_results/overaged_results.rds"
source("src/05-01-make-graphs-and-maps-tables.R")

tab_helper <- "out_of_school"
results_filtered <- "output/rds_results/out_of_school_results.rds"
source("src/05-01-make-graphs-and-maps-tables.R")

tab_helper <- "ece"
results_filtered <- "output/rds_results/ece_results.rds"
source("src/05-01-make-graphs-and-maps-tables.R")

tab_helper <- "level1"
results_filtered <- "output/rds_results/level1_results.rds"
source("src/05-01-make-graphs-and-maps-tables.R")

tab_helper <- "level2"
results_filtered <- "output/rds_results/level2_results.rds"
source("src/05-01-make-graphs-and-maps-tables.R")

tab_helper <- "level3"
results_filtered <- "output/rds_results/level3_results.rds"
source("src/05-01-make-graphs-and-maps-tables.R")
```



