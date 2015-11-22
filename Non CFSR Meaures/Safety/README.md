# Creating Non CFSR Safety Measures

It is important the scripts are run in the correct order since they build off each other and need to be run in the order that they appear below.

## Included Scripts
    
    - create_non_cfsr_safety
    - rate_of_reports
    - rate_of_screened_in_reports
    - rate_of_placement

### Dependencies

Each of the table creation scripts have some depencies on other tables in the POC database, some table provided by CA, and some that POC created. Below is a description of each of the tables:

    - calendar_dim: used to aggregate reports into proper month and fiscal year. This table was provided to POC by CA.
        - used by rate_of_reports, rate_of_screened_in_reports, rate_of_placement
    - ref_lookup_county: used to create inline views so that records are counted in the correct region and at the state level. The table is also used to match our population table to the correct regions. Columns in the table include county name, codes for 3 and 6 regions, text for 6 regions and the 5 digit county fips
    -

> 1. Script uses a calendar table allows us to aggregate reports by month in the proper federal fiscal year. The table that POC uses was provided by CA (calendar_dim), please check schema in script before running.  
> 2. Script uses a table to lookup region and county, this is used in two places. In the POC data base this table is called ref_lookup_county and has columns for county name, codes for 3 and 6 regions, text for 6 regions and the county fips.
> 3. 



### 1. Creating the non CFSR table

This is the first script that needs to be run and it creates an empty table with 9 columns:

    - fiscal_date: months in each fiscal year as a calendar date
    - region: uses six regions along with 0 for all regions
    - order: this is used to distinguish from order specific non CFSR measures which are not currently included
    - count_of_reports: populated by rate_of_reports and used by rate_of_screened_in_reports
	- report_rate: populated by rate_of_reports
	- count_of_screened_in_reports: populated by rate_of_reports and used by rate_of_placement
	- screened_in_rate: populated by rate_of_reports
	- count_of_placements: populated by rate_of_placement
	- placement_rate: populated by rate_of_placement, not used by the other measures but kept for consistency

### 2. Populating table with rate of reports

This is the second script that needs to be run and uses the rptIntake_children table as the basis for getting the count of reports. This table also has a handful of dependencies that it relies on: 
> 1. Script uses a calendar table allows us to aggregate reports by month in the proper federal fiscal year. The table that POC uses was provided by CA (calendar_dim), please check schema in script before running.  
> 2. Script uses a table to lookup region and county, this is used in two places. In the POC data base this table is called ref_lookup_county and has columns for county name, codes for 3 and 6 regions, text for 6 regions and the county fips.
> 3. 


### 3. Populating table with rate of screened-in reports

### 4. Populating table with rate of placement
