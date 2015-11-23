
CREATE function [dbo].[fnc_datediff_yrs](@BEGIN_DATE datetime,@END_DATE datetime)
returns int
begin

--DECLARE @BEGIN_DATE DATETIME = '2010-01-31 21:36:43.997'
--	,@END_DATE DATETIME = '2011-12-30 07:39:02.730'

DECLARE @diff int

IF @END_DATE < @BEGIN_DATE
begin
	DECLARE @TEMP_DATE DATETIME = @END_DATE
	SET @END_DATE = @BEGIN_DATE
	SET @BEGIN_DATE = @TEMP_DATE
end

IF month(@END_DATE) < month(@BEGIN_DATE) OR (month(@END_DATE) = month(@BEGIN_DATE) AND day(@END_DATE) < day(@BEGIN_DATE))

	SET @diff = datediff(yyyy,@BEGIN_DATE,@END_DATE) - 1
	
ELSE

	SET @diff = datediff(yyyy,@BEGIN_DATE,@END_DATE)
	

--PRINT @diff
RETURN @diff

end



