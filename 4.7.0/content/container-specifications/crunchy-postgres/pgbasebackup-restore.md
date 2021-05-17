---
title: "pgbasebackup-restore"
---

The pgbasebackup-restore running mode restores a database using a `pg_basebackup` backup.  Specifically, the container
uses `rsync` to copy a `pg_basebackup` backup into a specified `/pgdata` directory.

The pgbasebackup-restore mode does not support point-in-time-recovery (PITR). If you would to create an environment that allows you to use PostgreSQL's point-in-time-recovery capabilities, please use the [crunchy-backrest](crunchy-backrest.md) container with a corresponding pgBackRest repository.

MODE: `pgbasebackup-restore`

## Environment Variables

### Required
**Name**|**Default**|**Description**
:-----|:-----|:-----
**MODE**|None|Set to `pgbasebackup-restore` to run as `pg_basebackup` restore job
**BACKUP_PATH**|None|The path under the `/backup` volume containing the `pg_basebackup` that will be used for the restore (`/backup` should be excluded when providing the path)
**PGDATA_PATH**|None|The path under the `/pgdata` volume containing the restored database (`/pgdata` should be excluded when providing the path).  The path specified will be created if it does not already exist.

### Optional
**Name**|**Default**|**Description**
:-----|:-----|:-----
**RSYNC_SHOW_PROGRESS**|false|If set to `true`, the `--progress` flag will be enabled when running rysnc to copy the backup files during the restore
**CRUNCHY_DEBUG**|false|Set this to true to enable debugging in logs. Note: this mode can reveal secrets in logs.
