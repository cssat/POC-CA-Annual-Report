
INSERT INTO annual_report.non_cfsr_safety
    (
	fiscal_date
	,region
	,[order]
	,count_of_reports
	,referral_rate
    )

SELECT 
	fiscal_date
	,reg.old_region_cd
	,report_order
	,COUNT(*) AS 'count_of_reports'
	,COUNT(*) * 1.0 / pop_cnt * 1000 AS 'report_rate'
FROM (SELECT
		ID_ACCESS_REPORT
		,DT_ACCESS_RCVD
		,VICS_ID_CHILDREN
		,0 AS 'report_order'
		,COALESCE(IIF(CD_CASE_REGION between 1 and 6, CD_CASE_REGION, NULL), 
			IIF(CD_WRKR_REGION between 1 and 6, CD_WRKR_REGION, NULL),
			IIF(REGION IN ('Region 1', 'Region 2', 'Region 3', 'Region 4', 'Region 5', 'Region 6'), 
				RIGHT(REGION, 1), NULL), 0) AS region
		,CASE
			WHEN VICS_ID_CHILDREN != 0 AND  
				DATEDIFF(DAY, LAG(DT_ACCESS_RCVD, 1, 0) 
				OVER (PARTITION BY VICS_ID_CHILDREN ORDER BY DT_ACCESS_RCVD), DT_ACCESS_RCVD) <= 14
				THEN 0
				ELSE 1
			END AS drop_flag
		FROM [base].[rptIntake_children]
		WHERE CPS_YESNO = 'Yes') AS ic
LEFT JOIN (SELECT DISTINCT
				FEDERAL_FISCAL_MONTH AS fiscal_date
				,CALENDAR_DATE AS date_match
			FROM [dbo].[CALENDAR_DIM]
			WHERE FEDERAL_FISCAL_YYYY BETWEEN 2010 AND 2014) AS cd
	ON CONVERT(DATE, DT_ACCESS_RCVD) = cd.date_match
LEFT JOIN (SELECT DISTINCT
				0 AS old_region_cd
				,old_region_cd AS region_match
			FROM [dbo].[ref_lookup_county]
			WHERE old_region_cd != -99
			UNION ALL
			SELECT DISTINCT
				old_region_cd
				,old_region_cd AS region_match
			FROM [dbo].[ref_lookup_county]
			WHERE old_region_cd > 0) AS reg
	ON ic.region = reg.region_match
LEFT JOIN (SELECT 
				year
				,reg.old_region_cd
				,SUM(pop.pop_cnt) AS pop_cnt
			FROM [public_data].[mb_census_population] AS pop
			LEFT JOIN (SELECT DISTINCT
							0 AS old_region_cd
							,county_desc AS region_match
						FROM [dbo].[ref_lookup_county]
						UNION ALL
						SELECT DISTINCT
							old_region_cd
							,county_desc AS region_match
						FROM [dbo].[ref_lookup_county]) AS reg
				ON pop.county_desc = reg.region_match
			GROUP BY
				year
				,reg.old_region_cd) AS pop
ON pop.year = YEAR(fiscal_date)
	AND pop.old_region_cd = reg.old_region_cd
WHERE drop_flag = 1
	AND fiscal_date IS NOT NULL
GROUP BY
	fiscal_date
	,reg.old_region_cd
	,report_order
	,pop_cnt
ORDER BY
	fiscal_date
	,reg.old_region_cd
	,report_order


SELECT * FROM [dbo].[ref_lookup_county]
