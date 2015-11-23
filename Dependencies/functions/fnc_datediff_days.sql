

create function [dbo].[fnc_datediff_days](@BEGIN_DATE datetime,@END_DATE datetime)
returns int
begin
-- Count of full days between dates. A full day requires a full 24 hours down to the second.
--DECLARE @BEGIN_DATE DATETIME = '2014-04-12 21:36:43.997'
--	,@END_DATE DATETIME = '2014-04-13 21:36:43.730'

DECLARE @diff int

IF @END_DATE < @BEGIN_DATE
begin
	DECLARE @TEMP_DATE DATETIME = @END_DATE
	SET @END_DATE = @BEGIN_DATE
	SET @BEGIN_DATE = @TEMP_DATE
end

IF cast(replace(convert(varchar,@END_DATE,8),':','') as int) < cast(replace(convert(varchar,@BEGIN_DATE,8),':','') as int)

	SET @diff = datediff(dd,@BEGIN_DATE,@END_DATE) - 1

ELSE

	SET @diff = datediff(dd,@BEGIN_DATE,@END_DATE)

--PRINT @diff
RETURN @diff

end




