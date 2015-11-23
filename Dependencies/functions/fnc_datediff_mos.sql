

CREATE function [dbo].[fnc_datediff_mos](@BEGIN_DATE datetime,@END_DATE datetime)
returns int
begin

--DECLARE @BEGIN_DATE DATETIME = '2012-03-15 21:36:43.997'
--	,@END_DATE DATETIME = '2014-04-12 07:39:02.730'

DECLARE @diff int
if (@BEGIN_DATE<=@END_DATE)
begin
IF day(@END_DATE) < day(@BEGIN_DATE)

	SET @diff = datediff(mm,@BEGIN_DATE,@END_DATE) - 1

ELSE

	SET @diff = datediff(mm,@BEGIN_DATE,@END_DATE)
end
--PRINT @diff
RETURN @diff

end




