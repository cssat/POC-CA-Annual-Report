# Creating Non CFSR Permanency Measures
    
It is important the scripts are run in the correct order since they build off each other and need to be run in the order that they appear below.

## Included Scripts
    
1. create_non_cfsr_permanency
2. adoption_within_one_year_tpr

### Dependencies

1. prm_eth_census: used so that records are counted correctly with their respective race and the all category. POC is using the Children's Bureau race definitions which calssifies anyone with an hispanic backgrund, regardless of race, as hispanic. This is why the WHERE clause filters out 9, 10, 11, 12 since we only need 8 categtories:

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

    - 1. 0 to 5
    - 2. 6 to 11
    - 3. 12 to 17

3. prm_region_6: used so that records are counted correctly with their respective region and the all category.