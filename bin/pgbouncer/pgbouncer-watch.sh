#!/bin/bash

# Copyright 2016 - 2018 Crunchy Data Solutions, Inc.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#export OSE_HOST=openshift.default.svc.cluster.local

source /opt/cpm/bin/common_lib.sh
enable_debugging

export SLEEP_TIME=${SLEEP_TIME:-10}
env_check_info "SLEEP_TIME is set to ${SLEEP_TIME}."

export PG_PRIMARY_SERVICE=$PG_PRIMARY_SERVICE
export PG_REPLICA_SERVICE=$PG_REPLICA_SERVICE
export PG_PRIMARY_PORT=$PG_PRIMARY_PORT
export PG_PRIMARY_USER=$PG_PRIMARY_USER
export PG_DATABASE=$PG_DATABASE

export PGROOT=$(find /usr/ -type d -name 'pgsql-*')

echo_info "Setting PGROOT to ${PGROOT?}."

export PATH=$PATH:/opt/cpm/bin:$PGROOT/bin

function failover() {
    if [[ -v KUBE_PROJECT ]]; then
        echo_info "Performing Kubernetes failover.."
        kube_failover
    elif [[ -v OSE_PROJECT ]]; then
        echo_info "Performing OpenShift failover.."
        ose_failover
    else
        echo_info "Performing standalone failover.."
        standalone_failover
    fi
}

function standalone_failover() {
    echo_info "Standalone failover is defined."

    # env var is required to talk to older docker
    # server using a more recent docker client
    export DOCKER_API_VERSION=1.20
    echo_info "Creating the trigger file on ${PG_REPLICA_SERVICE?}."
    docker exec $PG_REPLICA_SERVICE touch /tmp/pg-failover-trigger
    echo_info "Exiting after the failover has been triggered."

    /opt/cpm/bin/bounce /tmp/pgbouncer.ini

    echo_info "Reloading pgbouncer configuration file.."
    kill -s SIGHUP `cat /tmp/pgbouncer.pid`
    exit 0
}


function kube_failover() {

    TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
    #oc login https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT --insecure-skip-tls-verify=true --token="$TOKEN"
    #oc projects $OSE_PROJECT
    echo_info "Kubernetes failover is defined."

    TRIGGERREPLICAS=`kubectl get pod --selector=name=$PG_REPLICA_SERVICE --selector=replicatype=trigger --no-headers | cut -f1 -d' '`
    echo_info "${TRIGGERREPLICAS?} are defined as the trigger replicas."
    if [ "$TRIGGERREPLICAS" = "" ]; then
        echo_info "No trigger replicas found. Using any replica.."
        REPLICAS=`kubectl get pod --selector=name=$PG_REPLICA_SERVICE --no-headers | cut -f1 -d' '`
    else
        echo_info "Trigger replicas found."
        REPLICAS=$TRIGGERREPLICAS
    fi

    declare -a arr=($REPLICAS)
    firstreplica=true
    for i in  "${arr[@]}"
    do
        if [ "$firstreplica" = true ] ; then
            echo_info 'First replica defined as:' $i
            firstreplica=false
            echo_info "Triggering failover on replica:" $i
            kubectl exec $i touch /tmp/pg-failover-trigger
            echo_info "Sleeping 60 seconds to give failover a chance before setting label.."
            sleep 60
            echo_info "Changing label of replica to ${PG_PRIMARY_SERVICE?}."
            kubectl label --overwrite=true pod $i name=$PG_PRIMARY_SERVICE
        else
            echo_info "Deleting old replica " $i
            kubectl delete pod $i
        fi
    done

    echo_info "Failover succesfully completed at " `date`
}
function ose_failover() {

    TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
    oc login https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT --insecure-skip-tls-verify=true --token="$TOKEN"
    oc projects $OSE_PROJECT
    echo_info "OpenShift failover is defined."
    echo_info "Deleting primary service to block replicas.."
    oc get service $PG_PRIMARY_SERVICE -o json > /tmp/primary-service.json
    oc delete service $PG_PRIMARY_SERVICE
    echo_info "Sleeping for 10 seconds to allow replicas time to halt.."
    sleep 10

    TRIGGERREPLICAS=`oc get pod --selector=name=$PG_REPLICA_SERVICE --selector=replicatype=trigger --no-headers | cut -f1 -d' '`
    echo_info $TRIGGERREPLICAS " is TRIGGERREPLICAS"
    if [ "$TRIGGERREPLICAS" = "" ]; then
        echo_info "No trigger replicas found. Using any replica.."
        REPLICAS=`oc get pod --selector=name=$PG_REPLICA_SERVICE --no-headers | cut -f1 -d' '`
    else
        echo_info "Trigger replicas found."
        REPLICAS=$TRIGGERREPLICAS
    fi

    declare -a arr=($REPLICAS)
    firstreplica=true
    for i in  "${arr[@]}"
    do
        if [ "$firstreplica" = true ] ; then
            echo_info 'First replica is:' $i
            firstreplica=false
            echo_info "Triggering failover on replica:" $i
            oc exec $i touch /tmp/pg-failover-trigger
            echo_info "Sleeping 60 seconds to give failover a chance before setting label.."
            sleep 60
            echo_info "Changing label of replica to ${PG_PRIMARY_SERVICE?}."
            oc label --overwrite=true pod $i name=$PG_PRIMARY_SERVICE
            echo_info "Recreating primary service.."
            oc create -f /tmp/primary-service.json
        else
            echo_info "Deleting old replica " $i
            oc delete pod $i
        fi
    done

    echo_info "Failover succesfully completed at " `date`
}

while true; do
    sleep $SLEEP_TIME
    pg_isready  --dbname=$PG_DATABASE --host=$PG_PRIMARY_SERVICE --port=$PG_PRIMARY_PORT --username=$PG_PRIMARY_USER
    if [ $? -eq 0 ]
    then
        :
    else
        echo_info "Could not reach primary at " `date`
        failover
    fi
done
