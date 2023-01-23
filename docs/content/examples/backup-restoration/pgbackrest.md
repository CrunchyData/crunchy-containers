---
title: "pgBackRest"
date:
draft: false
weight: 30
---

# pgBackRest Examples

Written and maintained by David Steele, pgBackRest is a utility that provides backup and restore functionality for PostgreSQL databases.  pgBackRest is available for use within the Crunchy Container Suite, and can therefore be utilized to provide an effective backup and restore solution for any database clusters deployed using the crunchy-postgres or crunchy-postgres-gis containers.  The following section will provide an overview of how pgBackRest can be utilized within the Crunchy Container Suite, including examples for enabling and configuring pgBackRest, and then utilizing pgBackRest to backup and restore various PostgreSQL database clusters.  For more detailed information about pgBackRest, please visit the [official pgBackRest website](https://pgbackrest.org/).

## Configuration Overview

In order to enable pgBackRest within a crunchy-postgres or crunchy-postgres-gis container, environment variable `PGBACKREST` must be set to `true` during deployment of the container (`PGBACKREST=true`).  This will setup the proper pgBackRest configuration, ensure any required pgBackRest repositories and directories are created, and will create the proper pgBackRest stanza.

Please note that setting `PGBACKREST=true` is all that is needed to configure and enable pgBackRest within a crunchy-postgres or crunchy-postgres-gis container.  When enabled, default environment variables will be set for pgBackRest as follows, unless they are otherwise explicitly defined and provided during deployment of the container:

```bash
export PGBACKREST_STANZA="db"
export PGBACKREST_PG1_PATH="/pgdata/${PGDATA_DIR}"
export PGBACKREST_REPO1_PATH="/backrestrepo/${PGDATA_DIR}-backups"
export PGBACKREST_LOG_PATH="/tmp"
```

As shown above, a stanza named `db` is created by default, using the default values provided for both `PGBACKREST_PG1_PATH` and `PGBACKREST_REPO1_PATH`.  Variable `PGDATA_DIR` represents the name of the database cluster's data directory, which will either be the hostname of the container or the value specified for variable `PGDATA_PATH_OVERRIDE` during deployment of the container.  Please see the [crunchy-postgres](/container-specifications/crunchy-postgres) and/or [crunchy-postgres-gis](/container-specifications/crunchy-postgres-gis) container specifications for additional details.

While setting `PGBACKREST` to `true` provides a simple method for enabling pgBackRest within a crunchy-postgres or crunchy-postgres-gis container, pgBackRest is also fully configurable and customizable via the various environment variables supported by pgBackRest.  This applies to the crunchy-backrest-restore container as well, which is also configured using pgBackRest environment variables when performing database restores.  Therefore, during the deployment of any container containing pgBackRest (crunchy-postgres, crunchy-postgres-gis or crunchy-backrest-restore), environment variables should be utilized to configure and customize the pgBackRest utility as needed and ensure the desired backup and restore functionality is achieved.  For instance, the following environment variables could be specified upon deployment of the crunchy-backrest-restore container in order to perform delta restore to a specific point-in-time:

```bash
PGBACKREST_TYPE=time
PITR_TARGET="2019-10-27 16:53:05.590156+00"
PGBACKREST_DELTA=y
```

Database restores can be performed via the crunchy-backrest-restore container, which offers full pgBackRest restore capabilities, such as full, point-in-time and delta restores.  Further information and guidance for performing both backups and restores using the Crunchy Container Suite and pgBackRest will be provided in the examples below.

In addition to providing the backup and restoration capabilities discussed above, pgBackRest supports the capability to asynchronously push and get write ahead logs (WAL) to and from a WAL archive.  To enable asychronous WAL archiving within a crunchy-postgres or crunchy-postgres-gis container, pgBackRest environment variable `PGBACKREST_ARCHIVE_ASYNC` must be set to `"y"` during deployment (`PGBACKREST_ARCHIVE_ASYNC=y`).  This will automatically enable WAL archiving within the container if not otherwise explicitly enabled, set the proper `pgbackrest archive` command within the `postgresql.conf` configuration file, and ensure the proper spool path has been created.  

If a spool path is not explicitly provided using environment variable `PGBACKREST_SPOOL_PATH`, this variable will default as follows:

```bash
# Environment variable XLOGDIR="true"
export PGBACKREST_SPOOL_PATH="/pgdata/${PGDATA_DIR}"

# Environment variable XLOGDIR!=true
export PGBACKREST_SPOOL_PATH="/pgwal/${PGDATA_DIR}/spool"
```

As shown above, the default location of the spool path depends on whether or not `XLOGDIR=true`, with `XLOGDIR` enabling the storage of WAL to the `/pgwal` volume within the container.  Being that pgBackRest recommends selecting a spool path that is as close to the WAL as possible, this provides a sensible default for the spool directory.  However, `PGBACKREST_SPOOL_PATH` can also be explicitly configured during deployment to any path desired.  And once again, `PGDATA_DIR` represents either the hostname of the container or the value specified for variable `PGDATA_PATH_OVERRIDE`.

The examples below will demonstrate the pgBackRest backup, restore and asynchronous archiving capabilities described above, while also providing insight into the proper configuration of pgBackBackrest within the Crunchy Container Suite.  For more information on these pgBackRest capabilities and associated configuration, please consult the [official pgBackRest documentation](https://pgbackrest.org/).  

## Kubernetes and OpenShift

***The pgBackRest examples for Kubernetes and OpenShift can be configured to use the PostGIS images by setting the following environment variable when running the examples:***
```bash
export CCP_PG_IMAGE='-gis'
```

### Backup
In order to demonstrate the backup and restore capabilities provided by pgBackRest, it is first necessary to deploy a PostgreSQL database, and then create a full backup of that database.  This example will therefore deploy a crunchy-postgres or crunchy-postgres-gis container containing a PostgreSQL database, which will then be backed up manually by executing a `pgbackrest backup` command.  ***Please note that this example serves as a prequisite for the restore examples that follow, and therefore must be run prior to running those examples.***

Start the example as follows:
```
cd $CCPROOT/examples/kube/backrest/backup
./run.sh
```

This will create the following in your Kubernetes environment:

* A deployment named **backrest** containing a PostgreSQL database with pgBackRest configured
* A service named **backrest** for the PostgreSQL database
* A PV and PVC for the PGDATA directory
* A PV and PVC for the pgBackRest backups and archives directories

Once the **backrest** deployment is running, use the `pgbackrest info` command to verify that pgbackrest has been properly configured and WAL archiving is working properly:

```bash
$ ${CCP_CLI} exec <backrest pod name> -- pgbackrest info \
  --stanza=db \
  --repo1-path=/backrestrepo/backrest-backups

pg_pid=126
stanza: db
    status: error (no valid backups)
    cipher: none

    db (current)
        wal archive min/max (11-1): 000000010000000000000001 / 000000010000000000000003
```

An output similar to the above indicates that pgBackRest was properly configured upon deployment of the pod, the **db** stanza has been created, and WAL archiving is working properly.  The error next to **status** is expected being that a backup has not yet been generated.

Now that we have verified that pgBackRest is properly configured and enabled, a backup of the database can be generated.  Being that this is the first backup of the database, we will take create a **full** backup:

```bash
$ ${CCP_CLI} exec <backrest pod name> -- pgbackrest backup \
  --stanza=db \
  --pg1-path=/pgdata/backrest \
  --repo1-path=/backrestrepo/backrest-backups \
  --log-path=/tmp \
  --type=full

pg_pid=138
WARN: option repo1-retention-full is not set, the repository may run out of space
      HINT: to retain full backups indefinitely (without warning), set option 'repo1-retention-full' to the maximum.
```
The warning displayed is expected, since backup retention has not been configured for this example.  Assuming no errors are displayed, a full backup has now been successfully created.

### Restore
pgBackRest provides numerous methods and strategies for restoring a PostgreSQL database.  The following section will demonstrate  three forms of database restores that can be  accomplished when using pgBackRest with the Crunchy Container Suite:

* **Full:** restore all database files into an empty PGDATA directory
* **point-in-time Recovery (PITR):** restore a database to a specific point-in-time using an empty PGDATA directory
* **Delta:** restore a database to a specific point-in-time using an existing PGDATA directory

#### Full
This example will demonstrate a full database restore to an empty PGDATA directory.  ***Please ensure the Backup example is currently running and a full backup has been generated prior to running this example.***

Prior to running the full restore, we will first make a change to the currently running database, which will we will then verify still exists following the restore.  Create a simple table in the database as follows:

```bash
$ ${CCP_CLI} exec <backrest pod name> -- psql -c "create table backrest_test_table (id int)"
CREATE TABLE
```

Now verify that the new table exists:

```bash
$ ${CCP_CLI} exec <backrest pod name> -- psql -c "table backrest_test_table"
 id
----
(0 rows)
```

With the table in place, we can now start the full restore as follows:

```bash
cd $CCPROOT/examples/kube/backrest/full
./run.sh
```

This will create the following in your Kubernetes environment:

* A Kubernetes job named **backrest-full-restore-job** which will perform the restore using the crunchy-backrest-restore container
* A PV and PVC for the new PGDATA directory that will contain the restored database.  The directory will initially be empty, as required  pgBackRest when performing a full restore, and will then contain the restored database upon completion of the restore.

Please note that a brand new PV and PVC are created when running the restore to clearly indicate that the database will be restored into an entirely new (i.e. empty) volume as required by pgBackRest.  The names of the new PV and PVC are as follows:

* **PV:** ${CCP_NAMESPACE}-br-new-pgdata
* **PVC:** br-new-pgdata

You can verify that the restore has completed successfully by verifying that the Kubernetes job has completed successfully:

```bash
$ ${CCP_CLI} get jobs
NAME                        COMPLETIONS   DURATION   AGE
backrest-full-restore-job   1/1           15s        58s
```

Once the job is complete, the post restore script can then be run, which will create a new deployment named **backrest-full-restored** containing the restored database:

```bash
cd $CCPROOT/examples/kube/backrest/full
./post-restore.sh
```

Finally, once the **backrest-full-restored** deployment is running we can verify that the restore was successful by verifying that the table created prior to the restore still exists:
```bash
$ ${CCP_CLI} exec <backrest restored pod name> -- psql -c "table backrest_test_table"
 id
----
(0 rows)
```

Please note that the default behavior of pgBackRest is to recover to the end of the WAL archive stream, which is why the full restore contained all changes made since the initial full backup was taken, including the creation of table **backrest_test_table**.  pgBackRest therefore played the entire WAL archive stream for all changes that occurred up until the restore.

_As a reminder, please remember to run the cleanup script for the **Backup** example after running the cleanup script for this example._

#### PITR
As demonstrated with the full restore above, the default behavior of pgBackRest is to recover to the end of the WAL archive stream. However, pgBackRest also provides the ability to recover to a specific point-in-time utilizing the WAL archives created since the last backup. This example will demonstrate how pgBackRest can be utilized to perform a point-in-time recovery (PITR) and therefore recover the database to specific point-in-time specified by the user.  ***Please ensure that the Backup example is currently running and a full backup has been generated prior to running this example.***

Prior to running the PITR restore, we will first verify the current state of the database, after which we will then make a change to the database.  This will allow us to verify that the PITR is successful by providing a method of verifying that the database has been restored to its current state following the restore.

To verify the current state of the database, we will first verify that a table called **backrest_test_table** does not  exist in the database.

```bash
$ ${CCP_CLI} exec <backrest pod name> -- psql -c " table backrest_test_table"
ERROR:  relation "backrest_test_table" does not exist
LINE 1:  table backrest_test_table
               ^
command terminated with exit code 1
```

Next, capture the current timestamp, which will be used later in the example when performing the restore:

```bash
$ ${CCP_CLI} exec <backrest pod name> -- psql -c "select current_timestamp"
       current_timestamp
-------------------------------
 2019-10-27 16:53:05.590156+00
(1 row)
```

Now create table **backrest_test_table**:

```bash
$ ${CCP_CLI} exec <backrest pod name> -- psql -c "create table backrest_test_table (id int)"
CREATE TABLE
```

Then verify that the new table exists:

```bash
$ ${CCP_CLI} exec <backrest pod name> -- psql -c "table backrest_test_table"
 id
----
(0 rows)
```

With the table in place, we can now start the PITR.  However, the timestamp captured above must also be provided in order to instruct pgBackRest to recover to that specific point-in-time.  This is done using the `CCP_BACKREST_TIMESTAMP` variable, which allows us to then start the PITR as follows (replace the timestamp in the command below with the timestamp you captured above):

```bash
cd $CCPROOT/examples/kube/backrest/pitr
CCP_BACKREST_TIMESTAMP="2019-10-27 16:53:05.590156+00" ./run.sh
```

This will create the following in your Kubernetes environment:
- A Kubernetes job named **backrest-pitr-restore-job** which will perform the restore using the crunchy-backrest-restore container

Additionally, when this example is run, the following pgBackRest environment variables are provided to the crunchy-backrest-restore container in order to initiate PITR restore to the point-in-time specified by the timestamp (in additional to any other pgBackRest variables required by the Crunchy Container Suite and pgBackRest):

```bash
PGBACKREST_TYPE=time
PITR_TARGET="${CCP_BACKREST_TIMESTAMP}"
```

As can be seen above, the timestamp provided for `CCP_BACKREST_TIMESTAMP` is used to populate variable `PITR_TARGET`, and therefore specify the point-in-time to restore the database to, while `PGBACKREST_TYPE` is set to `time` to indicate that a PITR should be performed.

Please note that the following pgBackRest environment variable is also set when performing the PITR, which results in a restore to a new/empty directory within an existing PV:

```bash
PGBACKREST_PG1_PATH=/pgdata/backrest-pitr-restored
```

You can verify that the restore has completed successfully by verifying that the Kubernetes job has completed successfully:

```bash
$ ${CCP_CLI} get jobs
NAME                        COMPLETIONS   DURATION   AGE
backrest-pitr-restore-job   1/1           15s        58s
```

Once the job is complete, the post restore script can then be run, which will create a new deployment named **backrest-pitr-restored** containing the restored database:

```bash
cd $CCPROOT/examples/kube/backrest/pitr
./post-restore.sh
```

Finally, once the **backrest-pitr-restored** deployment is running we can verify that the restore was successful by verifying that the table created prior to the restore no longer exists:

```bash
$ ${CCP_CLI} exec <backrest restored pod name> -- psql -c " table backrest_test_table"
ERROR:  relation "backrest_test_table" does not exist
LINE 1:  table backrest_test_table
               ^
command terminated with exit code 1
```

_As a reminder, please remember to run the cleanup script for the **Backup** example after running the cleanup script for this example._

#### Delta
By default, pgBackRest requires a clean/empty directory in order to perform a restore.  However, pgBackRest also provides an another option when performing the restore in the form of the **delta** option, which allows the restore to be run against an existing PGDATA directory.  With the delta option enabled, pgBackRest will use checksums to determine which files in the directory can be preserved, and which need to be restored (please note that pgBackRest will also remove any files that are not present in the backup).  This example will again demonstrate a point-in-time recovery (PITR), only this time the restore will occur within the existing PGDATA directory by specifying the **delta** option during the restore. ***Please ensure that the Backup example is currently running and a full backup has been generated prior to running this example.***

Prior to running the delta restore, we will first verify the current state of the database, and we will then make a change to the database.  This will allow us to verify that the delta restore is successful by providing a method of verifying that the database has been restored to its current state following the restore.

To verify the current state of the database, we will first verify that a table called **backrest_test_table** does not exist in the database.

```bash
$ ${CCP_CLI} exec <backrest pod name> -- psql -c " table backrest_test_table"
ERROR:  relation "backrest_test_table" does not exist
LINE 1:  table backrest_test_table
               ^
command terminated with exit code 1
```

Next, capture the current timestamp, which will be used later in the example when performing the restore:

```bash
$ ${CCP_CLI} exec <backrest pod name> -- psql -c "select current_timestamp"
       current_timestamp
-------------------------------
 2019-10-27 16:53:05.590156+00
(1 row)
```

Now create table **backrest_test_table**:

```bash
$ ${CCP_CLI} exec <backrest pod name> -- psql -c "create table backrest_test_table (id int)"
CREATE TABLE
```

Then verify that the new table exists:

```bash
$ ${CCP_CLI} exec <backrest pod name> -- psql -c "table backrest_test_table"
 id
----
(0 rows)
```

With the table in place, we can now start the delta restore.  When running the restore example the timestamp captured above must also be provided in order to instruct pgBackRest to recover to that specific point-in-time.  This is done using the `CCP_BACKREST_TIMESTAMP` variable, which allows us to then start the delta restore as follows (replace the timestamp in the command below with the timestamp you captured above):

```bash
cd $CCPROOT/examples/kube/backrest/delta
CCP_BACKREST_TIMESTAMP="2019-10-27 16:53:05.590156+00" ./run.sh
```

This will create the following in your Kubernetes environment:
- A Kubernetes job named **backrest-delta-restore-job** which will perform the restore using the crunchy-backrest-restore container

Additionally, when this example is run, the following pgBackRest environment variables are provided to the crunchy-backrest-restore container in order to initiate a delta restore to the point-in-time specified by the timestamp (in additional to any other pgBackRest variables required by the Crunchy Container Suite and pgBackRest):

```bash
PGBACKREST_TYPE=time
PITR_TARGET="${CCP_BACKREST_TIMESTAMP}"
PGBACKREST_DELTA=y
```

As can be seen above, the timestamp provided for `CCP_BACKREST_TIMESTAMP` is used to populate variable `PITR_TARGET`, and therefore specify the point-in-time to restore to, while `PGBACKREST_TYPE` is set to `time` to indicate that a PITR should be performed. `PGBACKREST_DELTA` is set to `y` to indicate that the delta option should be utilized when performing the restore.

It's also worth noting that the following pgBackRest environment variable is also set when performing the delta restore, which results in a restore within the existing PGDATA directory utilized by the database deployed when running the **Backup** example:

```bash
PGBACKREST_PG1_PATH=/pgdata/backrest
```

You can then verify that the restore has completed successfully by verifying that the Kubernetes job has completed successfully:

```bash
$ ${CCP_CLI} get jobs
NAME                        COMPLETIONS   DURATION   AGE
backrest-delta-restore-job   1/1           15s        58s
```

Once the job is complete, the post restore script can then be run, which will create a new deployment named **backrest-delta-restored** containing the restored database:

```bash
cd $CCPROOT/examples/kube/backrest/delta
./post-restore.sh
```

Finally, once the **backrest-delta-restored** deployment is running we can verify that the restore was successful by verifying that the table created prior to the restore no longer exists:

```bash
$ ${CCP_CLI} exec <backrest restored pod name> -- psql -c " table backrest_test_table"
ERROR:  relation "backrest_test_table" does not exist
LINE 1:  table backrest_test_table
               ^
command terminated with exit code 1
```

_As a reminder, please remember to run the cleanup script for the **Backup** example after running the cleanup script for this example._

### Async Archiving
pgBackRest supports the capability to asynchronously push and get write ahead logs (WAL) to and from a WAL archive. Asynchronous archiving can improve performance by parallelizing operations, while also reducing the number of connections to remote storage. For more information on async archiving and its benefits, please see the [official pgBackRest documentation](https://pgbackrest.org/).  This example will demonstrate how asynchronous archiving can be enabled within a crunchy-postgres or crunchy-postgres-gis container, while then also demonstrating the creation of a differential backup.

Start the example as follows:
```
cd $CCPROOT/examples/kube/backrest/async-archiving
./run.sh
```

This will create the following in your Kubernetes environment:
- A deployment named **backrest-async-archive** containing a PostgreSQL database with pgBackRest configured
- A service named **backrest-async-archive** for the PostgreSQL database
- A PV and PVC for the PGDATA directory
- A PV and PVC for the pgBackRest backups and archives directories

Additionally, the following variable will be set during deployment of the pod in order to enable asynchronous archiving:

```bash
PGBACKREST_ARCHIVE_ASYNC=y
```

This will also result in the creation of the required spool path, which we can see by listing the contents of the `/pgdata` directory in the backrest-async-archive deployment:

```bash
$ ${CCP_CLI} exec <backrest async archive pod name> -- ls /pgdata
backrest-async-archive
backrest-async-archive-backups
backrest-async-archive-spool
```

Once the database is up an running, a full backup can be taken:

```bash
${CCP_CLI} exec <backrest async archive pod name> -- pgbackrest backup \
  --stanza=db \
  --pg1-path=/pgdata/backrest-async-archive \
  --repo1-path=/backrestrepo/backrest-async-archive-backups \
  --log-path=/tmp \
  --type=full
```

And once a full backup has been taken, other types of backups can also be taken using pgBackRest, such as a differential backup:

```bash
${CCP_CLI} exec <backrest async archive pod name> -- pgbackrest backup \
  --stanza=db \
  --pg1-path=/pgdata/backrest-async-archive \
  --repo1-path=/backrestrepo/backrest-async-archive-backups \
  --log-path=/tmp \
  --type=diff
```

The following command can then be run to verify that both backups were created successfully:

```bash
${CCP_CLI} exec <backrest async archive pod name> -- pgbackrest info \
  --stanza=db \
  --repo1-path=/backrestrepo/backrest-async-archive-backups
```

## Docker

### Backup
In order to demonstrate the backup and restore capabilities provided by pgBackRest, it is first necessary to deploy a PostgreSQL database, and then create a full backup of that database.  This example will therefore deploy a crunchy-postgres or crunchy-postgres-gis container containing a PostgreSQL database, which will then be backed up manually by executing a `pgbackrest backup` command.  ***Please note that this example serves as a prequisite for the restore examples that follow, and therefore must be run prior to running those examples.***

Start the example as follows:
```
cd $CCPROOT/examples/docker/backrest/backup
./run.sh
```

This will create the following in your Docker environment:
- A container named **backrest** containing a PostgreSQL database with pgBackRest configured
- A volume for the PGDATA directory
- A volume for the pgBackRest backups and archives directories

Once the **backrest** container is running, use the `pgbackrest info` command to verify that pgbackrest has been properly configured and WAL archiving is working properly:
```bash
$ docker exec backrest pgbackrest info \
  --stanza=db \
  --repo1-path=/backrestrepo/backrest-backups

pg_pid=126
stanza: db
    status: error (no valid backups)
    cipher: none

    db (current)
        wal archive min/max (11-1): 000000010000000000000001 / 000000010000000000000003
```
An output similar to the above indicates that pgBackRest was properly configured upon deployment of the container, the **db** stanza has been created, and WAL archiving is working properly.  The error next to **status** is expected being that a backup has not yet been generated.

Now that we have verified that pgBackRest is properly configured and enabled, a backup of the database can be generated.  Being that this is the first backup of the database, we will take create a **full** backup:
```bash
$ docker exec backrest pgbackrest backup \
  --stanza=db \
  --pg1-path=/pgdata/backrest \
  --repo1-path=/backrestrepo/backrest-backups \
  --log-path=/tmp \
  --type=full

pg_pid=138
WARN: option repo1-retention-full is not set, the repository may run out of space
      HINT: to retain full backups indefinitely (without warning), set option 'repo1-retention-full' to the maximum.
```
The warning displayed is expected, since backup retention has not been configured for this example.  Assuming no errors are displayed, a full backup has now been successfully created.

### Restore
pgBackRest provides numerous methods and strategies for restoring a PostgreSQL database.  The following section will demonstrate  three forms of database restores that can be  accomplished when using pgBackRest with the Crunchy Container Suite:
- **Full:** restore all database files into an empty PGDATA directory
- **point-in-time Recovery (PITR):** restore a database to a specific point-in-time using an empty PGDATA directory
- **Delta:** restore a database to a specific point-in-time using an existing PGDATA directory

#### Full
This example will demonstrate a full database restore to an empty PGDATA directory.  ***Please ensure the Backup example is currently running and a full backup has been generated prior to running this example.***

Prior to running the full restore, we will first make a change to the currently running database, which will we will then verify still exists following the restore.  Create a simple table in the database as follows:
```bash
$ docker exec backrest psql -c "create table backrest_test_table (id int)"
CREATE TABLE
```
Now verify that the new table exists:
```bash
$ docker exec backrest psql -c "table backrest_test_table"
 id
----
(0 rows)
```
With the table in place, we can now start the full restore as follows:
```bash
cd $CCPROOT/examples/docker/backrest/full
./run.sh
```

This will create the following in your Docker environment:
- A container named **backrest-full-restore** which will perform the restore using the crunchy-backrest-restore container
- A volume for the new PGDATA directory that will contain the restored database.  The directory will initially be empty, as required  pgBackRest when performing a full restore, and will then contain the restored database upon completion of the restore.

Please note that a brand new PV and PVC are created when running the restore to clearly indicate that the database will be restored into an entirely new (i.e. empty) volume as required by pgBackRest.  The names of the new PV and PVC are as follows:
- **PV:** ${CCP_NAMESPACE}-br-new-pgdata
- **PVC:** br-new-pgdata

You can verify that the restore has completed successfully by verifying that the container has finished running and has exited without errors:
```bash
docker ps -a
```

Once the container has finished running, the post restore script can then be run, which will create a new container named **backrest-full-restored** containing the restored database:
```bash
cd $CCPROOT/examples/docker/backrest/full
./post-restore.sh
```

Finally, once the **backrest-full-restored** container is running we can verify that the restore was successful by verifying that the table created prior to the restore still exists:
```bash
$ docker exec backrest-full-restored psql -c "table backrest_test_table"
 id
----
(0 rows)
```

Please note that the default behavior of pgBackRest is to recover to the end of the WAL archive stream, which is why the full restore contained all changes made since the initial full backup was taken, including the creation of table **backrest_test_table**.  pgBackRest therefore played the entire WAL archive stream for all changes that occurred up until the restore.

_As a reminder, please remember to run the cleanup script for the **Backup** example after running the cleanup script for this example._

#### PITR
As demonstrated with the full restore above, the default behavior of pgBackRest is to recover to the end of the WAL archive stream. However, pgBackRest also provides the ability to recover to a specific point-in-time utilizing the WAL archives created since the last backup. This example will demonstrate how pgBackRest can be utilized to perform a point-in-time recovery (PITR) and therefore recover the database to specific point-in-time specified by the user.  ***Please ensure that the Backup example is currently running and a full backup has been generated prior to running this example.***

Prior to running the PITR restore, we will first verify the current state of the database, after which we will then make a change to the database.  This will allow us to verify that the PITR is successful by providing a method of verifying that the database has been restored to its current state following the restore.

To verify the current state of the database, we will first verify that a table called **backrest_test_table** does not  exist in the database.
```bash
$ docker exec backrest psql -c "table backrest_test_table"
ERROR:  relation "backrest_test_table" does not exist
LINE 1:  table backrest_test_table
               ^
command terminated with exit code 1
```

Next, capture the current timestamp, which will be used later in the example when performing the restore:
```bash
$ docker exec backrest psql -c "select current_timestamp"
       current_timestamp
-------------------------------
 2019-10-27 16:53:05.590156+00
(1 row)
```

Now create table **backrest_test_table**:
```bash
$ docker exec backrest psql -c "create table backrest_test_table (id int)"
CREATE TABLE
```
Then verify that the new table exists:
```bash
$ docker exec backrest psql -c "table backrest_test_table"
 id
----
(0 rows)
```
With the table in place, we can now start the PITR.  However, the timestamp captured above must also be provided in order to instruct pgBackRest to recover to that specific point-in-time.  This is done using the `CCP_BACKREST_TIMESTAMP` variable, which allows us to then start the PITR as follows (replace the timestamp in the command below with the timestamp you captured above):
```bash
cd $CCPROOT/examples/docker/backrest/pitr
CCP_BACKREST_TIMESTAMP="2019-10-27 16:53:05.590156+00" ./run.sh
```

This will create the following in your Docker environment:
- A container named **backrest-pitr-restore** which will perform the restore using the crunchy-backrest-restore container

Additionally, when this example is run, the following pgBackRest environment variables are provided to the crunchy-backrest-restore container in order to initiate PITR to the point-in-time specified by the timestamp (in additional to any other pgBackRest variables required by the Crunchy Container Suite and pgBackRest):
```bash
PGBACKREST_TYPE=time
PITR_TARGET="${CCP_BACKREST_TIMESTAMP}"
```
As can be seen above, the timestamp provided for `CCP_BACKREST_TIMESTAMP` is used to populate variable `PITR_TARGET`, and therefore specify the point-in-time to restore the database to, while `PGBACKREST_TYPE` is set to `time` to indicate that a PITR should be performed.

Please note that the following pgBackRest environment variable is also set when performing the PITR, which results in a restore to a new/empty directory within an existing PV:
```bash
PGBACKREST_PG1_PATH=/pgdata/backrest-pitr-restored
```

You can verify that the restore has completed successfully by verifying that the container has finished running and has exited without errors:
```bash
docker ps -a
```

Once the container has finished running, the post restore script can then be run, which will create a new container named **backrest-pitr-restored** containing the restored database:
```bash
cd $CCPROOT/examples/docker/backrest/pitr
./post-restore.sh
```

Finally, once the **backrest-pitr-restored** container is running we can verify that the restore was successful by verifying that the table created prior to the restore no longer exists:
```bash
$ docker exec backrest-pitr-restored psql -c "table backrest_test_table"
ERROR:  relation "backrest_test_table" does not exist
LINE 1:  table backrest_test_table
               ^
command terminated with exit code 1
```

_As a reminder, please remember to run the cleanup script for the **Backup** example after running the cleanup script for this example._

#### Delta
By default, pgBackRest requires a clean/empty directory in order to perform a restore.  However, pgBackRest also provides an another option when performing the restore in the form of the **delta** option, which allows the restore to be run against an existing PGDATA directory.  With the delta option enabled, pgBackRest will use checksums to determine which files in the directory can be preserved, and which need to be restored (please note that pgBackRest will also remove any files that are not present in the backup).  This example will again demonstrate a point-in-time recovery (PITR), only this time the restore will occur within the existing PGDATA directory by specifying the **delta** option during the restore. ***Please ensure that the Backup example is currently running and a full backup has been generated prior to running this example.***

Prior to running the delta restore, we will first verify the current state of the database, and we will then make a change to the database.  This will allow us to verify that the delta restore is successful by providing a method of verifying that the database has been restored to its current state following the restore.

To verify the current state of the database, we will first verify that a table called **backrest_test_table** does not  exist in the database.
```bash
$ docker exec backrest psql -c "table backrest_test_table"
ERROR:  relation "backrest_test_table" does not exist
LINE 1:  table backrest_test_table
               ^
command terminated with exit code 1
```

Next, capture the current timestamp, which will be used later in the example when performing the restore:
```bash
$ docker exec backrest psql -c "select current_timestamp"
       current_timestamp
-------------------------------
 2019-10-27 16:53:05.590156+00
(1 row)
```

Now create table **backrest_test_table**:
```bash
$ docker exec backrest psql -c "create table backrest_test_table (id int)"
CREATE TABLE
```
Then verify that the new table exists:
```bash
$ docker exec backrest psql -c "table backrest_test_table"
 id
----
(0 rows)
```

With the table in place, we can now start the delta restore.  When running the restore example the timestamp captured above must also be provided in order to instruct pgBackRest to recover to that specific point-in-time.  This is done using the `CCP_BACKREST_TIMESTAMP` variable, which allows us to then start the delta restore as follows (replace the timestamp in the command below with the timestamp you captured above):
```bash
cd $CCPROOT/examples/docker/backrest/delta
CCP_BACKREST_TIMESTAMP="2019-10-27 16:53:05.590156+00" ./run.sh
```

This will create the following in your Docker environment:
- A container named **backrest-delta-restore** which will perform the restore using the crunchy-backrest-restore container

Additionally, when this example is run, the following pgBackRest environment variables are provided to the crunchy-backrest-restore container in order to initiate a delta restore to the point-in-time specified by the timestamp (in additional to any other pgBackRest variables required by the Crunchy Container Suite and pgBackRest):
```bash
PGBACKREST_TYPE=time
PITR_TARGET="${CCP_BACKREST_TIMESTAMP}"
PGBACKREST_DELTA=y
```
As can be seen above, the timestamp provided for `CCP_BACKREST_TIMESTAMP` is used to populate variable `PITR_TARGET`, and therefore specify the point-in-time to restore to, while `PGBACKREST_TYPE` is set to `time` to indicate that a PITR should be performed. `PGBACKREST_DELTA` is set to `y` to indicate that the delta option should be utilized when performing the restore.

It's also worth noting that the following pgBackRest environment variable is also set when performing the delta restore, which results in a restore within the existing PGDATA directory utilized by the database deployed when running the **Backup** example:
```bash
PGBACKREST_PG1_PATH=/pgdata/backrest
```

You can verify that the restore has completed successfully by verifying that the container has finished running and has exited without errors:
```bash
docker ps -a
```

Once the container has finished running, the post restore script can then be run, which will create a new container named **backrest-delta-restored** containing the restored database:
```bash
cd $CCPROOT/examples/docker/backrest/delta
./post-restore.sh
```

Finally, once the **backrest-delta-restored** container is running we can verify that the restore was successful by verifying that the table created prior to the restore no longer exists:
```bash
$ docker exec backrest-delta-restored psql -c "table backrest_test_table"
ERROR:  relation "backrest_test_table" does not exist
LINE 1:  table backrest_test_table
               ^
command terminated with exit code 1
```

_As a reminder, please remember to run the cleanup script for the **Backup** example after running the cleanup script for this example._

### Async Archiving
pgBackRest supports the capability to asynchronously push and get write ahead logs (WAL) to and from a WAL archive. Asynchronous archiving can improve performance by parallelizing operations, while also reducing the number of connections to remote storage. For more information on async archiving and its benefits, please see the [official pgBackRest documentation](https://pgbackrest.org/).  This example will demonstrate how asynchronous archiving can be enabled within a crunchy-postgres or crunchy-postgres-gis container, while then also demonstrating the creation of a differential backup.

Start the example as follows:
```
cd $CCPROOT/examples/docker/backrest/async-archive
./run.sh
```

This will create the following in your Docker environment:

* A container named **backrest-async-archive** containing a PostgreSQL database with pgBackRest configured
* A volume for the PGDATA directory
* A volume for the pgBackRest backups and archives directories

Additionally, the following variable will be set during deployment of the container in order to enable asynchronous archiving:
```bash
PGBACKREST_ARCHIVE_ASYNC=y
```

This will also result in the creation of the required spool path, which we can see by listing the contents of the `/pgdata` directory in the backrest-async-archive container:
```bash
$ docker exec backrest-async-archive ls /pgdata
backrest-async-archive
backrest-async-archive-backups
backrest-async-archive-spool
```

Once the database is up an running, a full backup can be taken:
```bash
docker exec backrest-async-archive pgbackrest backup \
  --stanza=db \
  --pg1-path=/pgdata/backrest-async-archive \
  --repo1-path=/backrestrepo/backrest-async-archive-backups \
  --log-path=/tmp \
  --type=full
```

And once a full backup has been taken, other types of backups can also be taken using pgBackRest, such as a differential backup:
```bash
docker exec backrest-async-archive pgbackrest backup \
  --stanza=db \
  --pg1-path=/pgdata/backrest-async-archive \
  --repo1-path=/backrestrepo/backrest-async-archive-backups \
  --log-path=/tmp \
  --type=diff
```

The following command can then be run to verify that both backups were created successfully:
```bash
docker exec backrest-async-archive pgbackrest info \
  --stanza=db \
  --repo1-path=/backrestrepo/backrest-async-archive-backups
```
