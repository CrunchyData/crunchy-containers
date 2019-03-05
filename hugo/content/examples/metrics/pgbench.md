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
Mon Mar  4 22:15:45 UTC 2019 INFO: Initializing the target benchmark database: userdb
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
generating data...
100000 of 500000 tuples (20%) done (elapsed 0.06 s, remaining 0.22 s)
200000 of 500000 tuples (40%) done (elapsed 0.23 s, remaining 0.35 s)
300000 of 500000 tuples (60%) done (elapsed 0.43 s, remaining 0.28 s)
400000 of 500000 tuples (80%) done (elapsed 0.54 s, remaining 0.13 s)
500000 of 500000 tuples (100%) done (elapsed 0.67 s, remaining 0.00 s)
creating primary keys...
done.

Mon Mar  4 22:15:51 UTC 2019 INFO: Running benchmark..
scale option ignored, using count from pgbench_branches table (5)
starting vacuum...end.
progress: 2.0 s, 296.4 tps, lat 24.773 ms stddev 14.494
progress: 4.0 s, 285.8 tps, lat 25.372 ms stddev 17.366
progress: 6.0 s, 265.2 tps, lat 27.857 ms stddev 16.442
progress: 8.0 s, 256.6 tps, lat 29.311 ms stddev 20.234
progress: 10.0 s, 250.7 tps, lat 29.296 ms stddev 19.838
progress: 12.0 s, 328.0 tps, lat 22.510 ms stddev 14.044
progress: 14.0 s, 308.8 tps, lat 23.971 ms stddev 14.218
progress: 16.0 s, 302.1 tps, lat 24.452 ms stddev 15.144
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 5
query mode: simple
number of clients: 10
number of threads: 5
number of transactions per client: 500
number of transactions actually processed: 5000/5000
latency average = 25.533 ms
latency stddev = 16.570 ms
tps = 286.088709 (including connections establishing)
tps = 385.523184 (excluding connections establishing)
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
Mon Mar  4 22:15:45 UTC 2019 INFO: Initializing the target benchmark database: userdb
dropping old tables...
NOTICE:  table "pgbench_accounts" does not exist, skipping
NOTICE:  table "pgbench_branches" does not exist, skipping
NOTICE:  table "pgbench_history" does not exist, skipping
NOTICE:  table "pgbench_tellers" does not exist, skipping
creating tables...
generating data...
100000 of 500000 tuples (20%) done (elapsed 0.06 s, remaining 0.22 s)
200000 of 500000 tuples (40%) done (elapsed 0.23 s, remaining 0.35 s)
300000 of 500000 tuples (60%) done (elapsed 0.43 s, remaining 0.28 s)
400000 of 500000 tuples (80%) done (elapsed 0.54 s, remaining 0.13 s)
500000 of 500000 tuples (100%) done (elapsed 0.67 s, remaining 0.00 s)
creating primary keys...
done.

Mon Mar  4 22:15:51 UTC 2019 INFO: Running benchmark..
scale option ignored, using count from pgbench_branches table (5)
starting vacuum...end.
progress: 2.0 s, 296.4 tps, lat 24.773 ms stddev 14.494
progress: 4.0 s, 285.8 tps, lat 25.372 ms stddev 17.366
progress: 6.0 s, 265.2 tps, lat 27.857 ms stddev 16.442
progress: 8.0 s, 256.6 tps, lat 29.311 ms stddev 20.234
progress: 10.0 s, 250.7 tps, lat 29.296 ms stddev 19.838
progress: 12.0 s, 328.0 tps, lat 22.510 ms stddev 14.044
progress: 14.0 s, 308.8 tps, lat 23.971 ms stddev 14.218
progress: 16.0 s, 302.1 tps, lat 24.452 ms stddev 15.144
transaction type: <builtin: TPC-B (sort of)>
scaling factor: 5
query mode: simple
number of clients: 10
number of threads: 5
number of transactions per client: 500
number of transactions actually processed: 5000/5000
latency average = 25.533 ms
latency stddev = 16.570 ms
tps = 286.088709 (including connections establishing)
tps = 385.523184 (excluding connections establishing)
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
Mon Mar  4 19:40:22 UTC 2019 INFO: Initializing the target benchmark database: userdb
dropping old tables...
creating tables...
generating data...
100000 of 100000 tuples (100%) done (elapsed 0.03 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done.

Mon Mar  4 19:40:22 UTC 2019 INFO: Running benchmark..
starting vacuum...end.
transaction type: /pgconf/transactions.sql
scaling factor: 1
query mode: simple
number of clients: 1
number of threads: 1
number of transactions per client: 10
number of transactions actually processed: 10/10
latency average = 4.275 ms
tps = 233.918129 (including connections establishing)
tps = 285.761641 (excluding connections establishing)
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
$ ${CCP_CLI?} logs <name of pgbench custom pod>
Mon Mar  4 19:40:22 UTC 2019 INFO: Initializing the target benchmark database: userdb
dropping old tables...
creating tables...
generating data...
100000 of 100000 tuples (100%) done (elapsed 0.03 s, remaining 0.00 s)
vacuuming...
creating primary keys...
done.

Mon Mar  4 19:40:22 UTC 2019 INFO: Running benchmark..
starting vacuum...end.
transaction type: /pgconf/transactions.sql
scaling factor: 1
query mode: simple
number of clients: 1
number of threads: 1
number of transactions per client: 10
number of transactions actually processed: 10/10
latency average = 4.275 ms
tps = 233.918129 (including connections establishing)
tps = 285.761641 (excluding connections establishing)
```
