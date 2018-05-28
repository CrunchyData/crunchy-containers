---
title: "crunchy-watch"
date: 2018-05-24T12:06:15-07:00
draft: false
---

The crunchy-watch container essentially does a health check
on a primary database container and performs a failover sequence
if the primary is not reached. The watch container has access to a service
account that is used inside the container to issue commands to OpenShift.

In Kubrnetese 1.5, if a policy file is being used for securing down the
Kubernetes cluster, you could possibly need to add a policy to allow
the pg-watcher service account access to the Kubernetes API as mentioned
[here](https://kubernetes.io/docs/admin/authorization/abac/#a-quick-note-on-service-accounts).

In Kubernetes 1.6, an equivalent RBAC policy is also possibly required depending
on your authorization/authentication configuration. See  [this link](https://kubernetes.io/docs/admin/authorization/rbac/) for details on the new RBAC policy mechanism.

For example, you can grant cluster-admin permissions on the pg-watcher service
account in the my-namespace namespace as follows:
```bash
kubectl create clusterrolebinding pgwatcher-view-binding --clusterrole=cluster-admin --serviceaccount=my-namespace:pg-watcher
```

A less wide open policy would be applied like this on Kube 1.6 rbac:
```bash
kubectl create rolebinding my-sa-binding --clusterrole=admin --serviceaccount=demo:pg-watcher --namespace=demo
```

{{% notice tip %}}
The above kubectl command is only available in Kubernetes 1.6. For prior
Kubernetes releases such as 1.5 and the alpha RBAC, you will need to
specify the role binding in a JSON/YAML file instead of using
the previous command syntax.
{{% /notice %}}

The oc/docker/kubectl commands are included into the container from the
host when the container image is built.  These commands are used by
the watch logic to interact with the replica containers.

Starting with release 1.7.1, crunchy-watch source code is relocated
to a separate GitHub repository located [here](https://github.com/crunchydata/crunchy-watch).

## Environment Variables

### Required
**Name**|**Default**|**Description**
:-----|:-----|:-----
**CRUNCHY_WATCH_HEALTHCHECK_INTERVAL**|None|The time to sleep in seconds between checking on the primary.
**CRUNCHY_WATCH_FAILOVER_WAIT**|40s|The time to sleep in seconds between triggering the failover and updating its label.
**PG_CONTAINER_NAME**|None|If set, the name of the container to refer to when doing an *exec*. This is required if you have more than 1 container in your database pod.
**CRUNCHY_WATCH_PRIMARY**|None|The primary service name.
**CRUNCHY_WATCH_REPLICA**|None|The replica service name.
**PG_PRIMARY_PORT**|None|Database port to use when checking the database.
**CRUNCHY_WATCH_USERNAME**|None|Database user account to use when checking the database using pg_isready utility.
**CRUNCHY_WATCH_DATABASE**|None|Database to use when checking the database using pg_isready.
**REPLICA_TO_TRIGGER_LABEL**|None|The pod name of a replica that you want to choose as the new primary in a failover; this will override the normal replica selection.
**CRUNCHY_WATCH_PRE_HOOK**|None|Path to an executable file to run before failover is processed.
**CRUNCHY_WATCH_POST_HOOK**|None|Path to an executable file to run after failover is processed.

### Optional
**Name**|**Default**|**Description**
:-----|:-----|:-----
**CRUNCHY_DEBUG**|FALSE|Set this to true to enable debugging in logs. Note: this mode can reveal secrets in logs.

## Logic

The watch container will watch the primary. If the primary dies, then
the watcher will:

 * create the trigger file on the replica that will become the new primary
 * change the labels on the replica to be those of the primary
 * start watching the new primary in case that falls over next
 * look for replicas that have the metadata label value of *replicatype=trigger* to prefer
   the failover to. If found, it will use the first replica with that label; if
   not found, it will use the first replica it finds.

Example of looking for the failover replica:
```bash
oc get pod -l name=pg-replica-rc-dc
NAME                     READY     STATUS    RESTARTS   AGE
pg-replica-rc-dc           1/1       Running   2          16m
pg-replica-rc-dc-1-96qs8   1/1       Running   1          16m

oc get pod -l replicatype=trigger
NAME             READY     STATUS    RESTARTS   AGE
pg-replica-rc-dc   1/1       Running   2          16m
```
