# ANALYSIS GUIDANCE, EDUCATION FOCUSED OUTPUT

**Table of Contents**

1. [Analysis Overview](#analysis-overview)
   - [Analysis of Children Accessing Education](#1-analysis-of-children-accessing-education)
     - [Sub-School-Age Categories Analysis](#sub-school-age-categories-analysis)
   - [Analysis of Children Not Accessing Education](#2-analysis-of-children-not-accessing-education-oos)
2. [Analysis Implementation](#analysis-implementation)  
   - [Requirements](#0-Requirements)
   - [Install functions and load Data](#1-Install-functions-and-load-Data)
   - [Add Education Indicators](#2-Data-preparation)
   - [Indicator analysis](#3-Add-Education-Indicators)
   - [Import Labels](#4-Label-Data)
   - [Final output: Tables and Graphs](#5-Create-Tables-and-Graphs)

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

-	*Net Attendance Rates*: The percentage of school-aged children in primary school, lower secondary, or upper secondary school who are currently attending school.

-	*Over-Age Attendance*: The percentage of school-aged children attending school who are at least two years older than the intended age for their grade, specifically at the primary school level.

**All the mentioned dimensions and indicators should always be disaggregated by gender, and, where possible, by population group and administrative level**

#### **2. Analysis of Children Not Accessing Education, OoS**
Two key dimensions are essential for this analysis: the out-of-school rate and the barriers preventing access to education.

- **Out-of-School Rate**: Analyse the percentage of school-aged children who are not attending any level of education.

- **Barriers to Education**: Identify the main barriers preventing children from attending school.

Following the same logic, the school-age categories and disaggregation need to be applied, measuring these indicators for each of the school-age categories.

**All the mentioned dimensions and indicators should always be disaggregated by gender, and, where possible, by population group and administrative level**


## Analysis Implementation

### 0. Requirements 

This repository is designed to process and analyze educational data from various sources. It provides a systematic approach to adding indicators, running analyses, and generating tables for different educational metrics. The script is modular and can be adapted for different countries, datasets, and languages.

The Main.R script and repository are organized to follow a systematic approach to process and analyze educational data. The structure is divided into several steps, each corresponding to specific functions or scripts that move the data from clean input to final analysis and output.

### 1. Install packages and source needed functions and Data Preparation

```
if(!require(devtools)) install.packages("devtools")
devtools::install_github("impact-initiatives-hppu/humind")
devtools::install_github("impact-initiatives/analysistools")
devtools::install_github("impact-initiatives/presentresults")

library(humind) 
library(analysistools)
library(presentresults)
```
##### Additional functions 
```
source ('src/functions/00_edu_helper.R')
source ('src/functions/00_edu_function.R')
source("src/functions/create_education_table_group_x_var.R")
source("src/functions/create_education_xlsx_table.R")

source('src/01-add_education_indicators.R')
source('src/02-education_analysis.R')
source('src/03-education_labeling.R')
source('src/04-02-make-table-disruptions.R')
source('src/04-03-make-table-barriers.R')
source('src/04-04-make-ece-table.R')
source('src/04-05-make-level-table.R')
```

### 2. Data preparation

##### Input Data Paths

Define paths to all input data files, including cleaned datasets, ISCED mappings, and KOBO surveys
```
path_ISCED_file <- 'resources/UNESCO ISCED Mappings_MSNAcountries_consolidated.xlsx'
data_file <- 'input_data/data.xlsx'
label_main_sheet <-'Clean Data'
label_edu_sheet <- 'ind_loop'

kobo_path <- "input_data/kobo.xlsx"
label_survey_sheet <-'survey'
label_choices_sheet <- 'choices'
kobo_language_label <- "label::french"
```
#### Input data tools

The education list of analysis is saved here: input_tool/edu_analysistools_loa.xlsx

Please modify the column group_var to reflect the desired disaggregation variable. School-age cycle, edu_school_cycle_d, and gender, ind_gender, are already included.
```
loa_path = "input_tool/edu_analysistools_loa.xlsx" 
suffix <- ifelse(language_assessment == 'French', "_FR", "_EN")

data_helper_table <- paste0("input_tool/edu_table_helper", suffix, ".xlsx")
labelling_tool_path <- "input_tool/edu_indicator_labelling.xlsx"
```
#### Variables Definition

At the beginning of the Main.R script, specify the variable names according to the context of the analysis (country, data format, etc.)
```
country_assessment = 'HTI'
language_assessment = 'French'
etc ...
```
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
add_education_indicators(country_assessment = country_assessment, data_file = data_file, path_ISCED_file = path_ISCED_file,
                        main_sheet = label_main_sheet,loop_sheet = label_edu_sheet,
                        id_col_loop = id_col_loop, id_col_main = id_col_main,survey_start_date = survey_start_date,school_year_start_month = school_year_start_month,ind_age = ind_age,pnta = pnta,dnk = dnk,
                        ind_access = ind_access,occupation = occupation,hazards = hazards,displaced = displaced,teacher = teacher,education_level_grade = education_level_grade,barrier = barrier,barrier_other = barrier_other,
                        admin1 = admin1,admin3 = admin3, add_col1 = add_col1, add_col2 = add_col2)
```
The processed dataset with the recorded education indicators is saved in the *output/loop_edu_recorded.xlsx* file. It serves as the foundation for the further steps.

### 3. Run Education Analysis

This function runs the analysis based on the data with the added indicators. It includes generating summary statistics and applying filters based on predefined variables and thresholds.

It is defined in **02-education_analysis.R**

It uses analysistools::create_analysis() function from the **impact-initiatives/analysistools** package https://github.com/impact-initiatives/analysistools/blob/main/R/create_analysis.R

```
run_education_analysis(loa_path, number_displayed_barrier = number_displayed_barrier)
```
The output is saved here: *output/grouped_other_education_results_loop.RDS*

### 4. Label Data

After running the analysis, this function ensures that the correct labels are applied to the indicators for easy interpretation. It converts technical names into user-friendly labels according to the KOBO survey and choices and the edu_indicator_labeling.xlsx
This labeling step is crucial for aligning the analysis output with the desired format for reporting and visualization, ensuring consistency across the dataset and tables.


The function is defined here: **03-education_labeling.R**.

```
change_label (kobo_path = kobo_path, label_survey_sheet = label_survey_sheet, label_choices_sheet = label_choices_sheet, labeling_path = labelling_tool_path, 
              language = language_assessment, label_column_kobo = kobo_language_label) 
```
### 5. Create Tables and Graphs
First create workbook for tables
```
wb <- openxlsx::createWorkbook("education_results")
addWorksheet(wb, "Table_of_content")
writeData(wb, sheet = "Table_of_content", x = "Table of Content", startCol = 1, startRow = 1)
```

#### Create **Analysis of Children Accessing Education** table: create_access_education_table()

Defined in **04-02-make-table-disruptions.R**. It generates a table showing data on disruptions to education (e.g., due to teacher absence, school occupation, hazards).
```
create_access_education_table( loa_file =loa_path,  data_helper_file = data_helper_table, language = language_assessment)
```

#### Create **Analysis of Children Not Accessing Education, OoS** table: create_out_of_school_education_table()

Defined in **04-03-make-table-barriers.R**. 

IMPORTANT: open grouped_other_education_results_loop and copy the first (in decreasing order) 5 edu_barrier_d results in the edu_indicator_labelling_FR/EN.xlsx.  
```
create_out_of_school_education_table( loa_file =loa_path,  data_helper_file = data_helper_table, language = language_assessment)
```

#### Create **Early childhood education and early enrolment** table: create_ece_table()

Defined in **04-04-make-ece-table.R**. It generates a table specifically for Early Childhood Education (ECE) data.
```
create_ece_table (loa_file =loa_path,  data_helper_file = data_helper_table, gender_var = ind_gender, language = language_assessment) 
```

#### Create **School Attendance Profile** table: create_level_education_table()

To repeat according to the number of levels (except ECE) in the country's school system

Defined in **04-05-make-level-table.R**.
```
create_level_education_table( level_table = 'level1',
                              loa_file =loa_path,  data_helper_file = data_helper_table, path_ISCED_file = path_ISCED_file,  gender_var = ind_gender, language = language_assessment)
```

#### Final Output and Workbook Creation

A workbook is created using openxlsx, which consolidates all the tables and analysis results into one Excel file. It can be found here: **output/education_results.xlsx**.

It includes a Table of Contents: a summary sheet that hyperlinks to each table in the workbook is created for easy navigation.
