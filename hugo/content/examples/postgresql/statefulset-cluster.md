---
title: "Statefulset PostgreSQL Cluster"
date:
draft: false
weight: 7
---


## Statefulsets

This example deploys a statefulset named *statefulset*.  The statefulset
is a new feature in Kubernetes as of version 1.5 and in OpenShift Origin as of
version 3.5. Statefulsets have replaced PetSets going forward.

Please view [this Kubernetes description](https://kubernetes.io/docs/concepts/abstractions/controllers/statefulsets/)
to better understand what a Statefulset is and how it works.

This example creates 2 PostgreSQL containers to form the set.  At
startup, each container will examine its hostname to determine
if it is the first container within the set of containers.

The first container is determined by the hostname suffix assigned
by Kubernetes to the pod.  This is an ordinal value starting with *0*.
If a container sees that it has an ordinal value of *0*, it will
update the container labels to add a new label of:
```
name=$PG_PRIMARY_HOST
```

In this example, `PG_PRIMARY_HOST` is specified as `statefulset-primary`.

By default, the containers specify a value of `name=statefulset-replica`.

There are 2 services that end user applications will use to
access the PostgreSQL cluster, one service (statefulset-primary) routes to the primary
container and the other (statefulset-replica) to the replica containers.
```
$ ${CCP_CLI} get service
NAME            CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
kubernetes      10.96.0.1       <none>        443/TCP    22h
statefulset-primary    10.97.168.138   <none>        5432/TCP   1h
statefulset-replica   10.97.218.221   <none>        5432/TCP   1h
```

To shutdown the instance and remove the container for each example, run the following:
```
./cleanup.sh
```

### Kubernetes and OpenShift

First, start the example with the following command:
```
cd $CCPROOT/examples/kube/statefulset
./run.sh
```

You can access the primary database as follows:
```
psql -h statefulset-primary -U postgres postgres
```

You can access the replica databases as follows:
```
psql -h statefulset-replica -U postgres postgres
```

You can scale the number of containers using this command; this will
essentially create an additional replica database.
```
${CCP_CLI} scale --replicas=3 statefulset statefulset
```

### Helm

This example resides under the `$CCPROOT/examples/helm` directory. View the README to
run this example using Helm [here](https://github.com/CrunchyData/crunchy-containers/blob/master/examples/helm/statefulset/README.md).
