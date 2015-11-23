# Creating CFSR Permanency Measures

It is important the scripts are run in the correct order since they build off each other and need to be run in the order that they appear below.

## Included Scripts
    
1. create_cfsr_permanency
2. create_placement_mobility
3. placement_mobility
4. perm_first_day
5. perm_entries_reentry


### Dependencies

#### Tables/Views

1. prm_eth_census: used so that records are counted correctly with their respective race and the all category. POC is using the Children's Bureau race definitions which classifies anyone with an hispanic background, regardless of race, as hispanic. This is why the WHERE clause filters out 9, 10, 11, 12 since we only need 8 categories:

    - 0. All Race/Ethnicity
    - 1. American Indian/Alaska Native
    - 2. Asian
    - 3. Black/African American
    - 4. Native Hawaiian/Other Pacific Islander
    - 5. Hispanic or Latino
    - 6. White/Caucasian
    - 7. Multiracial
    - 8. Unknown

2. age_category: used so that records are counted correctly with their respective race and the all category. POC is using the Children's Bureau age categories:

    - 1. ages 0 to 5
    - 2. ages 6 to 11
    - 3. ages 12 to 17

3. prm_region_6: used so that records are counted correctly with their respective region and the all category.

4. disreasn_view: used so that records are counted correctly with their respective discharge type and the all category. We are only concerned about discharge types that are considered discharged to permanency.

#### Functions

1. fnc_datediff_days: Custom POC function for getting date difference in days.

2. fnc_datediff_mos: Custom POC function for getting date difference in months.

3. fnc_datediff_yrs: Custom POC function used for getting date difference in years, this function is useful for age.

## Placement Stability

### 1. Creating the placement mobility table

1. dat_year: 
2. region: 
3. sex: 
4. race
5. age_cat
6. years_in_care
6. placement_stability

### 2 Populating placement mobility table

This is the first, and currently the only script for populating the table. 

## All other cfsr measures

### 1. Creating the CFSR permanency table

1. dat_year
2. region
3. sex
4. race
5. age_cat
6. cd_discharge
7. perm_months_12_23
8. perm_months_24
9. permanency_12_months
10. re_entry

### Perm first day

This is the second script that needs to be run for the cfsr permanency table. This script populates the table with dat_year, region, sex, age_cat, cd_discharge (discharge type) along with perm_months_12_23 and Perm_months_24

### Perm for entries and re-entries

This is the second script that needs to be run for the cfsr permanency table. This script populates the permanenc_in_12_months and re_entry.


