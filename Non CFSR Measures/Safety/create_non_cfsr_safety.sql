
IF OBJECT_ID ('annual_report.non_cfsr_safety') IS NOT NULL DROP TABLE annual_report.non_cfsr_safety

CREATE TABLE annual_report.non_cfsr_safety
(
	fiscal_year_date DATE
	,fiscal_year INT
	,region TINYINT
	,[order] TINYINT
	,count_of_reports INT
	,report_rate DECIMAL (8, 4)
	,count_of_screened_in_reports INT
	,screened_in_rate DECIMAL (8, 4)
	,count_of_placements INT
	,placement_rate DECIMAL (8, 4)
)

