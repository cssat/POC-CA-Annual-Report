

IF OBJECT_ID ('annual_report.cfsr_permanency') IS NOT NULL DROP TABLE annual_report.cfsr_permanency

 CREATE TABLE annual_report.cfsr_permanency
 (
	dat_year SMALLINT
	,region TINYINT -- IF NO NULLS THEN USE 'NOT NULL'
	,sex TINYINT
	,race TINYINT
	,age_cat SMALLINT
	,cd_discharge TINYINT
	,perm_months_12_23 DECIMAL (7, 4)
	,perm_months_24 DECIMAL (7, 4)
	,permanency_12_months DECIMAL (7, 4)
	,re_entry DECIMAL (7, 4)
 )
