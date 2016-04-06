

IF OBJECT_ID ('annual_report.cfsr_safety') IS NOT NULL DROP TABLE annual_report.cfsr_safety

 CREATE TABLE annual_report.cfsr_safety
 (
	dat_year SMALLINT
	,maltreatment_in_care DECIMAL (7, 4)
	,recurrence_of_maltreatment DECIMAL (7, 4)
 )

