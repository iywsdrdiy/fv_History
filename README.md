# fv_History

Credit to [Eric Blinn](https://www.mssqltips.com/sqlservertip/6111/query-sql-server-agent-jobs-job-steps-history-and-schedule-system-tables/) and [Pinal Dave](https://blog.sqlauthority.com/2017/06/02/sql-server-alternate-agent_datetime-function/). I've just packaged it as a function and used `row_number over partition` to list the job's history from latest.

`select * from Monitor.jobs.fv_History('Job_of_interest');`


