---
title: "pgBadger"
date: 
draft: false
weight: 62
---

## pgBadger Example


pgbadger is a PostgreSQL tool that reads the log files from a specified database
in order to produce a HTML report that shows various PostgreSQL statistics and graphs.
This example runs the pgbadger HTTP server against a crunchy-postgres container and
illustrates how to view the generated reports.

The port utilized for this tool is port 14000 for Docker environments and port 10000
for Kubernetes and OpenShift environments.

The container creates a default database called *userdb*, a default user called
*testuser* and a default password of *password*.

To shutdown the instance and remove the container for each example, run the following:
```
./cleanup.sh
```

### Docker

Run the example as follows:
```
cd $CCPROOT/examples/docker/pgbadger
./run.sh
```

After execution, the container will run and provide a simple HTTP
command you can browse to view the report.  As you run queries against
the database, you can invoke this URL to generate updated reports:
```
curl -L http://127.0.0.1:10000/api/badgergenerate
```

### Kubernetes and OpenShift

Running the example:
```
cd $CCPROOT/examples/kube/pgbadger
./run.sh
```

After execution, the container will run and provide a simple HTTP
command you can browse to view the report.  As you run queries against
the database, you can invoke this URL to generate updated reports:
```
curl -L http://pgbadger:10000/api/badgergenerate
```

You can view the database container logs using these commands:
```
${CCP_CLI} logs pgbadger -c pgbadger
${CCP_CLI} logs pgbadger -c postgres
```
