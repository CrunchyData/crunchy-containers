---
title: "crunchy-pgbackrest-repo"
date:
draft: false
---

The crunchy-pgbackrest-repo container acts as a pgBackRest remote repository for the Postgres cluster to use for storing archive files and backups.

See the [pgBackRest](https://github.com/pgbackrest/pgbackrest) guide for more details.

## Volumes

The following volumes are mounted by the `crunchy-pgbackrest-repo` container:

 * `/backrestrepo` volume used by the pgbackrest backup tool to store pgBackRest archives
 * `/pgdata` volume is not used by this container, but required by the `crunchy-pgbackrest` parent container.
 * `/sshd` volume that contains the SSHD configuration from the `backrest-repo-config` secret

## Packages

The crunchy-backrest-repo image contains the following packages:

* [pgBackRest](https://pgbackrest.org/) (2.31)
* CentOS 7, UBI 8 - publicly available
* UBI 7, UBI 8 - customers only

## Environment Variables

**Name**|**Default**|**Description**
:-----|:-----|:-----
**CRUNCHY_DEBUG**|FALSE|Set this to true to enable debugging in logs. Note: this mode can reveal secrets in logs.
**MODE**|None|Sets the container mode. Accepted values are `pgbackrest`, `pgbackrest-repo` and `pgbackrest-restore`.
**PGBACKREST_DB_PATH**|None|PostgreSQL data directory. (deprecated)
**PGBACKREST_DB_HOST**|None|PostgreSQL host for operating remotely via SSH. (deprecated)
**PGBACKREST_LOG_PATH**|None|Path where log files are stored.
**PGBACKREST_PG1_PORT**|None|Port that PostgreSQL is running on.
**PGBACKREST_PG1_SOCKET_PATH**|None|PostgreSQL unix socket path.
**PGBACKREST_REPO_PATH**|None|Path where backups and archive are stored.
**PGBACKREST_STANZA**|None|Defines the backup configuration for a specific PostgreSQL database cluster. Must be set to the desired stanza for restore.
