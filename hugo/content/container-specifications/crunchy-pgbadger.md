---
title: "crunchy-pgbadger"
date: 2018-05-24T12:04:55-07:00
draft: false
---

The crunchy-pgbadger container executes the [pgBadger](http://dalibo.github.io/pgbadger) utility, which
generates a PostgreSQL log analysis report using a small HTTP server running on the container. This log
report can be accessed through the URL **http://<<ip address>>:10000/api/badgergenerate**.

## Features

The following features are supported by the crunchy-pgbadger container:

 * Generate a full report by default
 * Optional custom options for more advanced use cases (such as `incremental` reports)
 * Report persistence on a volume

## Packages

The crunchy-badger Docker image contains the following packages:

* [pgBadger](http://dalibo.github.io/pgbadger)
* CentOS7 - publicly available
* RHEL7 - customers only

## Environment Variables

### Required
**Name**|**Default**|**Description**
:-----|:-----|:-----
**BADGER_TARGET**|None|Only used in standalone mode to specify the name of the container. Also used to find the location of the database log files in `/pgdata/$BADGER_TARGET/pg_log/*.log`.

### Optional
**Name**|**Default**|**Description**
:-----|:-----|:-----
**BADGER_CUSTOM_OPTS**|None|For a list of optional flags, see the [official pgBadger documentation](http://dalibo.github.io/pgbadger).
**CRUNCHY_DEBUG**|FALSE|Set this to true to enable debugging in logs. Note: this mode can reveal secrets in logs.
