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
