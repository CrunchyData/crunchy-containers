#!/bin/bash

source "/tmp/pod_env.sh"

CLUSTER_LABEL="pg-cluster=${CLUSTER_NAME}"
TARGET_LABEL="pgo-backrest-repo=true"

opts=$(echo "$@" | grep -o "\-\-c.*")
pod=$(kubectl get pods --selector=${CLUSTER_LABEL},${TARGET_LABEL} -o name)

exec kubectl exec -i "${pod}" -- bash -c "pgbackrest ${opts}"
