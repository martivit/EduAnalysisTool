
```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
# This section is not for running but serves as an example setup.
```

# ANALYSIS GUIDANCE (Example)

## Analysis Overview

The analysis focuses on two main categories:
1. Children accessing education
2. Children not accessing education (Out-of-school)

### Children Accessing Education
This analysis revolves around two dimensions:
- **Access to education**: Percentage of children aged 5 to 17 who attended school during the 2023-2024 school year.
- **Education disruption**: Assess significant events affecting education.

Disruption types include:
- Natural hazards
- Teacher absences
- Schools used as shelters or occupied by armed forces

### Sub-School-Age Categories Analysis
Break down children into:
- **5-year-olds**: Early childhood education access.
- **Primary school age**: Attendance rates and over-age attendance.
- **Secondary school age**: Similar analysis, further breaking down into lower- and upper-secondary levels.

### Indicators for Children in School
- **ECE Access**: Percentage of children attending early childhood education.
- **Early Enrolment in Primary Grades**: Percentage of children attending primary school before the official age.
- **Net Attendance Rates**: The percentage of school-aged children currently attending.
- **Over-Age Attendance**: Children attending school who are two years older than the intended age for their grade.

### Children Not Accessing Education
Key dimensions:
- **Out-of-School Rate**: Percentage of children not attending school.
- **Barriers to Education**: Identify the main barriers preventing access.

## Analysis Implementation

### 1. Install Necessary Packages (Example Code)

```
# Example of how to install the necessary packages
if(!require(devtools)) install.packages("devtools")
devtools::install_github("impact-initiatives-hppu/humind")
devtools::install_github("impact-initiatives-hppu/humind.data", ref = "education")

library(humind) 
library(humind.data)

source ('scripts-example/Education/src/functions/00_edu_helper.R')
source ('scripts-example/Education/src/functions/00_edu_function.R')

```

### 2. Load MSNA Data and Add Education Indicators (Example Code)

```
# Example of loading datasets and adding education indicators
path_ISCED_file = 'scripts-example/Education/resources/UNESCO ISCED Mappings_MSNAcountries_consolidated.xlsx'
HTI_file <- 'scripts-example/Education/input/HTI2401-MSNA-DEPARTEMENTS-Clean-dataset.xlsx'

main  <- read_xlsx(HTI_file,
                   guess_max = 50000,
                   na = c("NA","#N/A",""," ","N/A"),
                   sheet = 'Clean Data')

loop <- read_xlsx(HTI_file,
                  guess_max = 50000,
                  na = c("NA","#N/A",""," ","N/A"),
                  sheet = 'ind_loop')



loop <- loop |>
  add_loop_edu_ind_age_corrected(main = main, id_col_loop = '_submission__uuid.x', id_col_main = '_uuid', 
                                 survey_start_date = 'start', school_year_start_month = 9, ind_age = 'ind_age') |>
  add_loop_edu_access_d(ind_access = 'edu_access') |>
  add_loop_edu_disrupted_d(occupation = 'edu_disrupted_occupation', hazards = 'edu_disrupted_hazards', 
                           displaced = 'edu_disrupted_displaced', teacher = 'edu_disrupted_teacher')

# Example of harmonizing variables
loop <- loop |>
  add_edu_school_cycle(country_assessment = 'HTI', path_ISCED_file) |>
  add_edu_level_grade_indicators(country_assessment = 'HTI', path_ISCED_file, education_level_grade = "edu_level_grade", 
                                 id_col_loop = '_submission__uuid.x', pnta = "pnta", dnk = "dnk") |>
  add_loop_edu_barrier_d(barrier = "edu_barrier", barrier_other = "other_edu_barrier")
```

### 3. Filter for School-Age Children (Example Code)

```
# Example of filtering to keep only school-age children
loop <- loop |> filter(edu_ind_schooling_age_d == 1)
```

### 4. Export Results to Excel (Example Code)

```
# Example of exporting the final data to Excel
write.xlsx(loop, 'scripts-example/Education/output/loop_edu_complete.xlsx')
```

## Final Thoughts

All these steps combine to provide a comprehensive analysis of education indicators, broken down by access, disruption, and barriers to education. For more details on `humind.data` functions, check the [documentation](https://github.com/impact-initiatives-hppu/humind).
