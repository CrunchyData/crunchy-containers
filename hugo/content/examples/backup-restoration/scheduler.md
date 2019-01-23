---
title: "Scheduler"
date:
draft: false
weight: 34
---

## Crunchy Scheduler

The Crunchy Scheduler container implements a cronlike microservice within a namespace
to automate backups of a PostgreSQL database.

Currently Crunchy Scheduler only supports two types of tasks:

* pgBackRest
* pgBaseBackup

This service watches Kubernetes for config maps with the label `crunchy-scheduler=true`.
If found the scheduler will parse the data found in the config map (json object) and
convert it to a scheduled task.  If the config map is removed, the scheduler will
delete the task.

See the following examples for creating config maps that Crunchy Scheduler can parse:

* link:https://github.com/CrunchyData/crunchy-containers/blob/master/examples/kube/scheduler/configs/schedule-backrest-diff.json[pgBackRest Diff Backup]
* link:https://github.com/CrunchyData/crunchy-containers/blob/master/examples/kube/scheduler/configs/schedule-backrest-full.json[pgBackRest Full Backup]
* link:https://github.com/CrunchyData/crunchy-containers/blob/master/examples/kube/scheduler/configs/schedule-pgbasebackup.json[pgBaseBackup Backup]

The Crunchy Scheduler requires a Service Account to create jobs (pgBaseBackup) and to
exec (pgBackRest).  See the link:https://github.com/CrunchyData/crunchy-containers/blob/scheduler/examples/kube/scheduler/scheduler-sa.json[scheduler example]
for the required permissions on this account.

{{% notice tip %}}
Crunchy Scheduler uses the `UTC` timezone for all schedules.
{{% /notice %}}

### pgBackRest Schedules

To configure Crunchy Scheduler to create pgBackRest backups the following is required:

* pgBackRest schedule definition requires a deployment name.  The PostgreSQL pod should be created by a deployment.

### pgBaseBackup Schedules

To configure Crunchy Scheduler to create pgBaseBackup scheduled backups, the following is required:

* The name of the secret that contains the username and password the Scheduler will use to
  configure the job template.  See link:https://github.com/CrunchyData/crunchy-containers/blob/scheduler/examples/kube/scheduler/primary/secret.json[the primary secret example].
  for the structure required by the Scheduler.
* The name of the PVC created for the backups.  This should be created by the user prior to scheduling the task.

{{% notice tip %}}
When using pgBaseBackup schedules, it may be required to apply specific `supplementalGroups` or an `fsGroup`
to the backup job created by the scheduler.  To apply a specific `securityContext` for your
storage provider, mount a `backup-template.json` to `/configs` on the scheduler pod.

For an example of applying a custom template, link:https://github.com/CrunchyData/crunchy-containers/blob/scheduler/examples/kube/scheduler[see the schedule example].
{{% /notice %}}

### Kubernetes and OpenShift

First, start the PostgreSQL example created for the Scheduler by running the following commands:

```
# Kubernetes
cd $CCPROOT/examples/kube/scheduler/primary
./run.sh
```

The pod created should show a ready status before proceeding.

Next, start the scheduler by running the following command:

```
# Kubernetes
cd $CCPROOT/examples/kube/scheduler
./run.sh
```

Once the scheduler is deployed, register the backup tasks by running the following command:

```
# Kubernetes
cd $CCPROOT/examples/kube/scheduler
./add-schedules.sh
```

The scheduled tasks will (these are just for fast results, not recommended for production):

* take a backup every minute using pgBaseBackup
* take a full pgBackRest backup every even minute
* take a diff pgBackRest backup every odd minute

View the logs for the `scheduler` pod until the tasks run:

```
${CCP_CLI?} logs scheduler -f
```

View the `pgBaseBackup` pods results after the backup completes:

```
${CCP_CLI?} logs <basebackup pod name>
```

View the `pgBackRest` backups via exec after the backup completes:

```
${CCP_CLI?} exec -ti <primary deployment pod name> -- pgbackrest info
```

Clean up the examples by running the following commands:

```
$CCPROOT/examples/kube/scheduler/primary/cleanup.sh
$CCPROOT/examples/kube/scheduler/cleanup.sh
```
