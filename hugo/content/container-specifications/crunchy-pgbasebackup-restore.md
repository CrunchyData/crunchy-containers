---
title: "crunchy-pgbasebackup-restore"
date:
draft: false
weight: 1
---

The **crunchy-pgbasebackup-restore** container restores a database using a `pg_basebackup` backup.  Specifically, the container
uses `rsync` to copy a `pg_basebackup` backup into a specified `/pgdata` directory.  The container can then prepare the restored 
database for a PITR, allowing for a restore to a specific recovery target, or to the end of the WAL log.

If a recovery target is specified when performing the restore, a `recovery.conf` file will be created and prepared in order
to restore the database to the recovery target specified when deployed.  A recovery target can be specified using one of the 
following environment variables (defined further under the **Optional** environment variables listed below):

* **RECOVERY_TARGET_NAME**
* **RECOVERY_TARGET_TIME**
* **RECOVERY_TARGET_XID**
* **RECOVERY_REPLAY_ALL_WAL**

If one of these environment variables is not specified, then a `recovery.conf` file will not be included in the restore, and
the WAL log will not be replayed to any specific point in time when the database is deployed.


## Packages

The crunchy-pgbasebackup-restore Docker image contains the following packages:

* rsync
* CentOS7 - publicly available
* RHEL7 - customers only

## Environment Variables

### Required
**Name**|**Default**|**Description**
:-----|:-----|:-----
**BACKUP_PATH**|None|The path under the `/backup` volume containing the `pg_basebackup` that will be used for the restore (`/backup` should be excluded when providing the path)
**PGDATA_PATH**|None|The path under the `/pgdata` volume containing the restored database (`/pgdata` should be excluded when providing the path).  The path specified will be created if it does not already exist.

### Optional
**Name**|**Default**|**Description**
:-----|:-----|:-----
**RECOVERY_TARGET_NAME**|None|Sets a named restore point for a PITR in the `recovery.conf` file
**RECOVERY_TARGET_TIME**|None|Sets a timestamp for a PITR the `recovery.conf` file
**RECOVERY_TARGET_XID**|None|Sets a transaction ID for a PITR in the `recovery.conf` file
**RECOVERY_REPLAY_ALL_WAL**|false|If set to `true`, configures the `recovery.conf` file to restore to the end of the WAL log.  Please note that if variable is set to `true` any recovery targets provided will be ignored.
**RECOVERY_TARGET_INCLUSIVE**|true|If set to `true`, configures the `recovery.conf` file to stop after the specified recovery target during the recovery. If set to `false`, the recovery will stop just before the recovery target.
**RSYNC_SHOW_PROGRESS**|false|If set to `true`, the `--progress` flag will be enabled when running rysnc to copy the backup files during the restore
**CRUNCHY_DEBUG**|false|Set this to true to enable debugging in logs. Note: this mode can reveal secrets in logs.

## Volumes

### Required
**Name**|**Description**
:-----|:-----
**/backup**|The volume containing the `pg_basebackup` backup that will be used for the restore
**/pgdata**|The volume that will contain the restored database
