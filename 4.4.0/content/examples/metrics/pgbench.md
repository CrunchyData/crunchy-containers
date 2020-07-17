---
title: "pgBench"
date:
draft: false
weight: 62
---

## pgBench Example


pgbench is a simple program for running benchmark tests on PostgreSQL. It runs the same sequence of SQL commands over and over, possibly in multiple concurrent database sessions, and then calculates the average transaction rate (transactions per second). By default, pgbench tests a scenario that is loosely based on TPC-B, involving five SELECT, UPDATE, and INSERT commands per transaction. However, it is easy to test other cases by writing your own transaction script files.

For more information on how to configure this container, please see the [Container Specifications](/container-specifications/) document.


### Docker

{{% notice tip %}}
This example requires the primary example to be running.
{{% /notice %}}

Run the example as follows:

```
cd $CCPROOT/examples/docker/pgbench
./run.sh
```

After execution check the pgBench container logs for the benchmark results:

```
$ docker logs pgbench
dropping old tables...
creating tables...
generating data...
100000 of 100000 tuples (100%) done (elapsed 0.06 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done.
scale option ignored, using count from pgbench_branches table (1)
starting vacuum...end.
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 1
number of threads: 1
number of transactions per client: 1
number of transactions actually processed: 1/1
latency average = 8.969 ms
tps = 111.498084 (including connections establishing)
tps = 211.041835 (excluding connections establishing)
```

### Kubernetes and OpenShift

{{% notice tip %}}
This example requires the primary example to be running.
{{% /notice %}}

Run the example as follows:

```
cd $CCPROOT/examples/kube/pgbench
./run.sh
```

After execution check the pgBench container logs for the benchmark results:

```
$ ${CCP_CLI?} logs <name of pgbench pod>
dropping old tables...
creating tables...
generating data...
100000 of 100000 tuples (100%) done (elapsed 0.06 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done.
scale option ignored, using count from pgbench_branches table (1)
starting vacuum...end.
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 1
query mode: simple
number of clients: 1
number of threads: 1
number of transactions per client: 1
number of transactions actually processed: 1/1
latency average = 8.969 ms
tps = 111.498084 (including connections establishing)
tps = 211.041835 (excluding connections establishing)
```

## pgBench Custom Transaction Example

The Crunch pgBench image supports mounting a custom transaction script (`transaction.sql`), which can be mounted to the `/pgconf` for auto-detection and configuration by the container.

This allows users to setup custom benchmarking scenarios for advanced use cases.

{{% notice tip %}}
This example requires the primary example to be running.
{{% /notice %}}

Run the example as follows:

```
cd $CCPROOT/examples/docker/pgbench-custom
./run.sh
```

After execution check the pgBench container logs for the benchmark results:

```
$ docker logs pgbench-custom
dropping old tables...
creating tables...
generating data...
100000 of 100000 tuples (100%) done (elapsed 0.06 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done.
scale option ignored, using count from pgbench_branches table (1)
starting vacuum...end.
transaction type: /pgconf/transactions.sql
scaling factor: 1
query mode: simple
number of clients: 1
number of threads: 1
number of transactions per client: 1
number of transactions actually processed: 1/1
latency average = 8.969 ms
tps = 111.498084 (including connections establishing)
tps = 211.041835 (excluding connections establishing)
```

### Kubernetes and OpenShift

{{% notice tip %}}
This example requires the primary example to be running.
{{% /notice %}}

Run the example as follows:

```
cd $CCPROOT/examples/kube/pgbench-custom
./run.sh
```

After execution check the pgBench container logs for the benchmark results:

```
dropping old tables...
creating tables...
generating data...
100000 of 100000 tuples (100%) done (elapsed 0.06 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done.
scale option ignored, using count from pgbench_branches table (1)
starting vacuum...end.
transaction type: /pgconf/transactions.sql
scaling factor: 1
query mode: simple
number of clients: 1
number of threads: 1
number of transactions per client: 1
number of transactions actually processed: 1/1
latency average = 8.969 ms
tps = 111.498084 (including connections establishing)
tps = 211.041835 (excluding connections establishing)
```
