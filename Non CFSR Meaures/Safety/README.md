# Creating Non CFSR Safety Measures

It is important the scripts are run in the correct order since they build off each other and need to be run in the order that they appear below.

## Included Scripts
    
    - create_non_cfsr_safety
    - rate_of_reports
    - rate_of_screened_in_reports
    - rate_of_placement
    
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

This is the second script that needs to be run and uses the rptIntake_children table as the basis for gett9ing the count of reports. This table also has a handful of dependecies that it relies on: \
> 1. Script uses calendar_dim table allows us to aggregate reports by month in the proper federal fiscal year. The table that POC uses was provided by CA, please check schema in script before running.  
> 2. 


### 3. Populating table with rate of screened-in reports

### 4. Populating table with rate of placement
