---
title: "PostgreSQL Primary"
date:
draft: false
weight: 1
---
# PostgreSQL Container Example

This example starts a single PostgreSQL container and service, the most simple
of examples.

The container creates a default database called *userdb*, a default user called *testuser*
and a default password of *password*.

For all environments, the script additionally creates:

 * A persistent volume claim
 * A crunchy-postgres container named *primary*
 * The database using predefined environment variables

And specifically for the Kubernetes and OpenShift environments:

 * A pod named *primary*
 * A service named *primary*
 * A PVC named *primary-pgdata*
 * The database using predefined environment variables

To shutdown the instance and remove the container for each example, run the following:
```
./cleanup.sh
```

## Docker


To create the example and run the container:
```
cd $CCPROOT/examples/docker/primary
./run.sh
```

Connect from your local host as follows:
```
psql -h localhost -U testuser -W userdb
```

## Kubernetes and OpenShift

To create the example:
```
cd $CCPROOT/examples/kube/primary
./run.sh
```

Connect from your local host as follows:
```
psql -h primary -U postgres postgres
```

## Helm

This example resides under the `$CCPROOT/examples/helm` directory. View the README to run this
example using Helm [here](https://github.com/CrunchyData/crunchy-containers/blob/master/examples/helm/primary/README.md).
