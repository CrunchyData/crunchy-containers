---
title: "crunchy-pgbouncer"
date: 2018-05-24T12:05:03-07:00
draft: false
---

[pgBouncer](https://pgbouncer.github.io/) is a lightweight connection pooler for PostgreSQL databases.

## Features

The following features are supported by the crunchy-pgbouncer container:

 * crunchy-pgbouncer uses `auth_query` to authenticate users.  This requires only the `pgbouncer`
   username and password in `users.txt`.  Automatically generated from environment variables.
 * Mount a custom `users.txt` and `pgbouncer.ini` configurations for advanced usage.
 * Tune pooling parameters via environment variables.
 * Connect to the administration database in pgBouncer to view statistics of the target databases.

## Packages

The crunchy-pgbouncer Docker image contains the following packages (versions vary depending on PostgreSQL version):

* PostgreSQL (9.5.13, 9.6.9 and 10.4)
* [pgBouncer](https://pgbouncer.github.io/)
* CentOS7 - publicly available
* RHEL7 - customers only

## Restrictions

 * OpenShift: If custom configurations aren't being mounted, an **emptydir** volume is required
   to be mounted at `/pgconf`.
 * Superusers cannot connect through the connection pooler.

## Environment Variables

### Required
**Name**|**Default**|**Description**
:-----|:-----|:-----
**PGBOUNCER_PASSWORD**|None|The password of the pgBouncer role in PostgreSQL. Must be also set on the primary database.
**PG_SERVICE**|None|The hostname of the database service.

### Optional
**Name**|**Default**|**Description**
:-----|:-----|:-----
**DEFAULT_POOL_SIZE**|20|How many server connections to allow per user/database pair.
**MAX_CLIENT_CONN**|100|Maximum number of client connections allowed.
**MAX_DB_CONNECTIONS**|Unlimited|Do not allow more than this many connections per-database.
**MIN_POOL_SIZE**|0|Adds more server connections to pool if below this number.
**POOL_MODE**|Session|When a server connection can be reused by other clients. Possible values: `session`, `transaction` and `statement`.
**RESERVE_POOL_SIZE**|0|How many additional connections to allow per pool. 0 disables.
**RESERVE_POOL_TIMEOUT**|5|If a client has not been serviced in this many seconds, pgbouncer enables use of additional connections from reserve pool. 0 disables.
**QUERY_TIMEOUT**|0|Queries running longer than that are canceled.
**IGNORE_STARTUP_PARAMETERS**|extra_float_digits|Set to ignore particular parameters in startup packets.
**CRUNCHY_DEBUG**|FALSE|Set this to true to enable debugging in logs. Note: this mode can reveal secrets in logs.
