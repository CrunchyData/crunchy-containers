---
title: "Synchronous Replication"
date: 
draft: false
weight: 6
---

## Synchronous Replication

This example deploys a PostgreSQL cluster with a primary, a synchronous replica, and
an asynchronous replica. The two replicas share the same service.

To shutdown the instance and remove the container for each example, run the following:
```
./cleanup.sh
```

### Docker

To run this example, run the following:
```
cd $CCPROOT/examples/docker/sync
./run.sh
```

You can test the replication status on the primary by using the following command
and the password *password*:
```
psql -h 127.0.0.1 -p 12010 -U postgres postgres -c 'table pg_stat_replication'
```

You should see 2 rows; 1 for the asynchronous replica and 1 for the synchronous replica.  The
`sync_state` column shows values of async or sync.

You can test replication to the replicas by first entering some data on
the primary, and secondly querying the replicas for that data:
```
psql -h 127.0.0.1 -p 12010 -U postgres postgres -c 'create table foo (id int)'
psql -h 127.0.0.1 -p 12010 -U postgres postgres -c 'insert into foo values (1)'
psql -h 127.0.0.1 -p 12011 -U postgres postgres -c 'table foo'
psql -h 127.0.0.1 -p 12012 -U postgres postgres -c 'table foo'
```

### Kubernetes and OpenShift

Running the example:
```
cd $CCPROOT/examples/kube/sync
./run.sh
```

Connect to the *primarysync* and *replicasync* databases as follows for both the
Kubernetes and OpenShift environments:
```
psql -h primarysync -U postgres postgres -c 'create table test (id int)'
psql -h primarysync -U postgres postgres -c 'insert into test values (1)'
psql -h primarysync -U postgres postgres -c 'table pg_stat_replication'
psql -h replicasync -U postgres postgres -c 'select inet_server_addr(), * from test'
psql -h replicasync -U postgres postgres -c 'select inet_server_addr(), * from test'
psql -h replicasync -U postgres postgres -c 'select inet_server_addr(), * from test'
```

This set of queries will show you the IP address of the PostgreSQL replica
container. Note the changing IP address due to the round-robin service proxy
being used for both replicas.  The example queries also show that both
replicas are replicating successfully from the primary.
