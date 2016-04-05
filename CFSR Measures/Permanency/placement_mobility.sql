
-- table variable

DECLARE @period VARCHAR(2) = 'AB'
	,@year INT = 2009
	,@dtperiodbeg DATE
	,@dtperiodend DATE

SET @dtperiodbeg = IIF(@period = 'AB', DATEFROMPARTS(@year - 1, 10, 01), DATEFROMPARTS(@year - 1, 04, 01))
SET @dtperiodend = IIF(@period = 'AB', DATEFROMPARTS(@year, 09, 30), DATEFROMPARTS(@year, 03, 31))

DECLARE @mytable TABLE
		(
		childid INT
		,recnumbr INT
		,repdat INT
		,dob DATE
		,sex TINYINT
		,amiakn TINYINT
		,asian TINYINT
		,blkafram TINYINT
		,hawaiipi TINYINT
		,white TINYINT
		,untodetm TINYINT
		,hisorgin TINYINT
		,raceeth TINYINT
		,region_6_cd VARCHAR (18)
		,latremdt DATE
		,dodfcdt DATE
		,cursetdt DATE
		,disreasn2 SMALLINT
		,numplep TINYINT
		,age_at_entry SMALLINT
		,csfr_age_cat TINYINT
		,agexmosyrscat SMALLINT
		,agenmosyrscat TINYINT
		,agenmosyrs SMALLINT
		,tremcat TINYINT
		,dtreportbeg DATE
		,dtreportend DATE
		,dtreportendfinal DATE
		,reportedduringperiod BIT
		,flag_lastrpt4ep TINYINT
		,entered BIT
		,dq_dropped TINYINT
		,dq_dobgtdodfcdt TINYINT
		,dq_dobgtlatremdt TINYINT
		,dq_dodfcdteqletremdt TINYINT
		,dq_dodfcdtltletremdt TINYINT
		,dq_gt21dobtodtdisch TINYINT
		,dq_gt21dobtodtlatrem TINYINT
		,dq_gt21dtdischtodtlatrem TINYINT
		,dq_missdob TINYINT
		,dq_missdtlatremdt TINYINT
		,dq_indicator TINYINT
		,dq_missnumplep TINYINT
		,bday18 DATE
		,dodfcdtadjusted DATE
		,adjust18 BIT
		,exited BIT
		,loslatremdays SMALLINT
		,exlos8 TINYINT
		,exagen18 BIT
		,numplepadjust TINYINT
		,den_child SMALLINT
		,num_child SMALLINT
		,movesgtdays BIT
		,tremcat_first TINYINT
		,agenmosyrscat_first TINYINT
		,agenmosyrs_first TINYINT
		,flag_lastrpt4ch TINYINT
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

	(
	childid
	,recnumbr
	,repdat
	,dob
	,sex
	,amiakn
	,asian
	,blkafram
	,hawaiipi
	,white
	,untodetm
	,hisorgin
	,raceeth
	,region_6_cd
	,latremdt
	,dodfcdt 
	,cursetdt
	,disreasn2
	,numplep
	,agexmosyrscat
	,agenmosyrscat
	,agenmosyrs
	,tremcat
	,dtreportbeg 
	,dtreportend 
	,dtreportendfinal 
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
	,dq_missnumplep)
	
SELECT
	childid
	,recnumbr
	,repdat
	,dob
	,sex
	,amiakn
	,asian
	,blkafram
	,hawaiipi
	,white
	,untodetm
	,hisorgin
	,raceeth
	,region_6_cd
	,latremdt
	,dodfcdt 
	,cursetdt
	,disreasn2
	,numplep
	,agexmosyrscat
	,agenmosyrscat
	,agenmosyrs
	,tremcat
	,dtreportbeg 
	,dtreportend 
	,dtreportendfinal 
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
	,dq_missnumplep
FROM [annual_report].[ca_afcars_source_data]

-- Delete records not reported during this period

DELETE @mytable
	WHERE dtreportbeg < @dtperiodbeg OR dtreportend > @dtperiodend

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
	SET entered = IIF(latremdt >= @dtperiodbeg AND latremdt <= @dtperiodend, 1, 0)

DELETE @mytable
	WHERE entered = 0

UPDATE @mytable
	SET dq_dropped = CASE WHEN dtreportend = @dtperiodend THEN 0 ELSE dq_dropped END 

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
							OR dq_missnumplep = 1
							, 1, 0)

DELETE @mytable
	WHERE dq_indicator = 1

-- ****************************************************
-- ADJUST DISCHARGE DATES FOR YOUTH WHO TURN 18
-- ****************************************************
-- 
-- * Youth who turn 18 during the 12-month period will not have time in care beyond their
-- * 18th birthday or moves after their 18th birthday counted. To handle this, for children who 
-- * turn 18 during the period we replace their discharge date with the date they turned 18. 
-- * Therefore, the LOS for children who turn 18 during the period will be calculated from date of latest
-- * removal to date of 18th birthday.
-- ****************************************************

UPDATE @mytable
	 SET bday18 = DATEADD(YEAR, 18, dob)

UPDATE @mytable
	 SET dodfcdtadjusted = CASE
		WHEN bday18 > @dtperiodbeg AND bday18 <= @dtperiodend AND (dodfcdt IS NULL OR dodfcdt > bday18) THEN bday18
		ELSE dodfcdt
		END
	,adjust18 = CASE
		WHEN bday18 > @dtperiodbeg AND bday18 <= @dtperiodend AND (dodfcdt IS NULL OR dodfcdt > bday18) THEN 1
		END

-- *****************************************
-- CALCULATE LENGTH OF STAY FOR EACH EPISODE
-- *****************************************

-- Identify children who exited during the 12-month period (needed later).

UPDATE @mytable
	 SET exited = IIF(dodfcdt >= @dtperiodbeg AND dodfcdt <= @dtperiodend, 1, 0)

-- * LOS (days) between date of latest removal from home and date of discharge (or last date in the 12-month period)

UPDATE @mytable
	SET loslatremdays = CASE
		WHEN exited = 1 THEN [dbo].[fnc_datediff_days](latremdt, dodfcdtadjusted)
		WHEN exited = 0 THEN [dbo].[fnc_datediff_days](latremdt, @dtperiodend)
		END

--****************************************************
--IDENTIFY AND REMOVE EPISODES THAT MEET EXCLUSION CRITERIA
--****************************************************
--
-- The denominator for this indicator is the sum of children's LOS (days) across *all* episodes during the 
-- 12-month period. So if a child entered twice during the 12-month periods, his total LOS is the LOS from his
-- first episode plus the LOS from his second episode. However, when summing a child's LOS over all his episodes
-- in the 12-month period, we want to exclude:
-- 1) episodes in which the child entered at age 18 or more and
-- 2) *complete* episodes with LOS < 8 days. If the episode has a LOS < 8 days, but the child is still in care, we 
-- want to keep this. These short but ongoing episodes represent entries that occurred near the end of the 
-- 12-month period and continued past it (i.e., child was still in care).

UPDATE @mytable
	SET exlos8 = IIF(exited = 1 AND loslatremdays < 8, 1, 0)
	,exagen18 = IIF(agexmosyrscat = 6, 1, 0)-- look into calculation for agexmosyrscat

DELETE @mytable
	WHERE exlos8 = 1

-- ***************************
-- ADJUST NUMBER OF PLACEMENTS
-- ***************************

-- We don't want to count the first placement (which reflects the child's entry into care).

-- *************************************************************
-- SUM EACH CHILD's LOS and NUMBER OF PLACEMENTS ACROSS EPISODES
-- *************************************************************

UPDATE @mytable
	SET numplepadjust = CASE
			WHEN cursetdt > dodfcdtadjusted and numplep >= 2 THEN numplep - 2 -- childid 260 is off here not clear why
			WHEN (cursetdt <= dodfcdtadjusted and numplep >= 1)
				 OR (cursetdt IS NULL and numplep >= 1)
				 OR (exited = 0 and numplep >= 1) THEN numplep - 1
			ELSE numplep
			END 
	--,den_child = SUM(loslatremdays) OVER (PARTITION BY childid)

UPDATE A
	SET  A.den_child = B.den_child
	FROM @mytable AS A
		JOIN (SELECT
					childid
					,dtreportbeg 
					,SUM(loslatremdays) OVER (PARTITION BY childid) AS den_child
				FROM @mytable) AS B
				ON A.childid = B.childid
				AND A.dtreportbeg = B.dtreportbeg 

UPDATE A
	SET  A.num_child = B.num_child
	FROM @mytable AS A
		JOIN (SELECT
					childid
					,dtreportbeg 
					,SUM(numplepadjust) OVER (PARTITION BY childid) AS num_child
				FROM @mytable) AS B
				ON A.childid = B.childid
				AND A.dtreportbeg = B.dtreportbeg 

-- Age at entry

UPDATE @mytable
	SET age_at_entry = [dbo].[fnc_datediff_yrs](dob, latremdt)

-- Using the CSFR age categories
-- 1 = 0:5, 2 = 6:11, 3 = 12:17 

UPDATE @mytable
	SET csfr_age_cat = CASE
		WHEN age_at_entry < 6 THEN 1
		WHEN age_at_entry < 12 AND age_at_entry > 5 THEN 2
		WHEN age_at_entry > 11 AND age_at_entry < 18 THEN 3
		END

--  Some children may have a total LOS > 364 days. 
-- ***************************************************
-- 
--  These are due to data quality issues associated with some children who were reported two or more times 
--  during the 12-month period, with different dates of latest removal, and with no date of discharge in the first 
--  reported episode. 
-- 
--  Note: LOS of 364 represents children who entered on the first day of the period and did not discharge by the 
--  end of the period. We choose 364 and not 365 because on the first day of the period they were not in care for 
--  a full 24 hours. 

UPDATE @mytable
	SET den_child = CASE
		WHEN den_child > 364 THEN 364
		ELSE den_child
		END

DELETE @mytable
	WHERE den_child = 0

-- eliminating records there are more moves than days

DELETE @mytable
	WHERE numplepadjust > den_child

UPDATE A
	SET  A.tremcat_first = B.tremcat_first
		,A.agenmosyrscat_first = B.agenmosyrscat_first
		,A.agenmosyrs_first = B.agenmosyrs_first
		,A.flag_lastrpt4ch = B.flag_lastrpt4ch
	FROM @mytable AS A
		JOIN (SELECT
					childid
					,latremdt
					,FIRST_VALUE(tremcat) OVER (PARTITION BY childid ORDER BY dtreportend) AS tremcat_first
					,FIRST_VALUE(agenmosyrscat) OVER (PARTITION BY childid ORDER BY dtreportend) AS agenmosyrscat_first
					,FIRST_VALUE(agenmosyrs) OVER (PARTITION BY childid ORDER BY dtreportend) AS agenmosyrs_first
					,RANK() OVER (PARTITION BY childid ORDER BY dtreportend DESC) AS flag_lastrpt4ch
				FROM @mytable) AS B
				ON A.childid = B.childid 
				AND A.latremdt = B.latremdt

DELETE @mytable
	WHERE flag_lastrpt4ch = 2

INSERT INTO annual_report.cfsr_permanency_placement_mobility
    (
     dat_year
     ,region
     ,sex
     ,race
     ,age_cat
	 ,years_in_care
	 ,placement_stability
    )

SELECT
	@year AS dat_year
	,r.region_6_cd AS region
	,g.pk_gndr AS sex
	,e.cd_race AS race
	,ag.cd_age_cat AS age_cat
	,1 AS 'years_in_care'
	,(SUM(num_child)* 1.0 / SUM(den_child)) * 1000 AS placement_stability
FROM @mytable AS a
	LEFT JOIN dbo.prm_gndr AS g 
		ON g.match_code = a.sex
	LEFT JOIN [dbo].[prm_region_6] AS r
		ON r.match = a.region_6_cd
	LEFT JOIN (SELECT DISTINCT
						cd_race
						,match_code	
					FROM [dbo].[prm_eth_census]
					WHERE cd_race NOT IN (9, 10, 11, 12)) AS e
			ON e.match_code = a.raceeth
	LEFT JOIN [annual_report].[age_category] AS ag
		ON ag.match_code = a.csfr_age_cat
	AND g.pk_gndr != 3
GROUP BY g.pk_gndr
	,r.region_6_cd
	,e.cd_race
	,ag.cd_age_cat
					
SET @year = @year + 1

SET @dtperiodbeg = IIF(@period = 'AB', DATEFROMPARTS(@year - 1, 10, 01), DATEFROMPARTS(@year - 1, 04, 01))
SET @dtperiodend = IIF(@period = 'AB', DATEFROMPARTS(@year, 09, 30), DATEFROMPARTS(@year, 03, 31))

END

