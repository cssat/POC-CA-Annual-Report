
UPDATE a
SET count_of_placements = b.count_of_placements
	,placement_rate = b.placement_rate
FROM annual_report.non_cfsr_safety AS a
LEFT JOIN (SELECT
				cd.fiscal_year
				,region
				,0 AS 'order'
				,COUNT(*) AS 'count_of_placements'
				,COUNT(*) * 1.0 / sa.count_of_screened_in_reports * 1000 AS placement_rate
			FROM
				(SELECT 
					rptdt
					,rptcnty
					,DENSE_RANK() OVER (PARTITION BY chid, rptdisdt ORDER BY rptdt DESC) AS rpt_rank
				FROM [annual_report].[ca_ncands_extracts]
				WHERE fostercr = 1) AS ic
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
							FEDERAL_FISCAL_YEAR AS fiscal_year
							,CALENDAR_DATE AS date_match
						FROM [dbo].[CALENDAR_DIM]) AS cd
				ON ic.rptdt = cd.date_match
			JOIN annual_report.non_cfsr_safety AS sa
				ON sa.fiscal_year = cd.fiscal_year
				AND sa.region = reg.old_region_cd
			--WHERE rpt_rank = 1
			GROUP BY 
				cd.fiscal_year
				,region
				,sa.count_of_screened_in_reports) AS b
ON a.fiscal_year = b.fiscal_year
AND a.region = b.region
AND a.[order] = b.[order]

