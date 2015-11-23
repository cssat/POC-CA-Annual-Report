
IF OBJECT_ID ('annual_report.non_cfsr_permanency') IS NOT NULL DROP TABLE annual_report.non_cfsr_permanency

 CREATE TABLE annual_report.non_cfsr_permanency
 (
	dat_year SMALLINT
	,region TINYINT
	,sex TINYINT
	,race TINYINT
	,age_cat SMALLINT
	,adopt_in_365 DECIMAL (7, 4)
 )


