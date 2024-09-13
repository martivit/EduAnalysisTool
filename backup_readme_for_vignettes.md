# ANALYSIS GUIDANCE, EDUCATION FOCUSED OUTPUT

**Table of Contents**

1. [Analysis Overview](#analysis-overview)
   - [Analysis of Children Accessing Education](#1-analysis-of-children-accessing-education)
     - [Sub-School-Age Categories Analysis](#sub-school-age-categories-analysis)
   - [Analysis of Children Not Accessing Education](#2-analysis-of-children-not-accessing-education-oos)
2. [Analysis Implementation](#analysis-implementation)   
   - [Install functions and load Data](#1-Install-functions-and-load-Data)
   - [Add Education Indicators](#2-add-education-indicators)
   - [Indicator analysis](#3-indicator-analysis)

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

### 1. Install functions and load Data
##### Install Humind, Education branch in Humind.data and analysistool packages
```
if(!require(devtools)) install.packages("devtools")
devtools::install_github("impact-initiatives-hppu/humind")
devtools::install_github("impact-initiatives-hppu/humind.data", ref = "education")
devtools::install_github("impact-initiatives/analysistools")

library(humind) 
library(humind.data)
library(analysistools)

source ('scripts-example/Education/src/functions/00_edu_helper.R')
source ('scripts-example/Education/src/functions/00_edu_function.R')
```
##### Additional education functions for level-grade indicator
```
source ('scripts-example/Education/src/functions/00_edu_helper.R')
source ('scripts-example/Education/src/functions/00_edu_function.R')
```
##### Load MSNA data and define ISCED UNESCO pathfile
```
# loop MSNA
# main MSNA
path_ISCED_file = 'scripts-example/Education/resources/UNESCO ISCED Mappings_MSNAcountries_consolidated.xlsx'
```

### 2. Add Education Indicators
Please adjust the variable names according to the country-specific MSNA.

##### Education indicators from Humind 
Correct the age according to the start of the school year
```
 loop <- loop |>
  add_loop_edu_ind_age_corrected(main = main,id_col_loop = '_submission__uuid.x', id_col_main = '_uuid', survey_start_date = 'start', school_year_start_month = 9, ind_age = 'ind_age')
 ``` 
Access 
 
 ```
  loop <- loop |>
  add_loop_edu_access_d( ind_access = 'edu_access')
  
   ```
Education disruption

  ```
  loop <- loop |>
  add_loop_edu_disrupted_d (occupation = 'edu_disrupted_occupation', hazards = 'edu_disrupted_hazards', displaced = 'edu_disrupted_displaced', teacher = 'edu_disrupted_teacher')
```
##### Additional education functions, from Humind.data

School-cycle age categorization: Add a column edu_school_cycle with ECE, primary (1 or 2 cycles) and secondary

```
  loop <- loop |>
  add_edu_school_cycle(country_assessment = 'HTI', path_ISCED_file)
```
Level-grade composite indicators: Net attendance, early-enrollment, overage learners.

IMPORTANT: THE INDICATOR MUST COMPLAY WITH THE MSNA GUIDANCE AND LOGIC.<br>
The function reads the classification of levels and grades from the UNESCO ISCED Mappings_MSNAcountries_consolidated.xlsx file. If the structure or names do not correspond to what is present in your data, please download a copy, modify it as needed, and load your version at the beginning of the script.

```
  loop <- loop |>
  add_edu_level_grade_indicators(country_assessment = 'HTI', path_ISCED_file, education_level_grade =  "edu_level_grade", id_col_loop = '_submission__uuid.x',  pnta = "pnta",
                                 dnk = "dnk")
```
Additional variable harmonization 

```
  loop <- loop |>
  add_loop_edu_barrier_d( barrier = "edu_barrier", barrier_other = "other_edu_barrier")
```
OPTIONAL non-core indicators, non-formal and community modality
```
  loop <- loop |>
  add_loop_edu_optional_nonformal_d(edu_other_yn = "edu_other_yn",edu_other_type = 'edu_non_formal_type',yes = "yes",no = "no",pnta = "pnta",dnk = "dnk" )|>
  add_loop_edu_optional_community_modality_d(edu_community_modality = "edu_community_modality" )
```

Merge the loop with the main script to retrieve weight and strata information, such as admin levels, population groups, etc.
```
  loop <- loop |>
  merge_main_info_in_loop( main, id_col_loop = '_submission__uuid.x', id_col_main = '_uuid', admin1 = 'admin1', admin3 = 'admin3',  add_col1 = 'setting', add_col2 = 'depl_situation_menage'  )
```

Filter for School-Age Children

```
loop <- loop |> filter(edu_ind_schooling_age_d == 1)
```

##### Export recorded loop dataframe to excel

```
write.xlsx(loop, 'scripts-example/Education/output/loop_edu_complete.xlsx')
```
### 3. Indicator analysis

#### Education LOA: List of analysis

The education list of analysis is saved here: scripts-example/Education/input/edu_analysistools_loa.csv

Please modify the column **group_var** to reflect the desired disaggregation variable. School-age cycle, *edu_school_cycle_d*, and gender, *ind_gender*, are already included.

#### Analysis
1) Load the loop the education_loa
2) Verify the consistency of the LOA with the loop. Loop over the analysis_var in loa and check if it exists in the column names of loop

```
filtered_vars <- list()
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

if (length(filtered_vars) > 0) {
  message("Filtered out the following analysis_var as they are not present in loop columns:")
  print(filtered_vars)
}
```
Analysis using the analysistools::create_analysis() function from the **impact-initiatives/analysistools** package https://github.com/impact-initiatives/analysistools/blob/main/R/create_analysis.R
```
design_loop <- loop |>
  as_survey_design(weights = weight)

results_loop_weigthed <- create_analysis(
  design_loop,
  loa = loa_filtered,
  sm_separator =  ".")
```



