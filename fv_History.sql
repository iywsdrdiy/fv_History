USE [Monitor]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE FUNCTION [jobs].[fv_History] (@JobName nvarchar(128))
RETURNS TABLE 
AS
RETURN 
(
-- https://www.mssqltips.com/sqlservertip/6111/query-sql-server-agent-jobs-job-steps-history-and-schedule-system-tables/
SELECT 
row_number() over (partition by sjh.job_id order by sjh.instance_id desc) as sequence --needed to order the table
,  sj.name JobName
, sjh.step_id
, ISNULL(sjs.step_name, 'Job Status') StepName
, isnull(sjs.subsystem, '') subsystem
--, sjs.command
,case sjs.subsystem when 'TSQL' then sjs.command
		when 'SSIS' then
			case left(sjs.command,10) when '/ISSERVER' then	right(left(sjs.command,patindex('%dtsx%',sjs.command)+3),charindex('\',reverse(left(sjs.command,patindex('%dtsx%',sjs.command)+3)))-1)
			else sjs.command end
		else '' end as command
--https://blog.sqlauthority.com/2017/06/02/sql-server-alternate-agent_datetime-function/
--, dbo.agent_datetime(sjh.run_date, sjh.run_time) RunDateAndTime --this fails on BWP, the function doesn't appear to be there or I have wrong privs
,cast(cast(sjh.run_date as char(8))+' '+stuff(stuff(right('000000'+convert(varchar(6),sjh.run_time),6),3,0,':'),6,0,':') as datetime) start
--but there is one final comment on that page that provides a function to to the conversion
--, STUFF(STUFF(RIGHT('00000' + CAST(run_duration AS VARCHAR(6)),6),3,0,':'),6,0,':') duration --fixed width
	,trim('|' from trim ('0:' from 
	 right('0' + convert(varchar,(run_duration/86400)%24),2)+':'+
	 right('0' + convert(varchar,(run_duration/3600)%60),2)+':'+
	 right('0' + convert(varchar,(run_duration/60)%60),2)+':'+
	 right('0' + convert(varchar,run_duration%60),2) + '|'))								[duration] --variable width

, CASE sjh.run_status
    WHEN 0 THEN 'Failed'
    WHEN 1 THEN 'Succeeded'
    WHEN 2 THEN 'Retry'
    WHEN 3 THEN 'Canceled'
    WHEN 4 THEN 'In Progress'
  END RunStatus
, sjh.message
FROM msdb.dbo.sysjobs sj
  INNER JOIN msdb.dbo.sysjobhistory sjh ON sj.job_id = sjh.job_id
  LEFT OUTER JOIN msdb.dbo.sysjobsteps sjs ON sjh.job_id = sjs.job_id AND sjh.step_id = sjs.step_id  
WHERE sj.name = @JobName
--order by sjh.job_id ,sjh.instance_id
)
GO
