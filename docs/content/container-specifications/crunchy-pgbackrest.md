---
title: "crunchy-pgbackrest"
date:
draft: false
---

The `crunchy-pgbackrest` container is used for pgBackRest functions including backup, restore, info, stanza creation and as the pgBackRest remote repository.

See the [pgBackRest](https://github.com/pgbackrest/pgbackrest) guide for more details.


## Running Modes

The `crunchy-pgbackrest` image can be run in modes to enable different functionality.
The `MODE` environment variable must be set to run the image in the required mode. Each mode uses environment variables to configure how the container will be run.

| Running Mode | `MODE` setting |
|--------------|----------------|
| pgBackRest mode is used for taking pgBackRest backups, retrieving info and stanza creation. | `pgbackrest`
| pgBackRest Repo mode acts as a pgBackRest remote repository for the Postgres cluster to use for storing archive files and backups. | `pgbackrest-repo`
| pgBackRest Restore mode executes a pgBackRest restore independent of the Crunchy PostgreSQL Operator. | `pgbackrest-restore`

## Volumes

The following volumes are mounted by the `crunchy-pgbackrest` container:

 * Mounted `pgbackrest.conf` configuration file via the `/pgconf` volume (? not sure about this)
 * `/backrestrepo` volume used by the pgbackrest backup tool to store pgBackRest archives
 * `/pgdata` volume used to store the data directory contents for the PostgreSQL database
 * `/sshd` volume that contains the SSHD configuration from the `backrest-repo-config` secret


## Major Packages

The crunchy-backrest-restore Docker image contains the following packages (versions vary depending on PostgreSQL version):

* PostgreSQL (14.5, 13.8, 12.12, 11.17 and 10.22)
* [pgBackRest](https://pgbackrest.org/) (2.41)
* UBI 8 - publicly available
* UBI 8 - customers only

## Environment Variables

### pgbackrest Mode
**Name**|**Default**|**Description**
:-----|:-----|:-----
**COMMAND**|None|Stores the pgBackRest command to execute.
**COMMAND_OPTS**|None|Options to append the the chosen pgbackrest command.
**CRUNCHY_DEBUG**|FALSE|Set this to true to enable debugging in logs. Note: this mode can reveal secrets in logs.
**MODE**|None|Sets the container mode. Accepted values are `pgbackrest`, `pgbackrest-repo` and `pgbackrest-restore`.
**NAMESPACE**|None|Namespace where the pod lives.
**PGBACKREST_DB_PATH**|None|PostgreSQL data directory. (deprecated)
**PGBACKREST_REPO_PATH**|None|Path where backups and archive are stored.
**PGBACKREST_REPO_TYPE**|None|Type of storage used for the repository.
**PGBACKREST_STANZA**|None|Defines the backup configuration for a specific PostgreSQL database cluster.
**PGHA_PGBACKREST_LOCAL_GCS_STORAGE**|None|Indicates whether or not local and gcs storage should be enabled for pgBackRest.
**PGHA_PGBACKREST_LOCAL_S3_STORAGE**|None|Indicates whether or not local and s3 storage should be enabled for pgBackRest.
**PGHA_PGBACKREST_S3_VERIFY_TLS**|None|Indicates whether or not TLS should be verified when making connections to S3 storage.
**PITR_TARGET**|None|Store the PITR target for a pgBackRest restore.
**PODNAME**|None|Stores the name of the pod to exec into for command execution.


### pgbackrest-repo Mode
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

### pgbackrest-restore Mode
**Name**|**Default**|**Description**
:-----|:-----|:-----
**CRUNCHY_DEBUG**|FALSE|Set this to true to enable debugging in logs. Note: this mode can reveal secrets in logs.
**MODE**|None|Sets the container mode. Accepted values are `pgbackrest`, `pgbackrest-repo` and `pgbackrest-restore`.
**BACKREST_CUSTOM_OPTS**|None|Custom pgBackRest options can be added here to customize pgBackRest restores.
**PGBACKREST_DELTA**|None|Enables pgBackRest delta restore mode.  Used when a user needs to restore to a volume that already contains PostgreSQL data files.
**PGBACKREST_PG1_PATH**|None|Path where PostgreSQL data directory can be found.  This variable can also be used to setup a new PostgreSQL data directory on an empty volume.
**PGBACKREST_STANZA**|None|Must be set to the desired stanza for restore.
**PGBACKREST_TARGET**|None|PostgreSQL timestamp used when restoring up to a point in time. Required for Point In Time Recovery (PITR) restores.
