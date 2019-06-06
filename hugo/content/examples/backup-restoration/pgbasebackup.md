---
title: "pgBaseBackup"
date:
draft: false
weight: 31
---

# pgBaseBackup Examples


The script assumes you are going to backup the *primary*
container created in the first example, so you need to ensure
that container is running. This example assumes you have configured storage as described
in the [Storage Configuration documentation](/installation/storage-configuration/). Things to point out with this example
include its use of persistent volumes and volume claims to store the backup data files.

A successful backup will perform `pg_basebackup` on the *primary* container and store
the backup in the `$CCP_STORAGE_PATH` volume under a directory named `$CCP_NAMESPACE-primary-backups`. Each
backup will be stored in a subdirectory with a timestamp as the name, allowing any number of backups to be kept.

The backup script will do the following:

* Start up a backup container or Kubernetes job named *backup*
* Run `pg_basebackup` on the container named *primary*
* Store the backup in the `/backup` volume
* Exit after the backup

When you are ready to restore from the backup, the restore example runs a `pgbasebackup-restore` container or Kubernetes job
in order to restore the database into a new pgdata directory, specifically using rsync to copy the backup data into
the new directory.  A `crunchy-postgres` container then deployed using the restored database, deploying a new PostgreSQL DB
that utilizes the original backed-up data.

The restore scripts will do the following:

* Start up a container or Kubernetes job named *restore*
* Copy the backup files from the previous backup example into `/pgdata`
* Deploy a `crunchy-postgres` container using the restored database

To shutdown and remove any artifacts from the example, run the following under each directory utilized when running the example:
```
./cleanup.sh
```

### Docker

Perform a backup of *primary* using `pg_basebackup` by running the following script:
```
cd $CCPROOT/examples/docker/pgbasebackup/backup
./run.sh
```

When you're ready to restore, a *restore* example is provided.  In order to run the restore, a path for the backup
must be provided to the `pgabasebackup-restore` container using the `BACKUP_PATH` environment variable.  To get the correct path, check the logs for the `backup` container:

```
docker logs backup | grep BACKUP_PATH
Fri May 10 01:40:06 UTC 2019 INFO: BACKUP_PATH is set to /pgdata/primary-backups/2019-05-10-01-40-06.
```

`BACKUP_PATH` can also be discovered by looking at the backup mount directly (if access
to the storage is available to the user).

When you are ready to restore from the backup, first update the `$CCPROOT/examples/docker/pgbasebackup/full/run.sh` 
script used to run restore example with the proper `BACKUP_PATH`:

```
--env BACKUP_PATH=primary-backups/2019-05-09-11-53-32 \
```

Then run the restore:
```
cd $CCPROOT/examples/docker/pgbasebackup/full
./run.sh
```

Once the restore is complete, the restored database can then be deployed by running the post restore script:
```
./post-restore.sh
```

You can then test the restored database as follows:
```
docker exec -it pgbasebackup-full-restored psql
```

### Kubernetes and OpenShift

Perform a backup of *primary* using `pg_basebackup` by running the following script:
``` 
cd $CCPROOT/examples/kube/pgbasebackup/backup
./run.sh
```

This runs a Kubernetes job, which deploys a pod that performs the backup using `pg_basebackup`,
and then exits.  You can view the status of the job by running the following command:
```
${CCP_CLI} get job
```

When you're ready to restore, a *restore* example is provided.  In order to run the restore, a path for the backup
must be provided to the `pgabasebackup-restore` container using the `BACKUP_PATH` environment variable.  To get the correct path, check the logs for the `backup` job:

```
kubectl logs backup-txcvm | grep BACKUP_PATH
Fri May 10 01:40:06 UTC 2019 INFO: BACKUP_PATH is set to /pgdata/primary-backups/2019-05-10-01-40-06.
```

`BACKUP_PATH` can also be discovered by looking at the backup mount directly (if access
to the storage is available to the user).

When you are ready to restore from the backup, first update `$CCPROOT/examples/kube/pgbasebackup/full/restore.json`
with the proper `BACKUP_PATH`:
```
{
    "name": "BACKUP_PATH",
    "value": "primary-backups/2019-05-08-18-28-45"
}
```

Then run the restore:
```
cd $CCPROOT/examples/kube/pgbasebackup/full
./run.sh
```

Once the restore is complete, the restored database can then be deployed by running the post restore script:
```
./post-restore.sh
```

You can then test the restored database as follows:
```
kubectl exec -it pgbasebackup-full-restored-7d866cd5f7-qr6w8 -- psql
```

## Point in Time Recovery (PITR)

PITR (point-in-time-recovery) is a feature that allows for recreating a database
from backup and log files at a certain point in time. This is done using a write
ahead log (WAL) which is kept in the `pg_wal` directory within `PGDATA`. Changes
made to the database files over time are recorded in these log files, which allows
it to be used for disaster recovery purposes.

When using PITR as a backup method, in order to restore from the last checkpoint in
the event of a database or system failure, it is only necessary to save these log
files plus a full backup. This provides an additional advantage in that it is not
necessary to keep multiple full backups on hand, which consume space and time to create.
This is because point in time recovery allows you to "replay" the log files and recover
your database to any point since the last full backup.

More detailed information about Write Ahead Log (WAL) archiving can be found
[here.](https://www.postgresql.org/docs/10/static/continuous-archiving.html)

By default in the crunchy-postgres container, WAL logging is *not* enabled.
To enable WAL logging *outside of this example*, set the following environment
variables when starting the crunchy-postgres container:
```
ARCHIVE_MODE=on
ARCHIVE_TIMEOUT=60
```

These variables set the same name settings within the `postgresql.conf`
file that is used by the database. When set, WAL files generated by the database
will be archived to the `/pgwal` mount point.

A full backup is required to do a PITR.  The `crunchy-backup` container is utilized to 
perform the backup in the example below, specifically running `pg_basebackup` to backup 
the database. 

After the backup is complete, a restore can then be performed.  The restore is performed
using the `pgbasebackup-restore` container, which uses rysnc to copy a `pg_basebackup` 
backup into a new pgdata directory.

There are two volume mounts used when performing the restore.

* `/backup` - The volume containing the backup you would like to restore from.
* `/pgdata` - The volume containing the restored database

The following environment variables can be used to manipulate the point in time recovery logic when performing 
the restore using the `pgbasebackup-restore` container, specifically configuring the proper recovery target
within the `recovery.conf` file:

* `RECOVERY_TARGET_NAME` - Used to restore to a named restore point
* `RECOVERY_TARGET_TIME` - Used to restore to a specific timestamp
* `RECOVERY_TARGET_XID` - Used to restore to a specific transaction ID

If you would rather restore to the end of the WAL log, the `RECOVERY_REPLAY_ALL_WAL` environment varibale can
be set to `true`.  Please note that if this enviornment variable is set, then any recovery targets specified via
the environment variables described above will be ignored. 

The `RECOVERY_TARGET_INCLUSIVE` environment variable is also available to
let you control the setting of the `recovery.conf` setting `recovery_target_inclusive`.
If you do not set this environment variable the default is *true*.

Once you recover a database using PITR, it will be in read-only mode. To
make the database resume as a writable database, run the following SQL command:
```
postgres=# select pg_wal_replay_resume();
```

{{% notice tip %}}
If you're running the PITR example for *PostgreSQL versions 9.5 or 9.6*, please note that
starting in PostgreSQL version 10, the `pg_xlog` directory was renamed to `pg_wal`. Additionally, all usages
of the function `pg_xlog_replay_resume` were changed to `pg_wal_replay_resume`.
{{% /notice %}}

It takes about 1 minute for the database to become ready for use after initially starting.

To shutdown and remove any artifacts from the example, run the following:
```
./cleanup.sh
```

### Docker

Create a database container as follows:
```
cd $CCPROOT/examples/docker/pgbasebackup/pitr
./run-pitr.sh
```

Next, we will create a base backup of that database as follows:
```
./run-backup-pitr.sh
```

This will create a backup and write the backup files to a persistent
volume (specifically Docker named volume `pitr-backup-volume`). Additionally, 
WAL segment files will be created every 60 seconds under the `pgwal` directory
of the running `pitr` container that contain any additional database changes.

Next, create some recovery targets within the database by running
the SQL commands against the *pitr* database as follows:
```
./run-sql.sh
```

This will create recovery targets named `beforechanges`, `afterchanges`, and
`nomorechanges`.  It will create a table, *pitrtest*, between
the `beforechanges` and `afterchanges` targets.  It will also run a SQL
`CHECKPOINT` to flush out the changes to WAL segments. These labels can be
used to mark the points in the recovery process that will be referenced when
creating the restored database.

Next, now that we have a base backup and a set of WAL files containing
our database changes, we can shut down the *pitr* database
to simulate a database failure.  Do this by running the following:
```
docker stop pitr
```

Now get the BACKUP_PATH created by the `backup-pitr` example by viewing the containers logs:

```
docker logs backup-pitr | grep PATH
Thu May 10 18:07:58 UTC 2018 INFO: BACKUP_PATH is set to /pgdata/pitr-backups/2018-05-10-18-07-58.
```

Edit the `run-restore-pitr.sh` file and change the `BACKUP_PATH` environment variable
using the path discovered above:

```
--env BACKUP_PATH=pitr-backups/2018-05-10-18-07-58 \
```

Next, we restore prior to the `beforechanges` recovery target.  This
recovery point is *before* the *pitrtest* table is created.

Open file `run-restore-pitr.sh`, and edit the environment
variable to indicate we want to use the `beforechanges` recovery
point:
```
--env RECOVERY_TARGET_NAME=beforechanges \
```

Then run the following to restore the database:
```
./run-restore-pitr.sh
```

Once the restore is complete, the restored database can then be deployed by running the post restore script:
```
./post-restore.sh
```

As a result of the `recovery.conf` file configured using `RECOVERY_TARGET_NAME` when performing the restore,
the WAL segments are read from the WAL archive and applied up until the `beforechanges` named restore point.
At this point you should therefore be able to verify that the database was restored to the point before creating
the test table:
```
docker exec -it pgbasebackup-pitr-restored psql -c 'table pitrtest'
```

This SQL command should show that the pitrtest table does not exist
at this recovery time. The output should be similar to:
```
ERROR: relation "pitrtest" does not exist
```

PostgreSQL allows you to pause the recovery process if the target name
or time is specified.  This pause would allow a DBA a chance to review
the recovery time/name/xid and see if this is what they want or expect.  If so,
the DBA can run the following command to resume and complete the recovery:
```
docker exec -it pgbasebackup-pitr-restored psql -c 'select pg_wal_replay_resume()'
```

Until you run the statement above, the database will be left in read-only
mode.

Next, run the script to restore the database
to the `afterchanges` restore point. Update the `RECOVERY_TARGET_NAME` to `afterchanges`
in `run-restore-pitr.sh`:
```
--env RECOVERY_TARGET_NAME=afterchanges \
```

Then run the following to again restore the database:
```
./run-restore-pitr.sh
```

Once the restore is complete, the restored database can then once again be deployed by running the post restore script:
```
./post-restore.sh
```

After this restore you should be able to see the test table, and will still be required to make the database writable:
```
docker exec -it pgbasebackup-pitr-restored psql -c 'table pitrtest'
docker exec -it pgbasebackup-pitr-restored psql -c 'select pg_wal_replay_resume()'
```

Lastly, start a restore to the end of the WAL log. This will restore the database to the most current point 
possible. To do so, edit `run-restore-pitr.sh` and remove `RECOVERY_TARGET_NAME`, and then set environment variable 
`RECOVERY_REPLAY_ALL_WAL` to `true`:
```
--env RECOVERY_REPLAY_ALL_WAL=true \
```

Then run the following to again restore the database:
```
./run-restore-pitr.sh
```

Once the restore is complete, the restored database can then once again be deployed by running the post restore script:
```
./post-restore.sh
```

At this point, you should be able to create new data in the restored database
and the test table should be present.  When you recover the entire
WAL history, resuming the recovery is not necessary to enable writes.

```
docker exec -it pgbasebackup-pitr-restored psql -c 'table pitrtest'
docker exec -it pgbasebackup-pitr-restored psql -c 'create table foo (id int)'
```

### Kubernetes and OpenShift

Start by running the example database container:
```
cd $CCPROOT/examples/kube/pgbasebackup/pitr
./run-pitr.sh
```

This step will create a database container, *pitr*.  This
container is configured to continuously archive WAL segment files
to a mounted volume (`/pgwal`).

After you start the database, you will create a `pg_basebackup` backup
using this command:
```
./run-backup-pitr.sh
```

This will create a backup and write the backup files to a persistent
volume made available to the `crunchy-backup` container via Persistent 
Volume Claim `backup-pitr-pgdata`.

Next, create some recovery targets within the database by running
the SQL commands against the *pitr* database as follows:
```
./run-sql.sh
```

This will create recovery targets named `beforechanges`, `afterchanges`, and
`nomorechanges`.  It will create a table, *pitrtest*, between
the `beforechanges` and `afterchanges` targets.  It will also run a SQL
`CHECKPOINT` to flush out the changes to WAL segments.

Next, now that we have a `pg_basebackup` backup and a set of WAL files containing
our database changes, we can shut down the *pitr* database
to simulate a database failure.  Do this by running the following:
```
${CCP_CLI} delete deployment pitr
```

Next, we will create 3 different restored database containers based
upon the base backup and the saved WAL files.

First, get the BACKUP_PATH created by the `backup-pitr` example by viewing the pods logs:

```
${CCP_CLI} logs backup-pitr-8sfkh | grep PATH
Thu May 10 18:07:58 UTC 2018 INFO: BACKUP_PATH is set to /pgdata/pitr-backups/2018-05-10-18-07-58.
```

Edit the `restore-pitr.json` file and change the `BACKUP_PATH` environment variable
using the path discovered above (note: `/pgdata/` is not required and should be excluded
in the variable):

```
{
    "name": "BACKUP_PATH",
    "value": "pitr-backups/2018-05-10-18-07-58"
{
```

Next, we restore prior to the `beforechanges` recovery target.  This
recovery point is *before* the *pitrtest* table is created.

Edit the `restore-pitr.json` file, and edit the environment
variable to indicate we want to use the `beforechanges` recovery
point:
```
{
    "name": "RECOVERY_TARGET_NAME",
    "value": "beforechanges"
{
```


Then run the following to restore the database:
```
./run-restore-pitr.sh
```

Once the restore is complete, the restored database can then once again be deployed by running the post restore script:
```
./post-restore.sh
```

After the database has restored, you should be able to perform
a test to see if the recovery worked as expected:
```
kubectl exec -it pgbasebackup-pitr-restored-5c5df7894c-hczff -- psql -c 'table pitrtest'
kubectl exec -it pgbasebackup-pitr-restored-5c5df7894c-hczff -- psql -c 'create table foo (id int)'
```

The output of these commands should show that the *pitrtest* table is not
present.  It should also show that you can not create a new table
because the database is paused in read-only mode.

To make the database resume as a writable database, run the following
SQL command:
```
kubectl exec -it pgbasebackup-pitr-restored-5c5df7894c-hczff -- psql -c 'select pg_wal_replay_resume()'
```

It should then be possible to write to the database:
```
kubectl exec -it pgbasebackup-pitr-restored-5c5df7894c-hczff -- psql -c 'create table foo (id int)'
```

You can also test that if `afterchanges` is specified, that the
*pitrtest* table is present but that the database is still in recovery
mode.

Lastly, you can test a full recovery using *all* of the WAL files by removing any recovery targets,
and setting `RECOVERY_REPLAY_ALL_WAL` to `true`.

The storage portions of this example can all be found under `$CCP_STORAGE_PATH/$CCP_NAMESPACE-restore-pitr`.
