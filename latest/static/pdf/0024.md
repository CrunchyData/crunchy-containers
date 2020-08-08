---
title: "pgAudit"
date:
draft: false
weight: 72
---

## pgAudit Enhanced Logging

This example provides an example of enabling pg_audit output.
As of release 1.3, pg_audit is included in the crunchy-postgres
container and is added to the PostgreSQL shared library list in
`postgresql.conf`.

Given the numerous ways pg_audit can be configured, the exact
pg_audit configuration is left to the user to define.  pg_audit
allows you to configure auditing rules either in `postgresql.conf`
or within your SQL script.

For this test, we place pg_audit statements within a SQL script
and verify that auditing is enabled and working.  If you choose
to configure pg_audit via a `postgresql.conf` file, then you will
need to define your own custom file and mount it to override the
default `postgresql.conf` file.

### Docker

Run the following to create a database container:
```
cd $CCPROOT/examples/docker/pgaudit
./run.sh
```

This starts an instance of the pg_audit container (running crunchy-postgres)
on port 12005 on localhost. The test script is then automatically executed.

This test executes a SQL file which contains pg_audit configuration
statements as well as executes some basic SQL commands.  These
SQL commands will cause pg_audit to create log messages in
the `pg_log` log file created by the database container.

### Kubernetes and OpenShift

Run the following:
```
cd $CCPROOT/examples/kube/pgaudit
./run.sh
```

This script will create a PostgreSQL pod with the pgAudit extension configured and ready
to use

Once the pod is deployed successfully run the following command to test the extension:

```
cd $CCPROOT/examples/kube/pgaudit
./test-pgaudit.sh
```

This example has been configured to log directly to stdout of the pod.  To view the PostgreSQL logs,
run the following:

```
$CCP_CLI logs pgaudit
```
