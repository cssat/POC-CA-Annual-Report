

DECLARE @period VARCHAR(2) = 'AB'
	,@year INT = 2009
	,@dtperiodbeg DATE
	,@dtperiodend DATE
	,@dtmeasureend DATE
	,@dtmeasureend_minus6mo DATE

SET @dtperiodbeg = IIF(@period = 'AB', DATEFROMPARTS(@year - 1, 10, 01), DATEFROMPARTS(@year - 1, 04, 01))
SET @dtperiodend = IIF(@period = 'AB', DATEFROMPARTS(@year, 09, 30), DATEFROMPARTS(@year, 03, 31))

SET @dtmeasureend = IIF(@period = 'AB', DATEFROMPARTS(@year + 2, 09, 30), DATEFROMPARTS(@year + 2, 03, 31))
SET @dtmeasureend_minus6mo = IIF(@period = 'AB', DATEFROMPARTS(@year + 2, 03, 31), DATEFROMPARTS(@year + 1, 09, 30))

DECLARE @mytable TABLE
		(
		childid INT
		,recnumbr INT
		,repdat INT
		,dob DATE
		,sex TINYINT
		,raceeth TINYINT
		,region_6_cd VARCHAR (18)
		,latremdt DATE
		,dodfcdt DATE
		,dlstfcdt DATE
		,cursetdt DATE
		,curplset SMALLINT
		,disreasn SMALLINT
		,disreasn1 SMALLINT
		,disreasn2 SMALLINT
		,totalrem SMALLINT
		,age_at_entry TINYINT
		,age_at_exit TINYINT
		,csfr_age_entry_cat TINYINT
		,csfr_age_exit_cat TINYINT
		,agexmosyrscat SMALLINT
		,dtreportbeg DATE
		,dtreportend DATE
		,dtperiodbeg DATE
		,dtperiodend DATE
		,dtmeasureend DATE
		,dtmeasureend_minus6mo DATE
		,reportedduringperiod BIT
		,flag_lastrpt4ep TINYINT
		,timetoreentry_temp INT
		,timetoreentry INT
		,entered BIT
		,primaryfirst TINYINT
		,dq_dobgtdodfcdt BIT
		,dq_dobgtlatremdt BIT
		,dq_dodfcdteqletremdt BIT
		,dq_dodfcdtltletremdt BIT
		,dq_gt21dobtodtdisch BIT
		,dq_gt21dobtodtlatrem BIT
		,dq_gt21dtdischtodtlatrem BIT
		,dq_missdob BIT
		,dq_missdtlatremdt BIT
		,dq_missdisreasn BIT
		,dq_dropped BIT
		,dq_indicator BIT
		,loslatremdays INT
		,precursetlos SMALLINT
		,loslatremmo TINYINT
		,precursetlosmo TINYINT
		,loslatremmocat TINYINT
		,agenmosyrscat TINYINT
		,exlos8 BIT
		,exagen18 INT
		,den_child TINYINT
		,num_child TINYINT
		,denre_child TINYINT
		,numre_child TINYINT
		,UNIQUE(childid,
			dtreportbeg) 
		)

-------------------
-- START OF LOOP --
-------------------
 
WHILE @year <= 2015
BEGIN 
DELETE @mytable

INSERT INTO @mytable

	(childid
	,recnumbr
	,repdat
	,dob
	,sex
	,raceeth
	,region_6_cd
	,latremdt 
	,dodfcdt 
	,dlstfcdt 
	,cursetdt 
	,curplset
	,disreasn1
	,disreasn2
	,totalrem
	,agenmosyrscat
	,dtreportbeg 
	,dtreportend 
	,dq_dobgtdodfcdt 
	,dq_dobgtlatremdt 
	,dq_dodfcdteqletremdt 
	,dq_dodfcdtltletremdt 
	,dq_gt21dobtodtdisch
	,dq_gt21dobtodtlatrem
	,dq_gt21dtdischtodtlatrem 
	,dq_missdob 
	,dq_missdtlatremdt
	,dq_missdisreasn
	,dq_dropped)
	
SELECT
	childid
	,recnumbr
	,repdat
	,dob
	,sex
	,raceeth
	,region_6_cd
	,latremdt 
	,dodfcdt 
	,dlstfcdt 
	,cursetdt 
	,curplset
	,disreasn1
	,disreasn2
	,totalrem
	,agenmosyrscat
	,dtreportbeg 
	,dtreportend 
	,dq_dobgtdodfcdt 
	,dq_dobgtlatremdt 
	,dq_dodfcdteqletremdt 
	,dq_dodfcdtltletremdt 
	,dq_gt21dobtodtdisch
	,dq_gt21dobtodtlatrem
	,dq_gt21dtdischtodtlatrem 
	,dq_missdob 
	,dq_missdtlatremdt
	,dq_missdisreasn
	,dq_dropped
FROM [annual_report].[ca_afcars_source_data]

-- Delete case that aren't in the period of observation

DELETE @mytable
	WHERE dtreportbeg < @dtperiodbeg OR dtreportend > @dtmeasureend

-- Identify cases the final case for each child by last removal

UPDATE A
	SET flag_lastrpt4ep = B.flag_lastrpt4ep
	FROM @mytable AS A
		JOIN (SELECT
					childid
					,dtreportbeg 
					,RANK() OVER (PARTITION BY childid, latremdt ORDER BY dtreportbeg DESC) AS flag_lastrpt4ep
				FROM @mytable) AS B
				ON A.childid = B.childid
				AND A.dtreportbeg = B.dtreportbeg

-- Delete all but final report for each child, based on last removal date

DELETE @mytable
	WHERE flag_lastrpt4ep != 1

-- Identify time to re-entry

UPDATE @mytable
	SET timetoreentry_temp = IIF(totalrem > 1 AND latremdt > dlstfcdt, [dbo].[fnc_datediff_mos](dlstfcdt, latremdt), 0)

UPDATE A
	SET timetoreentry = B.timetoreentry
	FROM @mytable AS A
		JOIN (SELECT
					childid
					,dtreportbeg 
					,repdat
					,IIF(LEAD(childid, 1, 0) OVER (PARTITION BY childid ORDER BY childid ASC, latremdt ASC) != childid, NULL, 
						LAG(timetoreentry_temp, 1, NULL) OVER(PARTITION BY childid ORDER BY latremdt DESC)) AS timetoreentry
				FROM @mytable) AS B
				ON A.childid = B.childid
				AND A.repdat = B.repdat

-- Identify if child entered during period of observation

UPDATE @mytable
	SET entered = IIF(latremdt >= @dtperiodbeg AND latremdt <= @dtperiodend, 1, 0) 

-- Delete records for children that did not enter during period of observation

DELETE @mytable
	WHERE entered != 1 

UPDATE A
	SET primaryfirst = B.primaryfirst
	FROM @mytable AS A
		JOIN (SELECT
					childid
					,dtreportbeg 
					,RANK() OVER (PARTITION BY childid ORDER BY repdat ASC) AS primaryfirst
				FROM @mytable) AS B
				ON A.childid = B.childid
				AND A.dtreportbeg = B.dtreportbeg

DELETE @mytable
	WHERE primaryfirst != 1

-- Identift records with DQ issues

UPDATE @mytable
	SET dq_dropped = CASE WHEN dtreportend = @dtmeasureend THEN 0 ELSE dq_dropped END

UPDATE @mytable
	SET dq_indicator = IIF(dq_dobgtdodfcdt= 1 
						OR dq_dobgtlatremdt = 1
						OR dq_dropped = 1
						OR dq_dodfcdteqletremdt = 1
						OR dq_dodfcdtltletremdt = 1
						OR dq_gt21dobtodtdisch= 1
						OR dq_gt21dobtodtlatrem = 1
						OR dq_gt21dtdischtodtlatrem = 1
						OR dq_missDisreasn = 1 
						OR dq_missdob = 1
						OR dq_missdtlatremdt = 1, 1, 0)

-- Drop records with DQ issues

DELETE @mytable
	WHERE dq_indicator = 1

-- numbers are good through the dq variables

UPDATE @mytable
	SET loslatremdays = IIF(dodfcdt IS NOT NULL, [dbo].[fnc_datediff_days](latremdt, dodfcdt), [dbo].[fnc_datediff_days](latremdt, @dtmeasureend))
		,precursetlos = IIF(cursetdt IS NOT NULL AND latremdt IS NOT NULL AND cursetdt > latremdt, [dbo].[fnc_datediff_days](latremdt, cursetdt), NULL)
		,precursetlosmo = IIF(cursetdt IS NOT NULL AND latremdt IS NOT NULL AND cursetdt > latremdt, [dbo].[fnc_datediff_mos](latremdt, cursetdt), NULL)
		,loslatremmo = IIF(dodfcdt IS NOT NULL, [dbo].[fnc_datediff_mos](latremdt, dodfcdt), [dbo].[fnc_datediff_mos](latremdt, @dtmeasureend))

UPDATE @mytable
	SET loslatremdays = precursetlos + 30
	WHERE dodfcdt IS NOT NULL AND cursetdt < dodfcdt 
		AND precursetlos IS NOT NULL 
		AND disreasn1 = 1 
		AND curplset = 8 and [dbo].[fnc_datediff_days](cursetdt, dodfcdt) > 30

UPDATE @mytable
	SET loslatremmo = precursetlosmo + 1
	WHERE dodfcdt IS NOT NULL AND cursetdt < dodfcdt 
		AND disreasn1 = 1 
		AND precursetlos IS NOT NULL 
		AND curplset = 8 and [dbo].[fnc_datediff_days](cursetdt, dodfcdt) > 30

UPDATE @mytable
	SET loslatremmocat = CASE
		WHEN loslatremmo BETWEEN 42 AND 251 THEN 8
		WHEN loslatremmo BETWEEN 36 AND 42 THEN 7
		WHEN loslatremmo BETWEEN 30 AND 36 THEN 6
		WHEN loslatremmo BETWEEN 24 AND 30 THEN 5
		WHEN loslatremmo BETWEEN 18 AND 24 THEN 4
		WHEN loslatremmo BETWEEN 12 AND 18 THEN 3
		WHEN loslatremmo BETWEEN 6 AND 12 THEN 2
		WHEN loslatremmo BETWEEN 0 AND 6 THEN 1	 	
		END

UPDATE @mytable
	SET loslatremmocat = CASE
		WHEN loslatremdays < 8 THEN 0
		ELSE loslatremmocat
		END

UPDATE @mytable
	SET den_child = 1 

UPDATE @mytable
	SET num_child = IIF(disreasn2 = 1 AND loslatremmocat IN (1, 2), 1, 0)


UPDATE @mytable
	SET denre_child = IIF(disreasn1 IN (1, 2, 5) AND loslatremmocat IN (1, 2), 1, 0)
		,numre_child = IIF(disreasn1 IN (1, 2, 5) AND loslatremmocat IN (1, 2) AND timetoreentry < 12, 1, 0)
		,exlos8 = IIF(loslatremmocat = 0 AND dodfcdt IS NOT NULL, 1, 0)
		,exagen18 = IIF(agenmosyrscat = 6, 1, 0)

DELETE @mytable
	WHERE exlos8 != 0 OR exagen18 != 0

-- Age at entry

UPDATE @mytable
	SET age_at_entry = [dbo].[fnc_datediff_yrs](dob, latremdt)
	,age_at_exit = [dbo].[fnc_datediff_yrs](dob, dodfcdt)

-- Using the CSFR age categories
-- 1 = 0:5, 2 = 6:11, 3 = 12:17 

UPDATE @mytable
	SET csfr_age_entry_cat = CASE
		WHEN age_at_entry < 6 THEN 1
		WHEN age_at_entry < 12 AND age_at_entry > 5 THEN 2
		WHEN age_at_entry > 11 AND age_at_entry < 18 THEN 3
		END
		,csfr_age_exit_cat = CASE
		WHEN age_at_exit < 6 THEN 1
		WHEN age_at_exit < 12 AND age_at_exit > 5 THEN 2
		WHEN age_at_exit > 11 AND age_at_exit < 18 THEN 3
		END

-- Perm in 12 (Entries) numerator - Child exited to permanency 
-- (all types) within 12 months of entering care

UPDATE a
SET
	permanency_12_months = id.permanency_12_months * 100
FROM annual_report.cfsr_permanency AS a
	LEFT JOIN (SELECT
					@year AS dat_year
					,r.region_6_cd
					,g.pk_gndr
					,e.cd_race
					,a.cd_age_cat
					,d.cd_disreasn
					,(SUM(num_child) * 1.0 / counts) AS 'permanency_12_months'
				FROM dbo.prm_gndr AS g
				JOIN @mytable AS m
					ON g.match_code = m.sex
				JOIN [dbo].[prm_region_6] AS r
					ON m.region_6_cd = r.match
				JOIN (SELECT DISTINCT
							cd_race
							,match_code	
						FROM [dbo].[prm_eth_census]
						WHERE cd_race NOT IN (9, 10, 11, 12)) AS e
					ON m.raceeth = e.match_code
				JOIN [annual_report].[age_category] AS a
					ON m.csfr_age_entry_cat = a.match_code
				JOIN [annual_report].[disreasn_view] AS d
					ON m.disreasn1 = d.match_code
					AND d.cd_disreasn IN (0, 1, 2, 3, 5)
				JOIN (SELECT 
							r.region_6_cd
							,e.cd_race
							,g.pk_gndr
							,a.cd_age_cat
							,COUNT(*) AS counts
						FROM @mytable AS m
						JOIN [dbo].[prm_region_6] AS r
							ON m.region_6_cd = r.match
						JOIN (SELECT DISTINCT
									cd_race
									,match_code	
								FROM [dbo].[prm_eth_census]
								WHERE cd_race NOT IN (9, 10, 11, 12)) AS e
							ON m.raceeth = e.match_code
						JOIN dbo.prm_gndr AS g
							ON m.sex = g.match_code
						JOIN [annual_report].[age_category] AS a
							ON m.csfr_age_entry_cat = a.match_code
						GROUP BY
							r.region_6_cd
							,e.cd_race
							,g.pk_gndr
							,a.cd_age_cat) AS id
				ON g.pk_gndr = id.pk_gndr
					AND r.region_6_cd = id.region_6_cd
					and e.cd_race = id.cd_race
					AND a.cd_age_cat = id.cd_age_cat
				GROUP BY
					r.region_6_cd
					,e.cd_race
					,g.pk_gndr
					,a.cd_age_cat
					,d.cd_disreasn
					,counts) AS id
ON a.dat_year = id. dat_year
	AND a.region = id.region_6_cd
	AND a.sex = id.pk_gndr
	AND a.race = id.cd_race
	AND a.age_cat = id.cd_age_cat
	AND a.cd_discharge = id.cd_disreasn
WHERE a.dat_year = @year

---------------------------------
-- Re-Entry To FC in 12 Months --
---------------------------------

UPDATE a
SET
	re_entry = id.re_entry * 100
FROM annual_report.cfsr_permanency AS a
	LEFT JOIN (SELECT
					@year AS dat_year
					,r.region_6_cd
					,g.pk_gndr
					,e.cd_race
					,a.cd_age_cat
					,d.cd_disreasn
					,(SUM(numre_child) * 1.0 / counts) AS 're_entry'
				FROM dbo.prm_gndr AS g
				JOIN @mytable AS m
					ON g.match_code = m.sex
				JOIN [dbo].[prm_region_6] AS r
					ON m.region_6_cd = r.match
				JOIN (SELECT DISTINCT
							cd_race
							,match_code	
						FROM [dbo].[prm_eth_census]
						WHERE cd_race NOT IN (9, 10, 11, 12)) AS e
					ON m.raceeth = e.match_code
				JOIN [annual_report].[age_category] AS a
					ON m.csfr_age_entry_cat = a.match_code
				JOIN [annual_report].[disreasn_view] AS d
					ON m.disreasn1 = d.match_code
					AND d.cd_disreasn IN (0, 1, 2, 3, 5)
				JOIN (SELECT 
							r.region_6_cd
							,e.cd_race
							,g.pk_gndr
							,a.cd_age_cat
							,COUNT(*) AS counts
						FROM @mytable AS m
						JOIN [dbo].[prm_region_6] AS r
							ON m.region_6_cd = r.match
						JOIN (SELECT DISTINCT
									cd_race
									,match_code	
								FROM [dbo].[prm_eth_census]
								WHERE cd_race NOT IN (9, 10, 11, 12)) AS e
							ON m.raceeth = e.match_code
						JOIN dbo.prm_gndr AS g
							ON m.sex = g.match_code
						JOIN [annual_report].[age_category] AS a
							ON m.csfr_age_entry_cat = a.match_code
						WHERE denre_child = 1
						GROUP BY
							r.region_6_cd
							,e.cd_race
							,g.pk_gndr
							,a.cd_age_cat) AS id
				ON g.pk_gndr = id.pk_gndr
					AND r.region_6_cd = id.region_6_cd
					and e.cd_race = id.cd_race
					AND a.cd_age_cat = id.cd_age_cat
				GROUP BY
					r.region_6_cd
					,e.cd_race
					,g.pk_gndr
					,a.cd_age_cat
					,d.cd_disreasn
					,counts) AS id
ON a.dat_year = id. dat_year
	AND a.region = id.region_6_cd
	AND a.sex = id.pk_gndr
	AND a.race = id.cd_race
	AND a.age_cat = id.cd_age_cat
	AND a.cd_discharge = id.cd_disreasn
WHERE a.dat_year = @year

SET @year = @year + 1

SET @dtperiodbeg = IIF(@period = 'AB', DATEFROMPARTS(@year - 1, 10, 01), DATEFROMPARTS(@year - 1, 04, 01))
SET @dtperiodend = IIF(@period = 'AB', DATEFROMPARTS(@year, 09, 30), DATEFROMPARTS(@year, 03, 31))

SET @dtmeasureend = IIF(@period = 'AB', DATEFROMPARTS(@year + 2, 09, 30), DATEFROMPARTS(@year + 2, 03, 31))
SET @dtmeasureend_minus6mo = IIF(@period = 'AB', DATEFROMPARTS(@year + 2, 03, 31), DATEFROMPARTS(@year + 1, 09, 30))

END
