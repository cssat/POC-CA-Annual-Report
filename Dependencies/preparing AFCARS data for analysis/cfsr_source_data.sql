--------------------------------------------------------------------------
------------------------- CREAT TABLE STATEMENT --------------------------
--------------------------------------------------------------------------
DROP TABLE annual_report.ca_afcars_source_data

CREATE TABLE annual_report.ca_afcars_source_data (
	recnumbr INT
	,fipscode INT
	,county_cd TINYINT
	,county_desc VARCHAR(14)
	,region_cd TINYINT
	,region_6_cd TINYINT
	,region_6_tx VARCHAR(18)
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
	,totalrem TINYINT
	,rem1dt DATE
	,dlstfcdt DATE
	,latremdt DATE
	,cursetdt DATE
	,dodfcdt DATE
	,tprmomdt DATE
	,tprdaddt DATE
	,numplep TINYINT
	,curplset TINYINT
	,childid INT
	,repdat INT
	,dtreportbeg DATE
	,dtreportend DATE
	,dtreportendfinal DATE
	,dtreportbeg1 DATE
	,next6moreport DATE
	,timebetweenreports INT
	,dq_dropped TINYINT
	,dq_idnomatchnext6mo TINYINT
	,dq_missdob TINYINT
	,dq_missdtlatremdt TINYINT
	,dq_missnumplep TINYINT
	,dq_dobgtlatremdt TINYINT
	,dq_dobgtdodfcdt TINYINT
	,dq_gt21dobtodtlatrem TINYINT
	,dq_gt21dobtodtdisch TINYINT
	,dq_gt21dtdischtodtlatrem TINYINT
	,dq_dodfcdteqletremdt TINYINT
	,dq_dodfcdtltletremdt TINYINT
	,dq_missdisreasn TINYINT
	,dq_totalrem1 TINYINT
	,entryyr INT
	,exityr INT
	,agenmos TINYINT
	,agenmosyrscat TINYINT
	,agenyears TINYINT
	,agenmosyrs INT
	,agexmos INT
	,agexmosyrscat INT
	,agexyrs INT
	,agexmosyrs INT
	,disreasn1 INT
	,disreasn2 INT
	,tremcat TINYINT
	)

CREATE UNIQUE NONCLUSTERED INDEX [idx_pk_ca_afcars_source_data] ON annual_report.ca_afcars_source_data (
	childid
	,repdat
	)
--------------------------------------------------------------------------
-------------------- NEED TO CREATE FINAL REPORT DATE --------------------
--------------------------------------------------------------------------

DECLARE @dtreportendfinal DATE

SELECT @dtreportendfinal = a.dtreportendfinal
FROM (
SELECT CASE 
		WHEN RIGHT(MAX(repdat), 1) = 3
			THEN DATEFROMPARTS(LEFT(MAX(repdat), 4), 3, 31)
		WHEN RIGHT(MAX(repdat), 1) = 9
			THEN DATEFROMPARTS(LEFT(MAX(repdat), 4), 9, 30)
		END AS dtreportendfinal
FROM [annual_report].[ca_fc_afcars_extracts]) AS a

--------------------------------------------------------------------------
-------------- THIS TABLE IS TO PREP DATA FOR CSFR MEASURES --------------
--------------------------------------------------------------------------
IF OBJECT_ID('TEMPDB..#prep_data') IS NOT NULL
	DROP TABLE #prep_data

SELECT recnumbr
	,dob
	,fipscode
	,pedrevdt
	,sex
	,sex_recode
	,amiakn
	,asian
	,blkafram
	,hawaiipi
	,white
	,untodetm
	,hisorgin
	,totalrem
	,rem1dt
	,dlstfcdt
	,latremdt
	,remtrndt
	,cursetdt
	,tprdaddt
	,tprmomdt
	,dodfcdt
	,numplep
	,curplset
	,childid
	,repdat
	,dtreportbeg
	,dtreportend
	,dtreportendfinal
	,dtreportbeg1
	,next6moreport
	,timebetweenreports
	,dq_dropped
	,dq_idnomatchnext6mo
	,dq_missdob
	,dq_missdtlatremdt
	,dq_missnumplep
	,dq_dobgtlatremdt
	,dq_dobgtdodfcdt
	,dq_gt21dobtodtlatrem
	,dq_gt21dobtodtdisch
	,dq_gt21dtdischtodtlatrem
	,dq_dodfcdteqletremdt
	,dq_dodfcdtltletremdt
	,dq_missdisreasn
	,dq_totalrem1
	,entryyr
	,exityr
	,agenmos
	,agenmosyrscat
	,agenyears
	,CASE 
		WHEN agenmosyrscat = 0
			THEN 0
		WHEN agenmosyrscat = 1
			THEN 1
		WHEN dq_dobgtlatremdt = 1
			OR dq_gt21dobtodtlatrem = 1
			THEN 8888
		WHEN dq_missdob = 1
			OR dq_missdtlatremdt = 1
			THEN 9999
		ELSE agenyears + 1
		END AS agenmosyrs
	,CASE 
		WHEN dodfcdt IS NULL
			THEN 7777
		WHEN dq_dobgtdodfcdt = 1
			OR dq_gt21dobtodtdisch = 1
			THEN 8888
		WHEN dq_missdob = 1
			THEN 9999
		ELSE [dbo].[fnc_datediff_mos](dob, dodfcdt)
		END AS agexmos
	,CASE 
		WHEN dodfcdt IS NULL
			THEN 7777
		WHEN dq_dobgtdodfcdt = 1
			OR dq_gt21dobtodtdisch = 1
			THEN 8888
		WHEN dq_missdob = 1
			THEN 9999
		WHEN [dbo].[fnc_datediff_mos](dob, dodfcdt) BETWEEN 216
				AND 263
			THEN 6
		WHEN [dbo].[fnc_datediff_mos](dob, dodfcdt) BETWEEN 204
				AND 216
			THEN 5
		WHEN [dbo].[fnc_datediff_mos](dob, dodfcdt) BETWEEN 132
				AND 204
			THEN 4
		WHEN [dbo].[fnc_datediff_mos](dob, dodfcdt) BETWEEN 72
				AND 132
			THEN 3
		WHEN [dbo].[fnc_datediff_mos](dob, dodfcdt) BETWEEN 12
				AND 72
			THEN 2
		WHEN [dbo].[fnc_datediff_mos](dob, dodfcdt) BETWEEN 4
				AND 12
			THEN 1
		WHEN [dbo].[fnc_datediff_mos](dob, dodfcdt) BETWEEN 0
				AND 4
			THEN 0
		END AS agexmosyrscat
	,CASE 
		WHEN dodfcdt IS NULL
			THEN 7777
		WHEN dq_dobgtdodfcdt = 1
			OR dq_gt21dobtodtdisch = 1
			THEN 8888
		WHEN dq_missdob = 1
			THEN 9999
		ELSE [dbo].[fnc_datediff_yrs](dob, dodfcdt)
		END AS agexyrs
	,CASE 
		WHEN dodfcdt IS NULL
			THEN 7777
		WHEN dq_dobgtdodfcdt = 1
			OR dq_gt21dobtodtdisch = 1
			THEN 8888
		WHEN dq_missdob = 1
			THEN 9999
		WHEN agenmosyrscat = 0
			THEN 0
		WHEN agenmosyrscat = 1
			THEN 1
		ELSE [dbo].[fnc_datediff_yrs](dob, dodfcdt) + 1
		END AS agexmosyrs
	,IIF(disreasn IS NULL
		OR disreasn = 0, 7777, disreasn) AS disreasn1
	,CASE 
		WHEN disreasn IS NULL
			OR disreasn = 0
			THEN 7777
		WHEN disreasn IN (
				1
				,2
				,3
				,5
				)
			THEN 1
		WHEN disreasn IN (
				4
				,6
				,7
				)
			THEN 2
		WHEN disreasn = 8
			THEN 3
		END AS disreasn2
	,IIF(totalrem > 4, 4, totalrem) AS tremcat
INTO #prep_data
FROM (
	SELECT recnumbr
		,dob
		,fipscode
		,pedrevdt
		,sex
		,sex_recode
		,amiakn
		,asian
		,blkafram
		,hawaiipi
		,white
		,untodetm
		,hisorgin
		,totalrem
		,rem1dt
		,dlstfcdt
		,latremdt
		,remtrndt
		,cursetdt
		,tprdaddt
		,tprmomdt
		,dodfcdt
		,numplep
		,curplset
		,childid
		,disreasn
		,repdat
		,dtreportbeg
		,dtreportend
		,dtreportendfinal
		,dtreportbeg1
		,next6moreport
		,timebetweenreports
		,dq_dropped
		,dq_idnomatchnext6mo
		,dq_missdob
		,dq_missdtlatremdt
		,dq_missnumplep
		,dq_dobgtlatremdt
		,dq_dobgtdodfcdt
		,dq_gt21dobtodtlatrem
		,dq_gt21dobtodtdisch
		,dq_gt21dtdischtodtlatrem
		,dq_dodfcdteqletremdt
		,dq_dodfcdtltletremdt
		,dq_missdisreasn
		,dq_totalrem1
		,CASE 
			WHEN dq_missdtlatremdt = 1
				THEN 9999
			WHEN MONTH(latremdt) BETWEEN 10
					AND 12
				THEN YEAR(latremdt) + 1
			ELSE YEAR(latremdt)
			END AS entryyr
		,CASE 
			WHEN dodfcdt IS NULL
				THEN 7777
			WHEN MONTH(dodfcdt) BETWEEN 10
					AND 12
				THEN YEAR(dodfcdt) + 1
			ELSE YEAR(dodfcdt)
			END AS exityr
		,[dbo].[fnc_datediff_mos](dob, latremdt) AS agenmos
		,CASE 
			WHEN [dbo].[fnc_datediff_mos](dob, latremdt) BETWEEN 216
					AND 263
				THEN 6
			WHEN [dbo].[fnc_datediff_mos](dob, latremdt) BETWEEN 204
					AND 216
				THEN 5
			WHEN [dbo].[fnc_datediff_mos](dob, latremdt) BETWEEN 132
					AND 204
				THEN 4
			WHEN [dbo].[fnc_datediff_mos](dob, latremdt) BETWEEN 72
					AND 132
				THEN 3
			WHEN [dbo].[fnc_datediff_mos](dob, latremdt) BETWEEN 12
					AND 72
				THEN 2
			WHEN [dbo].[fnc_datediff_mos](dob, latremdt) BETWEEN 4
					AND 12
				THEN 1
			WHEN [dbo].[fnc_datediff_mos](dob, latremdt) BETWEEN 0
					AND 4
				THEN 0
			END AS agenmosyrscat
		,[dbo].[fnc_datediff_yrs](dob, latremdt) AS agenyears
	FROM (
		SELECT recnumbr
			,dob
			,fipscode
			,pedrevdt
			,sex
			,sex_recode
			,amiakn
			,asian
			,blkafram
			,hawaiipi
			,white
			,untodetm
			,hisorgin
			,totalrem
			,rem1dt
			,dlstfcdt
			,latremdt
			,remtrndt
			,cursetdt
			,tprdaddt
			,tprmomdt
			,numplep
			,curplset
			,dodfcdt
			,childid
			,disreasn
			,repdat
			,dtreportbeg
			,dtreportend
			,dtreportendfinal
			,dtreportbeg1
			,next6moreport
			,timebetweenreports
			,CASE 
				WHEN dodfcdt IS NULL
					THEN CASE 
							WHEN timebetweenreports IS NULL
								OR (
									timebetweenreports >= 12
									AND timebetweenreports < 888
									)
								THEN 1
							END
				END AS dq_dropped
			,dq_idnomatchnext6mo = IIF(timebetweenreports IS NULL
				OR (
					timebetweenreports >= 12
					AND timebetweenreports < 888
					), 1, 0)
			,dq_missdob = IIF(dob IS NULL, 1, 0)
			,dq_missdtlatremdt = IIF(latremdt IS NULL, 1, 0)
			,dq_missnumplep = IIF(numplep IS NULL, 1, 0)
			,dq_dobgtlatremdt = IIF(dob > latremdt, 1, 0)
			,dq_dobgtdodfcdt = IIF(dob > dodfcdt, 1, 0)
			,dq_gt21dobtodtlatrem = IIF([dbo].[fnc_datediff_yrs](dob, latremdt) > 21, 1, 0)
			,dq_gt21dobtodtdisch = IIF([dbo].[fnc_datediff_yrs](dob, dodfcdt) > 21, 1, 0)
			,dq_gt21dtdischtodtlatrem = IIF([dbo].[fnc_datediff_days](latremdt, dodfcdt) > 7665, 1, 0)
			,dq_dodfcdteqletremdt = IIF(dodfcdt = latremdt, 1, 0)
			,dq_dodfcdtltletremdt = IIF(dodfcdt < latremdt, 1, 0)
			,dq_missdisreasn = IIF(dodfcdt IS NOT NULL
				AND disreasn IS NULL, 1, 0)
			,dq_totalrem1 = IIF(totalrem = 1, 1, 0)
		FROM (
			SELECT recnumbr
				,dob
				,fipscode
				,pedrevdt
				,sex
				,sex_recode
				,amiakn
				,asian
				,blkafram
				,hawaiipi
				,white
				,untodetm
				,hisorgin
				,totalrem
				,rem1dt
				,dlstfcdt
				,latremdt
				,remtrndt
				,cursetdt
				,tprdaddt
				,tprmomdt
				,numplep
				,curplset
				,dodfcdt
				,childid
				,disreasn
				,repdat
				,dtreportbeg
				,dtreportend
				,dtreportendfinal
				,dtreportbeg AS dtreportbeg1
				,LEAD(dtreportbeg, 1, NULL) OVER (
					PARTITION BY childid ORDER BY dtreportbeg
					) AS next6moreport
				,IIF(dtreportend = dtreportendfinal, 888, [dbo].[fnc_datediff_mos](dtreportbeg, LEAD(dtreportbeg, 1, NULL) OVER (
							PARTITION BY childid ORDER BY dtreportbeg
							))) AS timebetweenreports
			FROM (
				SELECT a.recnumbr
					,dob
					,fipscode
					,pedrevdt
					,sex
					,NULL AS sex_recode
					,amiakn
					,asian
					,blkafram
					,hawaiipi
					,white
					,untodetm
					,hisorgin
					,totalrem
					,rem1dt
					,dlstfcdt
					,latremdt
					,remtrndt
					,cursetdt
					,tprdaddt
					,tprmomdt
					,numplep
					,curplset
					,dodfcdt
					,disreasn
					,DENSE_RANK() OVER (
						ORDER BY a.recnumbr
						) AS childid
					,a.repdat
					,IIF(RIGHT(a.repdat, 1) = 3, DATEFROMPARTS(LEFT(a.repdat, 4) - 1, 10, 1), DATEFROMPARTS(LEFT(a.repdat, 4), 4, 1)) AS dtreportbeg
					,IIF(RIGHT(a.repdat, 1) = 3, DATEFROMPARTS(LEFT(a.repdat, 4), 3, 31), DATEFROMPARTS(LEFT(a.repdat, 4), 9, 30)) AS dtreportend
					,@dtreportendfinal AS dtreportendfinal
				FROM [annual_report].[ca_fc_afcars_extracts] AS a
				LEFT JOIN (
					SELECT recnumbr
						,repdat
						,COUNT(*) AS dup
					FROM [annual_report].[ca_fc_afcars_extracts]
					GROUP BY recnumbr
						,repdat
					) AS dups ON a.recnumbr = dups.recnumbr
					AND a.repdat = dups.repdat
				WHERE dup = 1
				) AS id
			) AS id
		) AS id
	) AS id
ORDER BY childid
	,dtreportbeg

--------------------------------------------------------------------------
----------------- ADDING COUNTY AND REGION TO THE TABLE ------------------
------------ AND TRANSFORMING RACE ETHNICITY TO SINGLE COLUMN ------------
--------------------------------------------------------------------------
IF OBJECT_ID('TEMPDB..#location') IS NOT NULL
	DROP TABLE #location

SELECT recnumbr
	,dob
	,fipscode
	,co.county_cd
	,co.county_desc
	,cr.region_cd
	,cr.region_6_cd
	,cr.region_6_tx
	,pedrevdt
	,sex
	,sex_recode
	,amiakn
	,asian
	,blkafram
	,hawaiipi
	,white
	,untodetm
	,hisorgin
	,CASE 
		WHEN hisorgin = 1
			THEN 5
		ELSE CASE 
				WHEN (amiakn + asian + blkafram + hawaiipi + white) > 1
					THEN 7
				ELSE CASE 
						WHEN amiakn = 1
							THEN 1
						WHEN asian = 1
							THEN 2
						WHEN blkafram = 1
							THEN 3
						WHEN hawaiipi = 1
							THEN 4
						WHEN white = 1
							THEN 6
						WHEN untodetm = 1
							THEN 7
						ELSE 8
						END
				END
		END AS [raceeth]
	,totalrem
	,rem1dt
	,dlstfcdt
	,latremdt
	,remtrndt
	,cursetdt
	,tprdaddt
	,tprmomdt
	,dodfcdt
	,numplep
	,curplset
	,childid
	,repdat
	,dtreportbeg
	,dtreportend
	,dtreportendfinal
	,dtreportbeg1
	,next6moreport
	,timebetweenreports
	,dq_dropped
	,dq_idnomatchnext6mo
	,dq_missdob
	,dq_missdtlatremdt
	,dq_missnumplep
	,dq_dobgtlatremdt
	,dq_dobgtdodfcdt
	,dq_gt21dobtodtlatrem
	,dq_gt21dobtodtdisch
	,dq_gt21dtdischtodtlatrem
	,dq_dodfcdteqletremdt
	,dq_dodfcdtltletremdt
	,dq_missdisreasn
	,dq_totalrem1
	,entryyr
	,exityr
	,agenmos
	,agenmosyrscat
	,agenyears
	,agenmosyrs
	,agexmos
	,agexmosyrscat
	,agexyrs
	,agexmosyrs
	,disreasn1
	,disreasn2
	,tremcat
INTO #location
FROM #prep_data AS pd
LEFT JOIN [dbo].[ref_lookup_county] AS co ON co.countyfips = pd.fipscode
LEFT JOIN [dbo].[ref_lookup_county_region] AS cr ON co.county_cd = cr.county_cd

-- POC codes for sex are the opposite of the codes used by CB 
UPDATE #location
SET sex_recode = CASE 
		WHEN sex = 1
			THEN 2
		WHEN sex = 2
			THEN 1
		END

UPDATE #location
SET sex = sex_recode

INSERT INTO annual_report.ca_afcars_source_data (
	recnumbr
	,fipscode
	,county_cd
	,county_desc
	,region_cd
	,region_6_cd
	,region_6_tx
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
	,totalrem
	,rem1dt
	,dlstfcdt
	,latremdt
	,cursetdt
	,dodfcdt
	,tprmomdt
	,tprdaddt
	,numplep
	,curplset
	,childid
	,repdat
	,dtreportbeg
	,dtreportend
	,dtreportendfinal
	,dtreportbeg1
	,next6moreport
	,timebetweenreports
	,dq_dropped
	,dq_idnomatchnext6mo
	,dq_missdob
	,dq_missdtlatremdt
	,dq_missnumplep
	,dq_dobgtlatremdt
	,dq_dobgtdodfcdt
	,dq_gt21dobtodtlatrem
	,dq_gt21dobtodtdisch
	,dq_gt21dtdischtodtlatrem
	,dq_dodfcdteqletremdt
	,dq_dodfcdtltletremdt
	,dq_missdisreasn
	,dq_totalrem1
	,entryyr
	,exityr
	,agenmos
	,agenmosyrscat
	,agenyears
	,agenmosyrs
	,agexmos
	,agexmosyrscat
	,agexyrs
	,agexmosyrs
	,disreasn1
	,disreasn2
	,tremcat
	)
SELECT recnumbr
	,fipscode
	,county_cd
	,county_desc
	,region_cd
	,region_6_cd
	,region_6_tx
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
	,totalrem
	,rem1dt
	,dlstfcdt
	,latremdt
	,cursetdt
	,dodfcdt
	,tprmomdt
	,tprdaddt
	,numplep
	,curplset
	,childid
	,repdat
	,dtreportbeg
	,dtreportend
	,dtreportendfinal
	,dtreportbeg1
	,next6moreport
	,timebetweenreports
	,dq_dropped
	,dq_idnomatchnext6mo
	,dq_missdob
	,dq_missdtlatremdt
	,dq_missnumplep
	,dq_dobgtlatremdt
	,dq_dobgtdodfcdt
	,dq_gt21dobtodtlatrem
	,dq_gt21dobtodtdisch
	,dq_gt21dtdischtodtlatrem
	,dq_dodfcdteqletremdt
	,dq_dodfcdtltletremdt
	,dq_missdisreasn
	,dq_totalrem1
	,entryyr
	,exityr
	,agenmos
	,agenmosyrscat
	,agenyears
	,agenmosyrs
	,agexmos
	,agexmosyrscat
	,agexyrs
	,agexmosyrs
	,disreasn1
	,disreasn2
	,tremcat
FROM #location
