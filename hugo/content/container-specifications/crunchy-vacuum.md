---
title: "crunchy-vacuum"
date: 2018-05-24T12:06:12-07:00
draft: false
---

The crunchy-vacuum container allows you to perform a SQL VACUUM job against a PostgreSQL database container.
You specify a database to vacuum using various environment variables which are listed below. It is possible
to run different vacuum operations either manually or automatically through scheduling.

The crunchy-vacuum image is executed, with the Postgres connection parameters passed to the single-primary
PostgreSQL container. The type of vacuum performed is dictated by the environment variables passed into the job.

More information on the PostgreSQL VACUUM job can be found in the [official PostgreSQL documentation](https://www.postgresql.org/docs/current/static/sql-vacuum.html).

## Packages

The crunchy-vacuum Docker image contains the following packages:

* CentOS7 - publicly available
* RHEL7 - customers only

## Environment Variables

### Required
**Name**|**Default**|**Description**
:-----|:-----|:-----
**JOB_HOST**|None|The PostgreSQL host the VACUUM should be performed against.
**PG_USER**|None|Username for the PostgreSQL role being used.
**PG_DATABASE**|None|The PostgreSQL database the VACUUM should be performed against.
**PG_PASSWORD**|None|Password for the PostgreSQL role being used.
**PG_PORT**|5432|Allows you to override the default value of 5432.

### Optional
**Name**|**Default**|**Description**
:-----|:-----|:-----
**VAC_FULL**|TRUE|When set to true, adds the FULL parameter to the VACUUM command.
**VAC_TABLE**|FALSE|When set to true, allows you to specify a single table to vacuum. When not specified, the entire database tables are vacuumed.
**VAC_ANALYZE**|TRUE|When set to true, adds the ANALYZE parameter to the VACUUM command.
**VAC_VERBOSE**|TRUE|When set to true, adds the VERBOSE parameter to the VACUUM command.
**VAC_FREEZE**|FALSE|When set to true, adds the FREEZE parameter to the VACUUM command.
**CRUNCHY_DEBUG**|FALSE|Set this to true to enable debugging in logs. Note: this mode can reveal secrets in logs.
