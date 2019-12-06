= scheduler(1)
Crunchy Data
2019
== NAME
Crunchy pgBench - a simple program for running benchmark tests against PostgreSQL.

== DESCRIPTION
The Crunchy pgBench pgbench is a simple program for running benchmark tests on PostgreSQL.
It runs the same sequence of SQL commands over and over, possibly in multiple
concurrent database sessions, and then calculates the average transaction rate
(transactions per second).

The container itself consists of:
    - RHEL7 base image
    - bash script that performs the container startup
    - pgbench binary app

== USAGE
See the crunchy docs.

The Red Hat Enterprise Linux version from which the container was built. For example, Version="7.7"

`Release=`

The specific release number of the container. For example, Release="4.1.2"
