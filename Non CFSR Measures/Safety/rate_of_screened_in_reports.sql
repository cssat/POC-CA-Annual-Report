
UPDATE a
SET count_of_screened_in_reports = b.count_of_screened_in_reports
	,screened_in_rate = b.screened_in_rate
FROM annual_report.non_cfsr_safety AS a
LEFT JOIN (SELECT
				cd.fiscal_year_date
				,reg.old_region_cd AS 'region'
				,0 AS 'order'
				,COUNT(*) 'count_of_screened_in_reports'
				,COUNT(*) * 1.0 / sa.count_of_reports * 1000 AS 'Screened_in_rate'
			FROM (SELECT
					rptdt
					,rptcnty
				  FROM [annual_report].[ca_ncands_extracts]) AS ic
			LEFT JOIN (SELECT 
							[old_region_cd]
							,IIF(LEFT(RIGHT(countyfips, 2), 1) = 0, RIGHT(countyfips, 1), RIGHT(countyfips, 2)) AS county_match
					   FROM [dbo].[ref_lookup_county]
					   WHERE old_region_cd > 0
					   UNION ALL
					   SELECT 
							0 AS old_region_cd
							,IIF(LEFT(RIGHT(countyfips, 2), 1) = 0, RIGHT(countyfips, 1), RIGHT(countyfips, 2)) AS county_match
					   FROM [dbo].[ref_lookup_county]
					   WHERE old_region_cd > 0) AS reg
				ON ic.rptcnty = reg.county_match
			LEFT JOIN (SELECT DISTINCT
							FEDERAL_FISCAL_YEAR AS fiscal_year_date
							,CALENDAR_DATE AS date_match
					   FROM [dbo].[CALENDAR_DIM]) AS cd
				ON ic.rptdt = cd.date_match
			LEFT JOIN annual_report.non_cfsr_safety AS sa
				ON sa.fiscal_year_date = cd.fiscal_year_date
				AND sa.region = reg.old_region_cd
			GROUP BY
				cd.fiscal_year_date
				,reg.old_region_cd
				,sa.count_of_reports) AS b
ON a.fiscal_year_date = b.fiscal_year_date
AND a.region = b.region
AND a.[order] = b.[order]


