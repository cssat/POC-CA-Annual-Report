


IF OBJECT_ID ('tempdb..#afcars') IS NOT NULL DROP TABLE #afcars

DECLARE @period VARCHAR(2) = 'AB'
	,@year INT = 2010
	,@dtperiodbeg DATE
	,@dtperiodend DATE
	,@dtmeasureend DATE
	,@dtmeasureend_minus6mo DATE

SET @dtperiodbeg = IIF(@period = 'AB', DATEFROMPARTS(@year - 1, 10, 01), DATEFROMPARTS(@year - 1, 04, 01))
SET @dtperiodend = IIF(@period = 'AB', DATEFROMPARTS(@year, 09, 30), DATEFROMPARTS(@year, 03, 31))

CREATE TABLE #afcars
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
		,disreasn1 SMALLINT
		,disreasn2 SMALLINT
		,totalrem SMALLINT
		,dtreportbeg DATE
		,dtreportend DATE
		,dtperiodbeg DATE
		,dtperiodend DATE
		,flag_lastrpt4ep TINYINT
		,reportedduringperiod TINYINT
		,inatstart BIT
		,entered BIT
		,agenmos SMALLINT
		,agenmosyrscat SMALLINT
		,agenyears SMALLINT
		,ageNmosyrs SMALLINT
		,dq_dobgtdodfcdt TINYINT
		,dq_dobgtlatremdt TINYINT
		,dq_dodfcdteqletremdt TINYINT
		,dq_dodfcdtltletremdt TINYINT
		,dq_gt21dobtodtdisch TINYINT
		,dq_gt21dobtodtlatrem TINYINT
		,dq_gt21dtdischtodtlatrem TINYINT
		,dq_missdob TINYINT
		,dq_missdtlatremdt TINYINT
		,dq_dropped TINYINT
		,dq_indicator TINYINT
		,bday18 DATE
		,dodfcdtadjust DATE
		,agefdmos SMALLINT
		,agefdmosyrscat SMALLINT
		,agefdyrs SMALLINT
		,agefdmosyrs SMALLINT
		,agemos SMALLINT
		,agemosyrscat SMALLINT
		,ageyrs SMALLINT
		,agemosyrs SMALLINT
		,exited BIT
		,losdays SMALLINT
		,exlos8 SMALLINT
		,exagen18 SMALLINT
		,den_child SMALLINT
		,numepisodes SMALLINT
		,latremdtplus7 DATE
		,dodfcdtadjusted2 DATE
		,UNIQUE(childid,
			dtreportbeg) 
		)

-------------------
-- START OF LOOP --
-------------------
 
WHILE @year <= 2015
BEGIN 
DELETE #afcars

INSERT INTO #afcars

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
	,agenmos
	,agenmosyrscat
	,agenyears
	,ageNmosyrs
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
	,dlstfcdt 
	,cursetdt 
	,curplset
	,disreasn1
	,disreasn2
	,totalrem
	,agenmos
	,agenmosyrscat
	,agenyears
	,ageNmosyrs
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

UPDATE #afcars
	SET dtperiodbeg = @dtperiodbeg
		,dtperiodend = @dtperiodend

-- Deleting records that aren't from the period observed 

DELETE #afcars
	WHERE dtreportbeg < dtperiodbeg OR dtreportend > dtperiodend

-- identifying the final report for each child

UPDATE A
	SET flag_lastrpt4ep = B.flag_lastrpt4ep
	FROM #afcars AS A
		JOIN (SELECT
					childid
					,dtreportbeg 
					,RANK() OVER (PARTITION BY childid, latremdt ORDER BY dtreportbeg DESC) AS flag_lastrpt4ep
				FROM #afcars) AS B
				ON A.childid = B.childid
				AND A.dtreportbeg = B.dtreportbeg

DELETE #afcars
	WHERE flag_lastrpt4ep != 1

-- Select only children who were served during the 12-month period specified earlier.

UPDATE #afcars
	SET inatstart = IIF((latremdt < dtperiodbeg) AND (dodfcdt >= dtperiodbeg OR dodfcdt IS NULL), 1, 0)
	,entered = IIF(latremdt >= dtperiodbeg AND latremdt <= dtperiodend, 1, 0)

-- deletee children who weren't served

DELETE #afcars
	WHERE inatstart = 0 AND entered = 0

-- determing if any records have been disqualified

UPDATE #afcars
	SET dq_dropped = CASE WHEN dtreportend = dtperiodend THEN 0 ELSE dq_dropped END 

UPDATE #afcars
	SET dq_indicator = IIF(dq_dobgtdodfcdt = 1 
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

DELETE #afcars
	WHERE dq_indicator = 1

-- Youth who turn 18 during the 12-month period will not have time in care beyond their 18th birthday or 
-- victimizations after their 18th birthday counted. To handle this, for children who turn 18 during the period we 
-- replace their discharge date with the date they turned 18. Therefore, the LOS for children who turn 18 during 
-- the period will be calculated from date of latest removal to date of 18th birthday.

UPDATE #afcars
	SET bday18 = DATEADD(YEAR, 18, dob)

-- If 18th birthday occurred during the 12-month period, and child had not discharged by the time he turned 18, 
-- replace date of discharge with date of 18th birthday.

UPDATE #afcars 
	SET dodfcdtadjust = IIF(bday18 > dtperiodbeg AND bday18 <= dtperiodend AND (dodfcdt IS NULL OR dodfcdt > bday18), bday18, NULL)

-- All discharge dates are moved over to dodfcdtadjust

UPDATE #afcars 
	SET dodfcdtadjust = IIF(dodfcdtadjust IS NULL, dodfcdt, dodfcdtadjust)

-- Calculating the age on first day in months

UPDATE #afcars 
	SET agefdmos = [dbo].[fnc_datediff_mos](dob, @dtperiodbeg)

UPDATE #afcars
	SET agefdmosyrscat = CASE
		WHEN agefdmos BETWEEN 216 AND 263 THEN 6
		WHEN agefdmos BETWEEN 204 AND 216 THEN 5
		WHEN agefdmos BETWEEN 132 AND 204 THEN 4
		WHEN agefdmos BETWEEN 72 AND 132 THEN 3
		WHEN agefdmos BETWEEN 12 AND 72 THEN 2
		WHEN agefdmos BETWEEN 4 AND 12 THEN 1
		WHEN agefdmos BETWEEN 0 AND 4 THEN 0
		END

UPDATE #afcars 
	SET agefdyrs = [dbo].[fnc_datediff_yrs](dob, @dtperiodbeg)

UPDATE #afcars
	SET agefdmosyrs = IIF(agefdyrs BETWEEN 1 AND 22, agefdyrs + 1, agefdyrs)

UPDATE #afcars
	SET agefdmosyrs = CASE
		WHEN agefdmosyrscat = 0 THEN 0
		WHEN agefdmosyrscat = 1 THEN 1
		ELSE agefdmosyrs
		END

-- If date of birth is after the date of first day (i.e., age on FS is negative), recode to 8888.
-- Note: Negative age on first day is to be expected for children who entered during the 12-month period at age 
-- < 1. For these children, their age at entry will be selected so it's okay to assign their age on first day to 8888

UPDATE #afcars
	SET agefdmos = 8888
	,agefdyrs = 8888
	,agefdmosyrscat = 8888
	,agefdmosyrs = 8888
	WHERE dob > @dtperiodbeg 
		OR [dbo].[fnc_datediff_yrs](dob, @dtperiodbeg) > 21

UPDATE #afcars
	SET agemos = agenmos
	,agemosyrscat = agenmosyrscat
	,ageyrs = agenyears
	,agemosyrs = ageNmosyrs
	WHERE entered = 1

UPDATE #afcars
	SET agemos = agefdmos
	,agemosyrscat = agefdmosyrscat
	,ageyrs = agefdyrs
	,agemosyrs = agefdmosyrs
	WHERE inatstart = 1

------------------------------
-- CALCULATE LENGTH OF STAY --
------------------------------

-- LOS calculations differ based on when the children was in care (i.e., on the first day of or entered during the 
-- 12-month period) and when the child exited (i.e., during the 12-month period or after, if at all). 

UPDATE #afcars
	SET exited = IIF(dodfcdt >= @dtperiodbeg AND dodfcdt <= @dtperiodend, 1, 0)

UPDATE #afcars
	SET losdays = CASE
		WHEN entered = 1 AND exited = 1 THEN [dbo].[fnc_datediff_days](latremdt, dodfcdtadjust)
		WHEN inatstart = 1 AND exited = 1 THEN [dbo].[fnc_datediff_days](@dtperiodbeg, dodfcdtadjust)
		WHEN entered = 1 AND exited = 0 THEN [dbo].[fnc_datediff_days](latremdt, @dtperiodend)
		WHEN inatstart = 1 AND exited = 0 THEN [dbo].[fnc_datediff_days](@dtperiodbeg, @dtperiodend) + 1
		END

--------------------------------------------------
-- REMOVE EPISODES THAT MEET EXCLUSION CRITERIA --
--------------------------------------------------

-- The denominator for this indicator is the sum of children's LOS (days) across *all* episodes during the 
-- 12-month period. So if a child entered twice during the 12-month periods, his total LOS is the LOS from his
-- first episode plus the LOS from his second episode. However, when summing a child's LOS over all his 
-- episodes in the 12-month period, we want to exclude:
-- 1) episodes in which the child entered at age 18 or more and
-- 2) *complete* episodes with LOS < 8 days. If the episode has a LOS < 8 days, but the child is still in care, 
-- we want to keep this. These short but ongoing episodes represent entries that occurred near the end of the 
-- 12-month period and continued past it (i.e., child was still in care).

UPDATE #afcars
	SET exlos8 = CASE
	WHEN entered = 1 AND exited = 1 AND losdays < 8 THEN 1
	WHEN inatstart = 1 AND exited = 1 AND [dbo].[fnc_datediff_days](latremdt, dodfcdtadjust) < 8 THEN 1
	ELSE 0
	END
	, exagen18 = CASE
	WHEN agemosyrscat = 6 THEN 1
	WHEN agemosyrscat = 8888 THEN 8888
	ELSE 0
	END

DELETE #afcars
	WHERE exlos8 = 1 
		OR exagen18 IN (1 , 8888)

-- total days in care

UPDATE a
	SET den_child = b.den_child
	FROM #afcars AS a
		JOIN (SELECT
				childid
				,SUM(losdays) OVER (PARTITION BY childid) AS den_child
			  FROM #afcars) AS b
		ON a.childid = b.childid

-- Some children may have a total LOS > 365 days. 

-- These are due to data quality issues associated with some children who were reported two or more times 
-- during the 12-month period, with different dates of latest removal, and with no date of discharge in the first 
-- reported episode. 

UPDATE #afcars	
	SET den_child = IIF(den_child > 365, 365, den_child)

-- removing children who did not spend 24 hours in care

DELETE #afcars
	WHERE den_child = 0

-- Count the number of episodes. Maximum number should be 2 (one for each 6-month reporting period). 

UPDATE #afcars
	SET numepisodes = 1

UPDATE a
	SET numepisodes = b.numepisodes
	FROM #afcars AS a
		JOIN (SELECT
				childid
				,IIF(childid = LEAD(childid, 1, NULL) OVER (PARTITION BY childid ORDER BY latremdt), numepisodes + 1,  numepisodes) AS numepisodes
			  FROM #afcars) AS b
		ON a.childid = b.childid

-- This indicator excludes any maltreatment report that occurs within 7 days of removal from home (latremdt). 
-- Therefore, compute latremdtPlus7 to be the removal date plus seven days. This will be used for later to
-- exclude maltreatment reports in NCANDS that occured before latremdtPlus7. 

UPDATE #afcars
	SET latremdtplus7 = DATEADD(DAY, 7, latremdt)

-- Later we need to find only maltreatment reports that occurred after the date of latest removal and before
-- the date of discharge. If the the child is still in care at the end of the 12-month period, his dodfcdt is missing, 
-- in which case we use DtPeriodEnd as the effective date of discharge. 

UPDATE #afcars
	SET dodfcdtadjusted2 = IIF(dodfcdtadjust IS NULL, dtperiodend, dodfcdtadjust)

-- Preparing NCANDS data

IF OBJECT_ID ('tempdb..#ncands') IS NOT NULL DROP TABLE #ncands

CREATE TABLE #ncands
	(
	subyr INT
	,staterr VARCHAR (2)
	,rptid INT
	,chid INT
	,rptcnty INT
	,rptdt DATE
	,invdate DATE
	,rptsrc INT
	,rptdisp INT
	,rptdisdt DATE
	,notifs TINYINT
	,chage TINYINT
	,chbdate DATE
	,chsex TINYINT
	,chcnty SMALLINT
	,chprior TINYINT
	,chmal1 TINYINT
	,mal1lev TINYINT
	,chmal2 TINYINT
	,mal2lev TINYINT
	,chmal3 TINYINT
	,mal3lev TINYINT
	,chmal4 TINYINT
	,mal4lev TINYINT
	,maldeath TINYINT
	,afcarsid INT
	,inciddt DATE
	,flvictim TINYINT
	,hasage TINYINT
	,hasafcars TINYINT
	,new TINYINT
	,daysdiff INT
	,chidlag TINYINT
	)

INSERT INTO #ncands
	(
	subyr
	,staterr
	,rptid
	,chid
	,rptcnty
	,rptdt
	,invdate
	,rptsrc
	,rptdisp
	,rptdisdt
	,notifs
	,chage
	,chbdate
	,chsex
	,chcnty
	,chprior
	,chmal1
	,mal1lev
	,chmal2
	,mal2lev
	,chmal3
	,mal3lev
	,chmal4
	,mal4lev
	,maldeath
	,afcarsid
	,inciddt
	)

SELECT 
	subyr
	,staterr
	,rptid
	,chid
	,rptcnty
	,rptdt
	,invdate
	,rptsrc
	,rptdisp
	,rptdisdt
	,notifs
	,chage
	,chbdate
	,chsex
	,chcnty
	,chprior
	,chmal1
	,mal1lev
	,chmal2
	,mal2lev
	,chmal3
	,mal3lev
	,chmal4
	,mal4lev
	,maldeath
	,afcarsid
	,inciddt
FROM [annual_report].[ca_ncands_extracts]
WHERE subyr = @year
ORDER BY 
	staterr
	,chid
	,rptdt

-- Flag victims, where a victim is a child who died due to maltreatment (maldeath = 1) or has a disposition of 
-- substantiated (malNlevel = 1) or indicated (malNlevel = 2), for any of four possible maltreatments.

UPDATE #ncands
	SET flvictim = CASE
		WHEN mal1lev <= 2 THEN 1
		WHEN mal2lev <= 2 THEN 1
		WHEN mal3lev <= 2 THEN 1
		WHEN mal4lev <= 2 THEN 1
		WHEN maldeath = 1 THEN 1
		END

-- Delete records that are not a victim

DELETE #ncands
	WHERE flvictim IS NULL

-- check to see if age is recorded
-- check to see if afcars id exists
-- remove children age 18 and older.

UPDATE #ncands
	SET hasage = IIF(chage >= 0 AND chage < 99, 1, 0)
	,hasafcars = IIF(afcarsid IS NOT NULL, 1, 0)

-- Calculating daysdiff

UPDATE a
	SET daysdiff = b.daysdiff
		,chidlag = b.chidlag
	FROM #ncands AS a
		LEFT JOIN (SELECT
					chid
					,rptid
					,rptdt
					,DATEDIFF(SECOND, LAG(rptdt) OVER (ORDER BY staterr, chid, rptdt), rptdt) / 86400 AS daysdiff
					,IIF(chid != LAG(chid) OVER (ORDER BY staterr, chid, rptdt), 1, 0) AS chidlag
				   FROM #ncands) AS b
		ON a.chid = b.chid
		AND a.rptdt = b.rptdt
		AND a.rptid = b.rptid

DELETE #ncands
	WHERE daysdiff <= 1 AND chidlag = 0

-- Delete records that don't occur during the period of observation

DELETE #ncands
	WHERE rptdt < @dtperiodbeg

-- Delete records with no afcars id and older than 18

DELETE #ncands
	WHERE hasafcars = 0
	OR hasage = 0

-- Bringing NCANDS and AFCARS together!

IF OBJECT_ID ('tempdb..#afcars_ncands') IS NOT NULL DROP TABLE #afcars_ncands

SELECT
	n.subyr
	,n.staterr
	,n.rptid
	,n.chid
	,n.rptcnty 
	,n.rptdt
	,n.invdate 
	,n.rptsrc
	,n.rptdisp 
	,n.rptdisdt
	,n.notifs
	,n.chage
	,n.chbdate 
	,n.chsex
	,n.chcnty
	,n.chprior 
	,n.chmal1
	,n.mal1lev 
	,n.chmal2
	,n.mal2lev 
	,n.chmal3
	,n.mal3lev 
	,n.chmal4
	,n.mal4lev 
	,n.maldeath
	,n.afcarsid
	,n.inciddt 
	,n.flvictim
	,n.hasage
	,n.hasafcars
	,a.latremdtplus7
	,a.dodfcdtadjusted2
	,NULL AS victiminCare
	,NULL AS victimization
	,NULL AS adjusted
	,NULL AS adjustvictim
	,NULL AS count_reports
	,NULL AS keep_record
INTO #afcars_ncands
FROM #ncands AS n
LEFT JOIN #afcars AS a
	ON n.afcarsid = a.recnumbr
ORDER BY 
	n.staterr
	,n.chid
	,n.rptdt
	
-- Identify children victimized while in care for any of his episodes (up to two) in the 12-month period. 
-- At this point, the count of victimInCare will be duplicate since a child has a record for every maltreatment report 
-- during the 12-month period. When we aggregate the file later and select max(victimInCare), we will have a 
-- unique count of children who were a victim in care at any point during the 12-month period. 

UPDATE #afcars_ncands
	SET victiminCare = IIF(rptdt >= latremdtplus7 AND rptdt < dodfcdtadjusted2, 1, 0)

-- Count victimizations. For example, if a child has three reports in NCANDS (and is a victim in each report), and 
-- all three reports were reported (or the incident occurred) during the child's first episode (DtLatRemPlus7.1 
-- and DtDischAdjusted2.1), victimization1 will = 1 for all three records/reports. When we aggregate the file later
-- and sum the victimizations (e.g., sum(victimization1), the result will show 3 victimizations for that one episode.

UPDATE #afcars_ncands
	SET victimization = IIF(rptdt >= latremdtplus7 AND rptdt < dodfcdtadjusted2, 1, 0)

-- Incident date adjustment. Recode victimInCare to 0 and victimization.N to 0 if the incident date is present and 
-- shows the child was not victimized while in care (i.e., the actual date of maltreatment was before date of latest 
-- removal plus 7, or after (or the same day of) the date of discharge. 

UPDATE #afcars_ncands
	SET adjusted = 1
		,adjustvictim = 1
		,victimization = 0
		,victiminCare = 0
	WHERE victimization = 1 AND inciddt IS NOT NULL AND (inciddt < latremdtplus7 OR inciddt >= dodfcdtadjusted2)

-- SPSS switches between long and wide format data, which is stupid.
-- Instead of doing that, we are meeting back up with the SPSS data
-- by counting the number of reports for a child in care.

UPDATE a
	SET count_reports = ISNULL(b.count_reports, 0)
	FROM #afcars_ncands AS a
	LEFT JOIN (SELECT
					chid
					,victiminCare
					,COUNT(chid) OVER (PARTITION BY chid) AS count_reports
				FROM #afcars_ncands 
				WHERE victiminCare = 1) AS b
	ON a.chid = b.chid
	AND a.victiminCare = b.victiminCare

-- There are some incidents where a child has multiple records in the afcars
-- file, this is because they had two different removals in a 12 month period.
-- This can create a problem because if they experienced maltreatment in care, 
-- we might end up with two records, one that says they didn't experience 
-- maltreatment and another that says they did. So we will use keep_record in
-- the final query to eliminate duplicate records.


INSERT INTO annual_report.cfsr_safety

    (
     dat_year
	 ,maltreatment_in_care
    )

SELECT
	@year AS dat_year
	,SUM(count_reports) * 1.0 / SUM(den_child) * 100000 AS maltreatment_in_care_rate
FROM
	(SELECT 
		recnumbr
		,den_child
		,count_reports
		,IIF(COUNT(recnumbr) OVER (PARTITION BY recnumbr) > 1 AND count_reports = 0, 0, 1) AS keep_record
	FROM (SELECT DISTINCT 
			recnumbr 
			,den_child 
		  FROM #afcars) AS id1
	LEFT JOIN (SELECT DISTINCT
					afcarsid
					,victiminCare
					,count_reports
				FROM #afcars_ncands) AS id2
	ON id1.recnumbr = id2.afcarsid) AS id3
WHERE keep_record = 1


SET @year = @year + 1

SET @dtperiodbeg = IIF(@period = 'AB', DATEFROMPARTS(@year - 1, 10, 01), DATEFROMPARTS(@year - 1, 04, 01))
SET @dtperiodend = IIF(@period = 'AB', DATEFROMPARTS(@year, 09, 30), DATEFROMPARTS(@year, 03, 31))

END

