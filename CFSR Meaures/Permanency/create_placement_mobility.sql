

IF OBJECT_ID ('annual_report.cfsr_permanency_placement_mobility') IS NOT NULL DROP TABLE annual_report.cfsr_permanency_placement_mobility

 CREATE TABLE annual_report.cfsr_permanency_placement_mobility
 (
	dat_year SMALLINT
	,region TINYINT
	,sex TINYINT
	,race TINYINT
	,age_cat SMALLINT
	,years_in_care TINYINT
	,placement_stability DECIMAL (8, 4)
 )

