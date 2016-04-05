
TRUNCATE TABLE [annual_report].[cfsr_permanency]

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
		,disreasn1 SMALLINT
		,disreasn2 SMALLINT
		,age_first_day SMALLINT
		,cfsr_age_cat TINYINT
		,agexmosyrscat SMALLINT
		,dtreportbeg DATE
		,dtreportend DATE
		,dtperiodbeg DATE
		,dtperiodend DATE
		,dtmeasureend DATE
		,dtmeasureend_minus6mo DATE
		,reportedduringperiod BIT
		,flag_lastrpt4ep TINYINT
		,inatstart TINYINT
		,dq_dobgtdodfcdt TINYINT
		,dq_dobgtlatremdt TINYINT
		,dq_dodfcdteqletremdt TINYINT
		,dq_dodfcdtltletremdt TINYINT
		,dq_gt21dobtodtdisch TINYINT
		,dq_gt21dobtodtlatrem TINYINT
		,dq_gt21dtdischtodtlatrem TINYINT
		--,OR dq_missDisreasn
		,dq_missdob TINYINT
		,dq_missdtlatremdt TINYINT
		,dq_dropped TINYINT
		,dq_indicator TINYINT
		,agefdyrs SMALLINT
		,agefdyrscat INT
		,losfddays SMALLINT
		,losfdmo TINYINT
		,lospriorfdmo SMALLINT
		,loslatremdays SMALLINT
		,exlos8 BIT
		,exagefd18 INT
		,losfdmocat TINYINT
		,lospriorfdmocat TINYINT
		,num_child TINYINT
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
	,disreasn1
	,disreasn2
	,agexmosyrscat
	,dtperiodbeg
	,dtperiodend
	,dtmeasureend
	,dtmeasureend_minus6mo
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
	,disreasn1
	,disreasn2
	,agexmosyrscat
	,@dtperiodbeg
	,@dtperiodend
	,@dtmeasureend
	,@dtmeasureend_minus6mo
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
	,dq_dropped
FROM [annual_report].[ca_afcars_source_data]

DELETE @mytable
	WHERE dtreportbeg < dtperiodbeg OR dtreportend > dtperiodend

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

UPDATE @mytable
	SET inatstart = IIF(latremdt < dtperiodbeg AND (dodfcdt >= dtperiodbeg OR dodfcdt IS NULL), 1, 0)

DELETE @mytable
	WHERE inatstart = 0

UPDATE @mytable
	SET dq_dropped = CASE WHEN dtreportend = dtperiodend THEN 0 ELSE dq_dropped END 

UPDATE @mytable
	SET dq_indicator = IIF(dq_dobgtdodfcdt= 1 
							OR dq_dobgtlatremdt = 1
							OR dq_dropped = 1 
							OR dq_dodfcdteqletremdt = 1
							OR dq_dodfcdtltletremdt = 1
							OR dq_gt21dobtodtdisch= 1
							OR dq_gt21dobtodtlatrem = 1
							OR dq_gt21dtdischtodtlatrem = 1
							OR dq_missdob = 1
							OR dq_missdtlatremdt = 1
							, 1, 0)

DELETE @mytable
	WHERE dq_indicator = 1


UPDATE @mytable
	SET agefdyrs = [dbo].[fnc_datediff_yrs](dob, dtperiodbeg) 
	,losfddays = IIF(dodfcdt IS NOT NULL, [dbo].[fnc_datediff_days](dtperiodbeg, dodfcdt), [dbo].[fnc_datediff_days](dtperiodbeg, dtperiodend))
	,losfdmo = IIF(dodfcdt IS NOT NULL, [dbo].[fnc_datediff_mos](dtperiodbeg, dodfcdt), [dbo].[fnc_datediff_mos](dtperiodbeg, dtperiodend))
	,loslatremdays = IIF(dodfcdt IS NOT NULL, [dbo].[fnc_datediff_days](latremdt, dodfcdt), NULL)

UPDATE @mytable
	SET lospriorfdmo = [dbo].[fnc_datediff_mos](latremdt, dtperiodbeg)
	WHERE latremdt IS NOT NULL

-- This is to create a field which has age groupings

UPDATE @mytable
	SET agefdyrscat = CASE
		WHEN agefdyrs = 0 THEN 0
		WHEN agefdyrs BETWEEN 1 AND 5 THEN 1
		WHEN agefdyrs BETWEEN 6 AND 10 THEN 2
		WHEN agefdyrs BETWEEN 11 AND 16 THEN 3
		WHEN agefdyrs = 17 THEN 4
		WHEN agefdyrs BETWEEN 18 AND 21 THEN 5
		WHEN dob > dtperiodbeg OR [dbo].[fnc_datediff_yrs](dob, dtperiodbeg) > 21 THEN 8888
		END

-- Noting if the age is negative or if over 21

UPDATE @mytable
	SET agefdyrs = CASE
		WHEN dob > dtperiodbeg OR [dbo].[fnc_datediff_yrs](dob, dtperiodbeg) > 21 THEN 8888
		ELSE agefdyrs
		END	

-- Adjusting data for youth who have been continuously in care throughout the period

UPDATE @mytable
	SET losfdmo = CASE
		WHEN losfddays = 364 AND (dodfcdt IS NULL OR dodfcdt > dtperiodend) THEN losfdmo + 1
		ELSE losfdmo
		END

UPDATE @mytable
	SET losfddays = CASE
		WHEN losfddays = 364 AND (dodfcdt IS NULL OR dodfcdt > dtperiodend) THEN losfddays + 1
		ELSE losfddays 
		END

-- Creating month categories

UPDATE @mytable
	SET losfdmocat = CASE
		WHEN losfddays < 8 THEN 0
		WHEN losfdmo BETWEEN 12 AND 251 THEN 3
		WHEN losfdmo BETWEEN 6 AND 12 THEN 2
		WHEN losfdmo BETWEEN 0 AND 6 THEN 1
		END

-- used to look at kids in care for 12-23 months from 24 months

UPDATE @mytable
	SET lospriorfdmocat = CASE
		WHEN lospriorfdmo BETWEEN 24 AND 251.99 THEN 4
		WHEN lospriorfdmo BETWEEN 12 AND 23.99 THEN 3
		WHEN lospriorfdmo BETWEEN 6 AND 11.99 THEN 2
		WHEN lospriorfdmo < 6 THEN 1
		END
	WHERE latremdt IS NOT NULL

-- flag episode if it should be included in the numerator

UPDATE @mytable
	SET num_child = CASE 
		WHEN disreasn2 = 1 AND losfdmocat IN (1, 2) AND agexmosyrscat = 6 THEN 0
		WHEN disreasn2 = 1 AND losfdmocat IN (1, 2) THEN 1
		ELSE 0
		END

-- flag for length of stay less than a week

UPDATE @mytable
	SET exlos8 = CASE
		WHEN loslatremdays < 8 AND dodfcdt IS NOT NULL THEN 1
		ELSE 0
		END

-- eliminating the same numner as SPSS

DELETE @mytable	
	WHERE exlos8 = 1

-- age on first day 18 or older

UPDATE @mytable
	SET exagefd18 = CASE
		WHEN agefdyrscat = 5 THEN 1
		WHEN agefdyrscat IN (8888, 9999) THEN 9999
		ELSE 0
		END

DELETE @mytable	
	WHERE exagefd18 IN (1, 9999)

-- Age at entry

UPDATE @mytable
	SET age_first_day = [dbo].[fnc_datediff_yrs](dob, dtperiodbeg)

-- Using the CFSR age categories
-- 1 = 0:5, 2 = 6:11, 3 = 12:17 

UPDATE @mytable
	SET cfsr_age_cat = CASE
		WHEN age_first_day < 6 THEN 1
		WHEN age_first_day < 12 AND age_first_day > 5 THEN 2
		WHEN age_first_day > 11 AND age_first_day < 18 THEN 3
		END

-- SUMMARY STATISTICS
-- PERMANENCY IN 12 MONTHS FOR CHILDREN IN CARE ON FIRST DAY 24 MONTHS OR MORE
-- We have about a dozen less on the no side and about a dozen more on the ues side

INSERT INTO annual_report.cfsr_permanency
    (
     dat_year
     ,region
     ,sex
     ,race
     ,age_cat
     ,cd_discharge
     ,perm_months_12_23
	 ,perm_months_24
    )

SELECT
	@year
	,r.region_6_cd
	,g.pk_gndr
	,e.cd_race
	,a.cd_age_cat
	,d.cd_disreasn
	,SUM(IIF(b.lospriorfdmocat = 3, (b.children * 1.0 / b.counts) * 100, NULL)) AS perm_months_12_23
	,SUM(IIF(b.lospriorfdmocat = 4, (b.children * 1.0 / b.counts) * 100, NULL)) AS perm_months_24
FROM (SELECT DISTINCT region_6_cd FROM dbo.ref_lookup_county_region) r
	CROSS JOIN (SELECT pk_gndr FROM dbo.ref_lookup_gender WHERE cd_gndr != 'U') g
	CROSS JOIN (SELECT DISTINCT cd_race_census AS cd_race FROM dbo.ref_xwalk_race_origin UNION ALL SELECT 0) e
	CROSS JOIN (SELECT cd_age_cat FROM annual_report.cfsr_age_category) a
	CROSS JOIN (SELECT cd_disreasn FROM annual_report.ref_afcars_disreasn WHERE cd_disreasn IN (0, 1, 2, 3, 5)) d
	LEFT JOIN (
	SELECT
		region_6_cd
		,pk_gndr
		,cd_race
		,cd_age_cat
		,cd_disreasn
		,lospriorfdmocat
		,children
		,SUM(IIF(cd_disreasn = 0, counts, 0)) OVER (PARTITION BY region_6_cd, pk_gndr, cd_race, cd_age_cat, lospriorfdmocat) AS counts
	FROM (
		SELECT
			r.region_6_cd
			,g.pk_gndr
			,e.cd_race
			,a.cd_age_cat
			,d.cd_disreasn
			,m.lospriorfdmocat
			,COUNT(DISTINCT CONVERT(VARCHAR(100), m.childid) + '-' + CONVERT(VARCHAR(100), m.dtreportbeg)) AS counts
			,SUM(IIF(d.cd_disreasn IN (0, 1, 2, 3, 5), num_child, 0)) AS children
		FROM @mytable AS m
		JOIN [dbo].[prm_region_6] AS r
			ON m.region_6_cd = r.match
		JOIN dbo.prm_gndr AS g
			ON m.sex = g.match_code
		JOIN (SELECT DISTINCT
					cd_race
					,match_code    
				FROM [dbo].[prm_eth_census]
				WHERE cd_race NOT IN (9, 10, 11, 12)) AS e
			ON m.raceeth = e.match_code
		JOIN [annual_report].[age_category] AS a
			ON m.cfsr_age_cat = a.match_code
		JOIN [annual_report].[disreasn_view] AS d
			ON m.disreasn1 = d.match_code
		WHERE m.lospriorfdmocat IN (3, 4)
		GROUP BY
			r.region_6_cd
			,e.cd_race
			,g.pk_gndr
			,a.cd_age_cat
			,d.cd_disreasn
			,m.lospriorfdmocat 
		) a
	) b 
		ON b.region_6_cd = r.region_6_cd
		AND b.cd_race = e.cd_race
		AND b.pk_gndr = g.pk_gndr
		AND b.cd_age_cat = a.cd_age_cat
		AND b.cd_disreasn = d.cd_disreasn
GROUP BY
	r.region_6_cd
	,g.pk_gndr
	,e.cd_race
	,a.cd_age_cat
	,d.cd_disreasn

SET @year = @year + 1

SET @dtperiodbeg = IIF(@period = 'AB', DATEFROMPARTS(@year - 1, 10, 01), DATEFROMPARTS(@year - 1, 04, 01))
SET @dtperiodend = IIF(@period = 'AB', DATEFROMPARTS(@year, 09, 30), DATEFROMPARTS(@year, 03, 31))

SET @dtmeasureend = IIF(@period = 'AB', DATEFROMPARTS(@year + 2, 09, 30), DATEFROMPARTS(@year + 2, 03, 31))
SET @dtmeasureend_minus6mo = IIF(@period = 'AB', DATEFROMPARTS(@year + 2, 03, 31), DATEFROMPARTS(@year + 1, 09, 30))

END

