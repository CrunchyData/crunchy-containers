---
title: "crunchy-dba"
date: 2018-05-24T12:05:24-07:00
draft: false
---

The crunchy-dba container implements a cron scheduler.  The purpose
of the crunchy-dba container is to offer a way to perform
simple DBA tasks that occur on some form of schedule such as
backup jobs or running a vacuum on a *single* PostgreSQL database container.

You can either run the crunchy-dba container as a single pod or include
the container within a database pod.

The crunchy-dba container makes use of a Service Account to perform
the startup of scheduled jobs.  The Kubernetes Job type is used to execute
the scheduled jobs with a Restart policy of Never.

## Packages

The crunchy-dba Docker image contains the following packages:

* CentOS7 - publicly available
* RHEL7 - customers only

## Environment Variables

### General
**Name**|**Default**|**Description**
:-----|:-----|:-----
**OSE_PROJECT**|None|The OSE project name to log into.
**JOB_HOST**|None|The PostgreSQL container name the action will be taken against.
**VAC_SCHEDULE**|None|If set, this will start a vacuum job container. The setting value must be a valid cron expression as described below.
**BACKUP_SCHEDULE**|None|If set, this will start a backup job container. The setting value must be a valid cron expression as described below.
**CRUNCHY_DEBUG**|FALSE|Set this to true to enable debugging in logs. Note: this mode can reveal secrets in logs.

### Vacuum Job

For a vacuum job, you are required to supply the following environment variables:

**Name**|**Default**|**Description**
:-----|:-----|:-----
**JOB_HOST**|None|The PostgreSQL container name the action will be taken against.
**PG_USER**|None|Username for the PostgreSQL role being used.
**PG_PASSWORD**|None|Password for the PostgreSQL role being used.
**PG_DATABASE**|postgres|Database host to connect to.
**PG_PORT**|5432|Allows you to override the default value of 5432.
**VAC_ANALYZE**|TRUE|When set to true, adds the ANALYZE parameter to the VACUUM command.
**VAC_FULL**|TRUE|hen set to true, adds the FULL parameter to the VACUUM command.
**VAC_VERBOSE**|TRUE|When set to true, adds the VERBOSE parameter to the VACUUM command.
**VAC_FREEZE**|FALSE|When set to true, adds the FREEZE parameter to the VACUUM command.
**VAC_TABLE**|FALSE|When set to true, allows you to specify a single table to vacuum. When not specified, the entire database tables are vacuumed.

### Backup Job

For a backup job, you are required to supply the following environment variables:

**Name**|**Default**|**Description**
:-----|:-----|:-----
**JOB_HOST**|None|The PostgreSQL container name the action will be taken against.
**PG_USER**|None|Username for the PostgreSQL role being used.
**PG_PASSWORD**|None|Password for the PostgreSQL role being used.
**PG_PORT**|5432|Allows you to override the default value of 5432.
**BACKUP_PV_CAPACITY**|None|A value like 1Gi is used to define the PV storage capacity.
**BACKUP_PV_PATH**|None|The storage path used to build the PV.
**BACKUP_PV_HOST**|None|The storage host used to build the PV.
**BACKUP_PVC_STORAGE**|None|A value like 75M means to allow 75 megabytes for the PVC used in performing the backup.

## CRON Expression Format

A cron expression represents a set of times, using 6 space-separated fields.

**Field Name**|**Mandatory?**|**Allowed Values**|**Allowed Special Characters**
:-----|:-----|:-----|:-----
**Seconds**|Yes|0-59|* / , -
**Minutes**|Yes|0-59|* / , -
**Hours**|Yes|0-23|* / , -
**Day of month**|Yes|1-31|* / , - ?
**Month**|Yes|1-12 or JAN-DEC|* / , -
**Day of week**|Yes|0-6 or SUN-SAT|* / , - ?

{{% notice tip %}}
Month and Day-of-week field values are case insensitive.  "SUN", "Sun", and "sun" are equally accepted.
{{% /notice %}}

### Special Characters

#### Asterisk

The asterisk indicates that the cron expression will match for all values
of the field; e.g., using an asterisk in the 5th field (month) would
indicate every month.

#### Slash

Slashes are used to describe increments of ranges. For example 3-59/15 in
the 1st field (minutes) would indicate the 3rd minute of the hour and every
15 minutes thereafter. The form "*\/..." is equivalent to the form
"first-last/...", that is, an increment over the largest possible range of
the field.  The form "N/..." is accepted as meaning "N-MAX/...", that is,
starting at N, use the increment until the end of that specific range.
It does not wrap around.

#### Comma

Commas are used to separate items of a list. For example, using
"MON,WED,FRI" in the 5th field (day of week) would mean Mondays,
Wednesdays and Fridays.

#### Hyphen

Hyphens are used to define ranges. For example, 9-17 would indicate every
hour between 9am and 5pm inclusive.

#### Question mark

Question mark may be used instead of "*" for leaving either day-of-month or
day-of-week blank.

### Predefined schedules

You may use one of several pre-defined schedules in place of a cron expression.

**Entry**|**Description**|**Equivalent To**
:-----|:-----|:-----
**@yearly (or @annually)**|Run once a year, midnight, Jan. 1st|0 0 0 1 1 *
**@monthly**|Run once a month, midnight, first of month|0 0 0 1 * *
**@weekly**|Run once a week, midnight on Sunday|0 0 0 * * 0
**@daily (or @midnight)**|Run once a day, midnight|0 0 0 * * *
**@hourly**|Run once an hour, beginning of hour|0 0 * * * *

### Intervals

You may also schedule a job to execute at fixed intervals.  This is
supported by formatting the cron spec like this:

```
@every <duration>
```

where "duration" is a string accepted by time.ParseDuration
(http://golang.org/pkg/time/#ParseDuration).

For example, "@every 1h30m10s" would indicate a schedule that activates every
1 hour, 30 minutes, 10 seconds.

NOTE: The interval does not take the job runtime into account.  For example,
if a job takes 3 minutes to run, and it is scheduled to run every 5 minutes,
it will have only 2 minutes of idle time between each run.

### Time zones

All interpretation and scheduling is done in the machines local
time zone (as provided by the Go time package
(http://www.golang.org/pkg/time).

{{% notice tip %}}
Be aware that jobs scheduled during daylight-savings leap-ahead transitions will not be run.
{{% /notice %}}
