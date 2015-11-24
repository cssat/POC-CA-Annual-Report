# Preparing AFCARS data for analysis

This script will create a new table and populate it with the AFCARS data based on the Children Bureau's SPSS script for creating the source data for CFSR measures.

## Dependencies

### Tables

1. ref_lookup_county 

2. ref_lookup_county_region

### Functions

1. fnc_datediff_mos: Custom POC function for getting date difference in months.

2. fnc_datediff_yrs: Custom POC function used for getting date difference in years, this function is useful for age.

