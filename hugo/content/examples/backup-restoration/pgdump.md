---
title: "pgDump"
date: {docdate}
draft: false
weight: 32
---

## pg_dump example

The script assumes you are going to backup the *primary* example and that container
is running.

This example assumes you have configured a storage filesystem as described
in the link:/installation/storage-configuration/[Storage Configuration] document.

A successful backup will perform pg_dump/pg_dumpall on the primary and store
the resulting files in the mounted volume under a directory named `<HOSTNAME>-backups`
as a sub-directory, then followed by a unique backup directory based upon a
date and timestamp - allowing any number of backups to be kept.

For more information on how to configure this container, please see the link:/container-specifications/[Container Specifications] document.

To shutdown the instance and remove the container for each example, run the following:
```
./cleanup.sh
```

### Docker

Run the backup with this command:
```
cd $CCPROOT/examples/docker/pgdump
./run.sh
```

### Kubernetes and OpenShift

Running the example:
```
cd $CCPROOT/examples/kube/pgdump
./run.sh
```

The Kubernetes Job type executes a pod and then the pod exits.  You can
view the Job status using this command:
```
${CCP_CLI} get job
```

The `pgdump.json` file within that directory specifies options that control the behavior of the pgdump job.
Examples of this include whether to run pg_dump vs pg_dumpall and advanced options for specific backup use cases.