# POC-CA-Annual-Report
It is important the scripts are run in the correct order since they build off each other and need to be run in the order that they appear below.

## Included Scripts

- 1. create_cfsr_safety
- 2. maltreatment_in_care
- 3. maltreatment_recurrance

### Dependencies

#### Functions

1. fnc_datediff_days: Custom POC function for getting date difference in days.

2. fnc_datediff_mos: Custom POC function for getting date difference in months.

3. fnc_datediff_yrs: Custom POC function used for getting date difference in years, this function is useful for age.

### 1. Creating the cfsr safety table

1. dat_year
2. maltreatment_in_care
3. recurrence_of_maltreatment

### 2. Maltreatment in Care

This is the second script that needs to be run and it populates dat_year and maltreatment_in_care.

### 2. Recurrenc of Maltreatment

This is the third script that needs to be run and it populates recurrence_of_maltreatment.