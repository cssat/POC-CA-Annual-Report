

DECLARE @period VARCHAR(2) = 'AB'
	,@year INT = 2009
	,@dtperiodbeg DATE
	,@dtperiodend DATE
	,@dtmeasureend DATE
	,@dtmeasureend_minus6mo DATE

SET @dtperiodbeg = IIF(@period = 'AB', DATEFROMPARTS(@year - 1, 10, 01), DATEFROMPARTS(@year - 1, 04, 01))
SET @dtperiodend = IIF(@period = 'AB', DATEFROMPARTS(@year, 09, 30), DATEFROMPARTS(@year, 03, 31))

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
		,curplset INT
		,tpr DATE
		,disreasn1 SMALLINT
		,disreasn2 SMALLINT
		,adopted_in_365 TINYINT
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
	,tpr
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
	,CASE
		WHEN tprmomdt IS NULL OR tprdaddt IS NULL THEN NULL
		WHEN tprmomdt > tprdaddt OR tprmomdt = tprmomdt THEN tprmomdt
		WHEN tprmomdt < tprdaddt THEN tprdaddt
		END AS tpr 
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

UPDATE @mytable
	SET dtperiodbeg = @dtperiodbeg
		,dtperiodend = @dtperiodend
		,dtmeasureend = @dtmeasureend
		,dtmeasureend_minus6mo = @dtmeasureend_minus6mo

-- drop records when tpr was not within the period of observation

DELETE @mytable
	WHERE tpr < @dtperiodbeg OR tpr > @dtperiodend

-- drop records of youth who do not have a tpr date

DELETE @mytable
	WHERE tpr IS NULL

-- determine if discharge happened within a year following tpr
-- and if the discharge was to adoption

UPDATE @mytable
	SET adopted_in_365 = CASE
		WHEN disreasn1 = 3 AND [dbo].[fnc_datediff_days](tpr, dodfcdt) <= 365 THEN 1
		ELSE 0
		END

-- Keep the last record for each child

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

DELETE @mytable
	WHERE flag_lastrpt4ep != 1

-- droping records with dq issues

UPDATE @mytable
	SET dq_dropped = CASE WHEN dtreportend = @dtmeasureend THEN 0 ELSE dq_dropped END -- Not sure if needed, keeping for consistency
UPDATE @mytable
	SET dq_indicator = IIF(dq_dobgtdodfcdt= 1 
						OR dq_dobgtlatremdt = 1
						OR dq_dropped = 1
						OR dq_dodfcdteqletremdt = 1
						OR dq_dodfcdtltletremdt = 1
						OR dq_gt21dobtodtdisch= 1
						OR dq_gt21dobtodtlatrem = 1
						OR dq_gt21dtdischtodtlatrem = 1
						OR dq_missDisreasn = 1 -- NEED TO ADD
						OR dq_missdob = 1
						OR dq_missdtlatremdt = 1, 1, 0)

DELETE @mytable
	WHERE dq_indicator = 1


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
	SET exlos8 = IIF(loslatremmocat = 0 AND dodfcdt IS NOT NULL, 1, 0)
		,exagen18 = IIF(agenmosyrscat = 6, 1, 0)

-- delete records of kids over 18 and less than 8 days

DELETE @mytable
	WHERE exlos8 != 0 OR exagen18 != 0

-- Age at tpr

UPDATE @mytable
	SET age_at_entry = [dbo].[fnc_datediff_yrs](dob, tpr)
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

-- Inserting data into table

INSERT INTO annual_report.non_cfsr_permanency
	(
	dat_year
	,region
	,sex
	,race
	,age_cat
	,adopt_in_365
	)

SELECT
	@year AS dat_year
	,r.region_6_cd AS region
	,g.pk_gndr	AS sex
	,e.cd_race AS race
	,a.cd_age_cat AS age_cat
	,SUM(adopted_in_365) * 1.0 / COUNT(m.adopted_in_365) AS 'adopt_in_365'
FROM (SELECT	
		pk_gndr
		,match_code 
	   FROM dbo.prm_gndr 
	   WHERE match_code != 3) AS g
CROSS JOIN [dbo].[prm_region_6] AS r
CROSS JOIN (SELECT DISTINCT 
				cd_race
				,match_code	
			FROM [dbo].[prm_eth_census] 
			WHERE cd_race NOT IN (9, 10, 11, 12)) AS e
CROSS JOIN [annual_report].[age_category] AS a
LEFT JOIN @mytable AS m
	ON m.sex  = g.match_code 
	AND m.region_6_cd = r.match
	AND m.raceeth = e.match_code
	AND m.csfr_age_entry_cat = a.match_code
GROUP BY
	r.region_6_cd
	,g.pk_gndr
	,e.cd_race
	,a.cd_age_cat
ORDER BY
	r.region_6_cd
	,g.pk_gndr
	,e.cd_race
	,a.cd_age_cat
SET @year = @year + 1

SET @dtperiodbeg = IIF(@period = 'AB', DATEFROMPARTS(@year - 1, 10, 01), DATEFROMPARTS(@year - 1, 04, 01))
SET @dtperiodend = IIF(@period = 'AB', DATEFROMPARTS(@year, 09, 30), DATEFROMPARTS(@year, 03, 31))

END
