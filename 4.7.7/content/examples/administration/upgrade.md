---
title: "Upgrade"
date:
draft: false
weight: 81
---

## Major Upgrade

{{% notice tip %}}
This example assumes you have run *primary* using a PostgreSQL 12 or 13 image
such as `ubi8-{{< param postgresVersion13 >}}-{{< param containersVersion >}}` prior to running this upgrade.
{{% /notice %}}

The upgrade container will let you perform a `pg_upgrade` from a PostgreSQL version 9.5, 9.6, 10, 11, 12, or 13 database to the available any of the higher versions of PostgreSQL versions that are currently support which are 9.6, 10, 11, 12, and 13. It does not do multi-version upgrades so you will need to for example do a 10 to 11 and then a 11 to 12 to get to version 12.

Prior to running this example, make sure your `CCP_IMAGE_TAG`
environment variable is using the next major version of PostgreSQL that you
want to upgrade to. For example, if you're upgrading from 12 to 13, make
sure the variable references a PostgreSQL 13 image such as `ubi8-{{< param postgresVersion13 >}}-{{< param containersVersion >}}`.

This will create the following in your Kubernetes environment:

 * a Kubernetes Job running the *crunchy-upgrade* container
 * a new data directory name *upgrade* found in the *pgnewdata* PVC

{{% notice tip %}}
Data checksums on the Crunchy PostgreSQL container were enabled by default in version 2.1.0.
When trying to upgrade, it's required that both the old database and the new database
have the same data checksums setting.  Prior to upgrade, check if `data_checksums`
were enabled on the database by running the following SQL: `SHOW data_checksums`
{{% /notice %}}

## Kubernetes and OpenShift

{{% notice tip %}}
Before running the example, ensure you edit `upgrade.json` and update the `OLD_VERSION`
and `NEW_VERSION` parameters to the major release version relevant to your situation.
{{% /notice %}}

First, delete the existing primary deployment:
```
${CCP_CLI} delete deployment primary
```
Then start the upgrade as follows:

```
cd $CCPROOT/examples/kube/upgrade
./run.sh
```

If successful, the Job will end with a **successful** status. Verify
the results of the Job by examining the Job's pod log:
```
${CCP_CLI} get pod -l job-name=upgrade
${CCP_CLI} logs -l job-name=upgrade
```

You can verify the upgraded database by running the `post-upgrade.sh` script in the
`examples/kube/upgrade` directory.  This will create a PostgreSQL pod that mounts the
upgraded volume.
