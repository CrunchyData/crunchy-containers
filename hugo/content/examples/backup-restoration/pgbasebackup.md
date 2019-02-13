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

* Start up a backup container named backup
* Run `pg_basebackup` on the container named *primary*
* Store the backup in the `/tmp/backups/primary-backups` directory
* Exit after the backup

When you are ready to restore from the backup, the restore example runs a PostgreSQL container
using the backup location. Upon initialization, the container will use rsync to copy the backup
data to this new container and then launch PostgreSQL using the original backed-up data.

The restore script will do the following:

* Start up a container named *restore*
* Copy the backup files from the previous backup example into `/pgdata`
* Start up the container using the backup files
* Map the PostgreSQL port of 5432 in the container to your local host port of 12001

To shutdown the instance and remove the container for each example, run the following:
```
./cleanup.sh
```

### Docker

Run the backup with this command:
```
cd $CCPROOT/examples/docker/pgbasebackup/backup
./run.sh
```

When you're ready to restore, a *restore* example is provided.

It's required to specified a backup path for this example.  To get the correct path
check the `backup` job logs or a timestamp:

```
docker logs backup-vpk9l | grep BACKUP_PATH
Wed May  9 20:32:00 UTC 2018 INFO: BACKUP_PATH is set to /pgdata/primary-backups/2018-05-09-20-32-00.
```

BACKUP_PATH can also be discovered by looking at the backup mount directly (if access
to the storage is available to the user).

An example of BACKUP_PATH is as followed:
```
"name": "BACKUP_PATH",
"value": "primary-backups/2018-05-09-20-32-00"
```

When you are ready to restore from the backup created, run the following example:
```
cd $CCPROOT/examples/docker/pgbasebackup/full
./run.sh
```

### Kubernetes and OpenShift

Running the example:
```
cd $CCPROOT/examples/kube/pgbasebackup/backup
./run.sh
```

The Kubernetes Job type executes a pod and then the pod exits.  You can
view the Job status using this command:
```
${CCP_CLI} get job
```

When you're ready to restore, a *restore* example is provided.

It's required to specified a backup path for this example.  To get the correct path
check the `backup` job logs or a timestamp:
```
kubectl logs backup-vpk9l | grep BACKUP_PATH
Wed May  9 20:32:00 UTC 2018 INFO: BACKUP_PATH is set to /pgdata/primary-backups/2018-05-09-20-32-00.
```

BACKUP_PATH can also be discovered by looking at the backup mount directly (if access
to the storage is available to the user).

An example of BACKUP_PATH defined as a variable within the JSON script is as follows:
```
"name": "BACKUP_PATH",
"value": "primary-backups/2018-05-09-20-32-00"
```

Running the example:
```
cd $CCPROOT/examples/kube/pgbasebackup/full
./run.sh
```

Test the restored database as follows:
```
psql -h restore -U postgres postgres
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
will be written out to the `/pgwal` mount point.

A full backup is required to do a PITR.  crunchy-backup currently
performs this role within the example, running a `pg_basebackup` on the database.
This is a requirement for PITR. After a backup is performed, code is added into
crunchy-postgres which will also check to see if you want to do a PITR.

There are three volume mounts used with the PITR example.

* `/recover` - When specified within a crunchy-postgres container, PITR is activated during container startup.
* `/backup` - This is used to find the base backup you want to recover from.
* `/pgwal` - This volume is used to write out new WAL files from the newly restored database container.

Some environment variables used to manipulate the point in time recovery logic:

* The `RECOVERY_TARGET_NAME` environment variable is used to tell the PITR logic what the name of the target is.
* `RECOVERY_TARGET_TIME` is also an optional environment variable that restores using a known time stamp.

If you don't specify either of these environment variables, then the PITR logic will assume you want to
restore using all the WAL files or essentially the last known recovery point.

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

{{% notice warning %}}
WAL segment files are written to the */tmp* directory. Leaving the example running
for a long time could fill up your /tmp directory.
{{% /notice %}}

To shutdown the instance and remove the container for each example, run the following:
```
./cleanup.sh
```

### Docker

Create a database container as follows:
```
cd $CCPROOT/examples/docker/pgbasebackup/pitr
./run-pitr.sh
```

Next, we will create a base backup of that database using this:
```
./run-backup-pitr.sh
```

After creating the base backup of the database, WAL segment files are created every 60 seconds
that contain any database changes. These segments are stored in the
`/tmp/pitr/pitr/pg_wal` directory.

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

Next, let's edit the restore script to use the base backup files
created in the step above.  You can view the backup path name
under the `/tmp/backups/pitr-backups/` directory. You will see
another directory inside of this path with a name similar to
`2018-03-21-21-03-29`.  Copy and paste that value into the
`run-restore-pitr.sh` script in the `BACKUP` environment variable.

After that, run the script.
```
vi ./run-restore-pitr.sh
./run-restore-pitr.sh
```

The WAL segments are read and applied when restoring from the database
backup.  At this point, you should be able to verify that the
database was restored to the point before creating the test table:
```
psql -h 127.0.0.1 -p 12001 -U postgres postgres -c 'table pitrtest'
```

This SQL command should show that the pitrtest table does not exist
at this recovery time. The output should be similar to:
```
ERROR: relation "pitrtest" does not exist
```

PostgreSQL allows you to pause the recovery process if the target name
or time is specified.  This pause would allow a DBA a chance to review
the recovery time/name and see if this is what they want or expect.  If so,
the DBA can run the following command to resume and complete the recovery:
```
psql -h 127.0.0.1 -p 12001 -U postgres postgres -c 'select pg_wal_replay_resume()'
```

Until you run the statement above, the database will be left in read-only
mode.

Next, run the script to restore the database
to the `afterchanges` restore point. Update the `RECOVERY_TARGET_NAME` to `afterchanges`:
```
vi ./run-restore-pitr.sh
./run-restore-pitr.sh
```

After this restore, you should be able to see the test table:
```
psql -h 127.0.0.1 -p 12001 -U postgres postgres -c 'table pitrtest'
psql -h 127.0.0.1 -p 12001 -U postgres postgres -c 'select pg_wal_replay_resume()'
```

Lastly, start a recovery using all of the WAL files. This will get the
restored database as current as possible. To do so, edit the script
to remove the `RECOVERY_TARGET_NAME` environment setting completely:
```
./run-restore-pitr.sh
sleep 30
psql -h 127.0.0.1 -p 12001 -U postgres postgres -c 'table pitrtest'
psql -h 127.0.0.1 -p 12001 -U postgres postgres -c 'create table foo (id int)'
```

At this point, you should be able to create new data in the restored database
and the test table should be present.  When you recover the entire
WAL history, resuming the recovery is not necessary to enable writes.

### Kubernetes and OpenShift

Start by running the example database container:
```
cd $CCPROOT/examples/kube/pgbasebackup/pitr
./run-pitr.sh
```

This step will create a database container, *pitr*.  This
container is configured to continuously write WAL segment files
to a mounted volume (`/pgwal`).

After you start the database, you will create a base backup
using this command:
```
./run-backup-pitr.sh
```

This will create a backup and write the backup files to a persistent
volume (`/pgbackup`).

Next, create some recovery targets within the database by running
the SQL commands against the *pitr* database as follows:
```
./run-sql.sh
```

This will create recovery targets named `beforechanges`, `afterchanges`, and
`nomorechanges`.  It will create a table, *pitrtest*, between
the `beforechanges` and `afterchanges` targets.  It will also run a SQL
`CHECKPOINT` to flush out the changes to WAL segments.

Next, now that we have a base backup and a set of WAL files containing
our database changes, we can shut down the *pitr* database
to simulate a database failure.  Do this by running the following:
```
${CCP_CLI} delete pod pitr
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


Then run the following to create the restored database container:
```
./run-restore-pitr.sh
```

After the database has restored, you should be able to perform
a test to see if the recovery worked as expected:
```
psql -h restore-pitr -U postgres postgres -c 'table pitrtest'
psql -h restore-pitr -U postgres postgres -c 'create table foo (id int)'
```

The output of these commands should show that the *pitrtest* table is not
present.  It should also show that you can not create a new table
because the database is paused in read-only mode.

To make the database resume as a writable database, run the following
SQL command:
```
select pg_wal_replay_resume();
```

It should then be possible to write to the database:
```
psql -h restore-pitr -U postgres postgres -c 'create table foo (id int)'
```

You can also test that if `afterchanges` is specified, that the
*pitrtest* table is present but that the database is still in recovery
mode.

Lastly, you can test a full recovery using *all* of the WAL files, if
you remove the `RECOVERY_TARGET_NAME` environment variable completely.

The storage portions of this example can all be found under `$CCP_STORAGE_PATH/$CCP_NAMESPACE-restore-pitr`.
