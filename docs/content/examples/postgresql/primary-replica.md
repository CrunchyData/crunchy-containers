---
title: "Primary and Streaming Replica Containers"
date:
draft: false
weight: 4
---

## Replication

This example starts a primary and a replica pod containing a PostgreSQL database.

The container creates a default database called *userdb*, a default user called
*testuser* and a default password of *password*.

For the Docker environment, the script additionally creates:

 * A docker volume using the local driver for the primary
 * A docker volume using the local driver for the replica
 * A container named *primary* binding to port 12007
 * A container named *replica* binding to port 12008
 * A mapping of the PostgreSQL port 5432 within the container to the localhost port 12000
 * The database using predefined environment variables

And specifically for the Kubernetes and OpenShift environments:

 * emptyDir volumes for persistence
 * A pod named *pr-primary*
 * A pod named *pr-replica*
 * A pod named *pr-replica-2*
 * A service named *pr-primary*
 * A service named *pr-replica*
 * The database using predefined environment variables

To shutdown the instance and remove the container for each example, run the following:
```
./cleanup.sh
```

### Docker

To create the example and run the container:
```
cd $CCPROOT/examples/docker/primary-replica
./run.sh
```

Connect from your local host as follows:
```
psql -h localhost -p 12007 -U testuser -W userdb
psql -h localhost -p 12008 -U testuser -W userdb
```

### Kubernetes and OpenShift

Run the following command to deploy a primary and replica database cluster:

```
cd $CCPROOT/examples/kube/primary-replica
./run.sh
```

It takes about a minute for the replica to begin replicating with the
primary.  To test out replication, see if replication is underway
with this command:

```
${CCP_CLI?} exec -ti pr-primary -- psql -d postgres -c 'table pg_stat_replication'
```

If you see a line returned from that query it means the primary is replicating
to the replica.  Try creating some data on the primary:

```

${CCP_CLI?} exec -ti pr-primary -- psql -d postgres -c 'create table foo (id int)'
${CCP_CLI?} exec -ti pr-primary -- psql -d postgres -c 'insert into foo values (1)'
```

Then verify that the data is replicated to the replica:

```
${CCP_CLI?} exec -ti pr-replica -- psql -d postgres -c 'table foo'
```

*primary-replica-dc*

If you wanted to experiment with scaling up the number of replicas, you can run the following example:

```
cd $CCPROOT/examples/kube/primary-replica-dc
./run.sh
```

You can verify that replication is working using the same commands as above.

```
${CCP_CLI?} exec -ti primary-dc -- psql -d postgres -c 'table pg_stat_replication'
```

### Helm

This example resides under the `$CCPROOT/examples/helm` directory. View the README to run this example
using Helm [here](https://github.com/CrunchyData/crunchy-containers/blob/master/examples/helm/primary-replica/README.md).
