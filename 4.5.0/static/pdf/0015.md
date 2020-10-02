---
title: "pgPool II"
date: 
draft: false
weight: 22
---

## pgPool Logical Router Example


An example is provided that will run a *pgPool II* container in conjunction with the
*primary-replica* example provided above.

You can execute both `INSERT` and `SELECT` statements after connecting to pgpool.
The container will direct `INSERT` statements to the primary and `SELECT` statements
will be sent round-robin to both the primary and replica.

The container creates a default database called *userdb*, a default user called
*testuser* and a default password of *password*.

You can view the nodes that pgpool is configured for by running:
```
psql -h pgpool -U testuser userdb -c 'show pool_nodes'
```

To shutdown the instance and remove the container for each example, run the following:
```
./cleanup.sh
```

### Docker

Create the container as follows:
```
cd $CCPROOT/examples/docker/pgpool
./run.sh
```

The example is configured to allow the *testuser* to connect
to the *userdb* database.
```
psql -h localhost -U testuser -p 12003 userdb
```

### Kubernetes and OpenShift

Run the following command to deploy the pgpool service:
```
cd $CCPROOT/examples/kube/pgpool
./run.sh
```

The example is configured to allow the *testuser* to connect
to the *userdb* database.
```
psql -h pgpool -U testuser userdb
```
