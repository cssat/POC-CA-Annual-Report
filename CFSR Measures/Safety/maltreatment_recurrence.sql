  
-- Project: Annual report
--
-- Purpose: Calculate CFSR measure for maltreatment recurrence
--
-- Notes: Refer to S:\Data Portal\data\afcars_foster_care_2000_2013\cfsr\second_try_syntax\CFSR3\Syntax\
--        CFSR 3 - 3 Observed perf for maltx recurrence 11-2-15 KSe.sps for SPSS code. Cited line numbers refer
--        to this file.
--
-- Programmers: Karen Segar
--
-- Dates: 11/17/2015 created

-- Replace maltreatment_recurrence table if it already exists
--IF OBJECT_ID ('[annual_report].[cfsr_maltreatment_recurrence]') IS NOT NULL TRUNCATE TABLE [annual_report].[cfsr_maltreatment_recurrence]

-- table variable
DECLARE @period VARCHAR(2) = 'AB'
	,@year INT = 2010
	,@dtperiodbeg DATE
	,@dtperiodend DATE


SET @dtperiodbeg = IIF(@period = 'AB', DATEFROMPARTS(@year - 1, 10, 01), DATEFROMPARTS(@year - 1, 04, 01))
SET @dtperiodend = IIF(@period = 'AB', DATEFROMPARTS(@year, 09, 30), DATEFROMPARTS(@year, 03, 31))

-------------------
-- START OF LOOP --
-------------------
 
WHILE @year <= 2015
BEGIN 

IF OBJECT_ID ('tempdb..#ncands') IS NOT NULL DROP TABLE #ncands
-- Line 80
CREATE TABLE #ncands
	(
	obyear INT
	,TwelveMoCohort VARCHAR (4)
	,subyr INT
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
	,chage INT
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
	,daysdiffnew NUMERIC
	,daysdifffix TINYINT
	,rec1 TINYINT
	,chlag1 TINYINT
	,difnew TINYINT
	,keepme TINYINT
	,new TINYINT
	,orig TINYINT
	,numyears TINYINT
	,chbdate1 DATE
	,chsex1 TINYINT
	,chage1 TINYINT
	,chbdate2 DATE
	,chsex2 TINYINT
	,chage2 TINYINT
	,timebetweenrpts INT
	,posit TINYINT
	,keep TINYINT
	)
	
INSERT INTO #ncands
	(
	obyear
	,TwelveMoCohort
	,subyr
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
	,new
	)

SELECT 
	@year AS obyear
	,@period AS TwelveMoCohort
	,subyr
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
	,1 AS new
FROM [annual_report].[ca_ncands_extracts]
ORDER BY 
	staterr
	,chid
	,rptdt

-- Line 81
DELETE #ncands
	WHERE subyr < obyear OR subyr > obyear + 1

-- Ignore lines 99-107. We only have data for one state.

-- Line 111
UPDATE #ncands
	SET TwelveMoCohort = 'FY' + SUBSTRING(CONVERT(varchar(4),obyear),3,2)

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
-- Line 124
DELETE #ncands
	WHERE flvictim IS NULL

-- Skip lines 143-192 (state DQ checks)

-- Lines 136, 202-216
UPDATE #ncands
	SET hasage = IIF(chage >= 0 AND chage < 99, 1, 0)
	,hasafcars = IIF(afcarsid IS NOT NULL, 1, 0)
	,chage = IIF(chage = 77,-1,chage)
	,chbdate1 = IIF(subyr = obyear,chbdate,NULL)
	,chsex1 = IIF(subyr = obyear,chsex,NULL)
	,chage1 = IIF(subyr = obyear,chage,NULL)
	,chbdate2 = IIF(subyr = obyear+1,chbdate,NULL)
	,chsex2 = IIF(subyr = obyear+1,chsex,NULL)
	,chage2 = IIF(subyr = obyear+1,chage,NULL)


-- Count the number of submission years associated with a Child ID.
-- Line 218
UPDATE a
	SET numyears = b.numyears
	FROM #ncands AS a
		LEFT JOIN (SELECT 
						chid
						,COUNT(DISTINCT subyr) AS numyears
					FROM #ncands
					GROUP BY chid) AS b
		ON a.chid = b.chid
-- Skipping past lines 226-384

--****************************************************
--* SELECT APPLICABLE RECORDS 
--****************************************************

--* Select only records with report dates on or after the beginning of the first fiscal year.

-- Line 391
DELETE #ncands
	WHERE rptdt < DATEFROMPARTS(obyear-1, 10, 1)

UPDATE #ncands
	SET chage = IIF(chage = 77,0,chage)

DELETE #ncands
	WHERE chage > 17

UPDATE a
	SET timebetweenrpts = b.timebetweenrpts
	FROM #ncands AS a
		JOIN (SELECT chid,
			rptdt,
			rptid,
			(DATEDIFF(SECOND, LAG(rptdt,1,NULL) OVER (PARTITION BY chid ORDER BY staterr, chid, rptdt), rptdt)/86400) AS timebetweenrpts
			FROM #ncands) AS b
			ON a.chid = b.chid AND
			a.rptid = b.rptid
UPDATE #ncands
	SET timebetweenrpts = ISNULL(timebetweenrpts,999)

-- Apply 14 day roll up
DELETE #ncands
	WHERE (timebetweenrpts <= 14)

--* Count the relative report position for a victim.
UPDATE a
	SET posit = b.posit
	FROM #ncands AS a
		JOIN (SELECT chid, rptdt, rptid,
			ROW_NUMBER() OVER (PARTITION BY chid ORDER BY rptdt) AS posit
			FROM #ncands) AS b
			ON a.chid = b.chid
			AND a.rptid = b.rptid

--* Exclude fatalities if they happened in the first report.
DELETE #ncands
	WHERE posit = 1 AND maldeath = 1

--* Select only the first two reports for a victim. Recurrence is only computed using the first two reports, so 
--* subsequent reports are of no interest. 
DELETE #ncands
	WHERE posit > 2

-- Make table with one record per child
IF OBJECT_ID ('tempdb..#maltx') IS NOT NULL DROP TABLE #maltx

CREATE TABLE #maltx
	(staterr VARCHAR (2)
	,chid INT
	,obyear INT
	,TwelveMoCohort VARCHAR (4)
	,FFY INT
	,county INT
	,dob DATE
	,ageinyears INT
	,initialrpt DATE
	,lastrpt DATE
	,initialincdt DATE
	,lastincdt DATE
	,ageinmonths DECIMAL(4,1)
	,daysbetweenrpts DECIMAL(6,1)
	,recur TINYINT
	,AgeMosyrsCat TINYINT
	,AgeMosyrs INT)

INSERT INTO #maltx
	(staterr
	,chid
	,obyear
	,TwelveMoCohort
	,FFY
	,county
	,dob
	,ageinyears
	,initialrpt
	,initialincdt)

SELECT staterr
	,chid
	,obyear
	,TwelveMoCohort
	,subyr AS FFY
	,rptcnty AS county
	,chbdate AS dob
	,chage AS ageinyears
	,rptdt AS initialrpt
	,inciddt AS initialincdt
	FROM #ncands
	WHERE posit = 1

-- Match second report
UPDATE a
	SET lastrpt = b.rptdt,
		lastincdt = b.inciddt
	FROM #maltx AS a
	JOIN (SELECT chid
				,rptdt
				,inciddt
			FROM #ncands
			WHERE posit = 2) AS b
			ON a.chid = b.chid
-- Most children don't have a second report
UPDATE #maltx
	SET lastrpt = ISNULL(lastrpt,initialrpt),
		lastincdt = ISNULL(lastincdt,initialincdt)

-- Some children have a negative ageinmonths due to dob > initialrpt. These are plausible and involve allegations 
-- concerning children in utero. Recode to 0 for 0-3 months age group, which includes unborn. 
UPDATE #maltx
	SET ageinmonths =[dbo].[fnc_datediff_mos](dob,initialrpt),
		ageinyears = IIF(ageinyears < 0,0,ageinyears),
		daysbetweenrpts = [dbo].[fnc_datediff_days](initialrpt,lastrpt) -- Compute the time between the first and the last report.

-- Line 477
UPDATE #maltx
	SET ageinmonths = IIF(ageinmonths < 0,0,ageinmonths),
		recur = IIF(daysbetweenrpts > 0 AND daysbetweenrpts <= 365,1,0) -- If the time betweeen reports is greater than 0 and less than or equal to 365 days, recurrence occurs.

UPDATE #maltx
	SET recur = IIF(initialincdt = lastincdt,0,recur) -- If the initial incident date is the same as the last incident date, set recur to 0.

--  Select only records where the first report date occurred in the first fiscal year (this uses two submission periods).
-- Line 494
DELETE #maltx
	WHERE initialrpt > DATEFROMPARTS(obyear,9,30)

UPDATE #maltx
	SET AgeMosyrsCat = CASE
		WHEN ageinmonths BETWEEN 216 AND 263 THEN 6
		WHEN ageinmonths BETWEEN 204 AND 216 THEN 5
		WHEN ageinmonths BETWEEN 132 AND 204 THEN 4
		WHEN ageinmonths BETWEEN 72 AND 132 THEN 3
		WHEN ageinmonths BETWEEN 12 AND 72 THEN 2
		WHEN ageinmonths BETWEEN 4 AND 12 THEN 1
		WHEN ageinmonths BETWEEN 0 AND 4 THEN 0
		END,
	AgeMosyrs = IIF(ageinyears > 0,ageinyears + 1,NULL)
-- Children < 1 currently have a value of 0 for AgeYrs. Need to split these into 0-3 mos (0) mos and 4-11 mos (1). 
-- To make room for the 0 and 1 for < 1 children, make a copy of AgeYrs then shift all subsequent ages, so 
UPDATE #maltx
	SET AgeMosyrs = IIF(AgeMosyrsCat <= 1,AgeMosyrsCat,AgeMosyrs)

UPDATE a
	SET recurrence_of_maltreatment = b.recurrence_of_maltreatment
FROM annual_report.cfsr_safety AS a
LEFT JOIN (SELECT 
			@year AS dat_year
			,SUM(recur) * 1.0 / COUNT(*) * 100 AS 'recurrence_of_maltreatment'
		   FROM #maltx) AS b
ON a.dat_year = b.dat_year
WHERE a.dat_year = @year

SET @year = @year + 1

SET @dtperiodbeg = IIF(@period = 'AB', DATEFROMPARTS(@year - 1, 10, 01), DATEFROMPARTS(@year - 1, 04, 01))
SET @dtperiodend = IIF(@period = 'AB', DATEFROMPARTS(@year, 09, 30), DATEFROMPARTS(@year, 03, 31))

END