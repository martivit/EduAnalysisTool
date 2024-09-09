# ANALYSIS GUIDANCE, EDUCATION FOCUSED OUTPUT

## Content of the Analysis structure 
### Analysis Overview

The analysis should be conducted at the individual level and can be divided into two main categories:<br>
1. <span style="color:blue">**Children accessing education**</span>: Focus on their profiles and the challenges they face while attending school.<br>
2. <span style="color:blue">**Children not accessing education – Out-of-school (OSC)**</span>: Focus on identifying the main barriers preventing their access.<br><br>

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

-	Early Enrolment in Primary Grades: The percentage of children one year before the official primary school entry age attending primary school.

For children in the **primary school-age** category (and similarly for older age groups), access and disruption can be analysed along with:

-	Net Attendance Rates: The percentage of school-aged children in primary school, lower secondary, or upper secondary school who are currently attending school.

-	Over-Age Attendance: The percentage of school-aged children attending school who are at least two years older than the intended age for their grade, specifically at the primary school level.


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
