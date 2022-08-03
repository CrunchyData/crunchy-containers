---
title: "crunchy-pgbouncer"
date:
draft: false
---

[pgBouncer](https://pgbouncer.github.io/) is a lightweight connection pooler for PostgreSQL databases.

## Features

The following features are supported by the crunchy-pgbouncer container:

* crunchy-pgbouncer uses `auth_query` to authenticate users.  This requires the `pgbouncer`
   username and password in `users.txt`.  Automatically generated from environment variables, see Restrictions.
* Mount a custom `users.txt` and `pgbouncer.ini` configurations for advanced usage.
* Tune pooling parameters via environment variables.
* Connect to the administration database in pgBouncer to view statistics of the target databases.

## Packages

The crunchy-pgbouncer Docker image contains the following packages (versions vary depending on PostgreSQL version):

* PostgreSQL (13.8, 12.12, 11.17, and 10.22)
* [pgBouncer](https://pgbouncer.github.io/)
* CentOS 7, UBI 8 - publicly available
* UBI 7, UBI 8 - customers only

## Restrictions

* OpenShift: If custom configurations aren't being mounted, an **emptydir** volume is required
   to be mounted at `/pgconf`.
* Superusers cannot connect through the connection pooler.
* User is required to configure the database for auth_query, see pgbouncer.ini file for configuration details.

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
**PG_PORT**|5432|The port to use when connecting to the database.
**CRUNCHY_DEBUG**|FALSE|Set this to true to enable debugging in logs. Note: this mode can reveal secrets in logs.
