---
title: "crunchy-pgdump"
date: 2018-05-24T12:08:16-07:00
draft: false
weight: 5
---

The crunchy-pgdump container executes either a pg_dump or pg_dumpall database backup against another
PostgreSQL database.

## Packages

The crunchy-pgdump Docker image contains the following packages (versions vary depending on PostgreSQL version):

* PostgreSQL (9.5.13, 9.6.9 and 10.4)
* CentOS7 - publicly available
* RHEL7 - customers only

## Environment Variables

### Required
**Name**|**Default**|**Description**
:-----|:-----|:-----
**PGDUMP_DB**|None|Name of the database the backup is being performed on.
**PGDUMP_HOST**|None|Hostname of the database the backup is being performed on.
**PGDUMP_PASS**|None|Password for the PostgreSQL role being used.
**PGDUMP_USER**|None|Username for the PostgreSQL role being used.

### Optional
**Name**|**Default**|**Description**
:-----|:-----|:-----
**PGDUMP_ALL**|TRUE|Run `pg_dump` instead of `pg_dumpall`. Set to false to enable `pg_dump`.
**PGDUMP_CUSTOM_OPTS**|None|Advanced options to pass into `pg_dump` or `pg_dumpall`.
**PGDUMP_FILENAME**|dump|Name of the file created by the `pgdump` container.
**PGDUMP_PORT**|5432|Port of the PostgreSQL database to connect to.
**CRUNCHY_DEBUG**|FALSE|Set this to true to enable debugging in logs. Note: this mode can reveal secrets in logs.

{{% notice tip %}}
For a list of advanced options for configuring the `PGDUMP_CUSTOM_OPTS` variable, see the official documentation:

https://www.postgresql.org/docs/current/static/app-pgdump.html

https://www.postgresql.org/docs/current/static/app-pg-dumpall.html
{{% /notice %}}

## Volumes

**Name**|**Description**
:-----|:-----
**/pgdata**|Volume used to store the data directory contents for the PostgreSQL database.

## Dump Location

Backups are stored in a mounted backup volume location, using the
database host name plus *-backups*  as a sub-directory, then followed by a unique
backup directory based upon a date/timestamp.  It is left to the
user to perform database backup archives in this current version
of the container. This backup location is referenced when performing
a database restore.
