---
title: "crunchy-backrest-restore"
date:
draft: false
weight: 1
---

The crunchy-backrest-restore container executes the pgBackRest utility, allowing FULL and DELTA restore capability. See the [pgBackRest](https://github.com/pgbackrest/pgbackrest) guide for more details.

## Features

The following features are supported and required by the crunchy-backrest-restore container:

* Mounted `pgbackrest.conf` configuration file via the `/pgconf` volume
* Mounted `/backrestrepo` for access to pgBackRest archives

## Packages

The crunchy-backrest-restore Docker image contains the following packages (versions vary depending on PostgreSQL version):

* PostgreSQL (13.8, 12.12, 11.17, and 10.22)
* [pgBackRest](https://pgbackrest.org/) (2.29)
* CentOS 7, UBI 8 - publicly available
* UBI 7, UBI 8 - customers only

## Environment Variables

### Required

**Name**|**Default**|**Description**
:-----|:-----|:-----
**PGBACKREST_STANZA**|None|Must be set to the desired stanza for restore.

### Optional

**Name**|**Default**|**Description**
:-----|:-----|:-----
**PGBACKREST_DELTA**|None|Enables pgBackRest delta restore mode.  Used when a user needs to restore to a volume that already contains PostgreSQL data files.
**PGBACKREST_TARGET**|None|PostgreSQL timestamp used when restoring up to a point in time. Required for Point In Time Recovery (PITR) restores.
**PGBACKREST_PG1_PATH**|None|Path where PostgreSQL data directory can be found.  This variable can also be used to setup a new PostgreSQL data directory on an empty volume.
**BACKREST_CUSTOM_OPTS**|None|Custom pgBackRest options can be added here to customize pgBackRest restores.
**CRUNCHY_DEBUG**|FALSE|Set this to true to enable debugging in logs. Note: this mode can reveal secrets in logs.
