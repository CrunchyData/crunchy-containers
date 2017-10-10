#!/bin/bash

# Copyright 2015 Crunchy Data Solutions, Inc.
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
if [ ! -v SLEEP_TIME ]; then
	SLEEP_TIME=10
fi
echo "SLEEP_TIME is set to " $SLEEP_TIME

export PG_PRIMARY_SERVICE=$PG_PRIMARY_SERVICE
export PG_REPLICA_SERVICE=$PG_REPLICA_SERVICE
export PG_PRIMARY_PORT=$PG_PRIMARY_PORT
export PG_PRIMARY_USER=$PG_PRIMARY_USER
export PG_DATABASE=$PG_DATABASE

if [ -d /usr/pgsql-10 ]; then
        export PGROOT=/usr/pgsql-10
elif [ -d /usr/pgsql-9.6 ]; then
        export PGROOT=/usr/pgsql-9.6
elif [ -d /usr/pgsql-9.5 ]; then
        export PGROOT=/usr/pgsql-9.5
elif [ -d /usr/pgsql-9.4 ]; then
        export PGROOT=/usr/pgsql-9.4
else
        export PGROOT=/usr/pgsql-9.3
fi

echo "setting PGROOT to " $PGROOT

export PATH=$PATH:/opt/cpm/bin:$PGROOT/bin

function failover() {
	if [[ -v KUBE_PROJECT ]]; then
		echo "kube failover ....."
		kube_failover
	elif [[ -v OSE_PROJECT ]]; then
		echo "openshift failover ....."
		ose_failover
	else
		echo "standalone failover....."
		standalone_failover
	fi
}

function standalone_failover() {
	echo "standalone failover is called"

	# env var is required to talk to older docker
	# server using a more recent docker client
	export DOCKER_API_VERSION=1.20
	echo "creating the trigger file on " $PG_REPLICA_SERVICE
	docker exec $PG_REPLICA_SERVICE touch /tmp/pg-failover-trigger
	echo "exiting after the failover has been triggered..."

	/opt/cpm/bin/bounce /tmp/pgbouncer.ini

	echo "reloading pgbouncer config file"
	kill -s SIGHUP `cat /tmp/pgbouncer.pid`
	exit 0
}


function kube_failover() {

	TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
	#oc login https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT --insecure-skip-tls-verify=true --token="$TOKEN"
	#oc projects $OSE_PROJECT
	echo "performing failover..."

	TRIGGERREPLICAS=`kubectl get pod --selector=name=$PG_REPLICA_SERVICE --selector=replicatype=trigger --no-headers | cut -f1 -d' '`
	echo $TRIGGERREPLICAS " is TRIGGERREPLICAS"
	if [ "$TRIGGERREPLICAS" = "" ]; then
		echo "no trigger replicas found...using any replica"
		REPLICAS=`kubectl get pod --selector=name=$PG_REPLICA_SERVICE --no-headers | cut -f1 -d' '`
	else
		echo "trigger replicas found!"
		REPLICAS=$TRIGGERREPLICAS
	fi

	declare -a arr=($REPLICAS)
	firstreplica=true
	for i in  "${arr[@]}"
	do
		if [ "$firstreplica" = true ] ; then
                	echo 'first replica is:' $i
			firstreplica=false
			echo "going to trigger failover on replica:" $i
			kubectl exec $i touch /tmp/pg-failover-trigger
			echo "sleeping 60 secs to give failover a chance before setting label"
			sleep 60
			echo "changing label of replica to " $PG_PRIMARY_SERVICE
			kubectl label --overwrite=true pod $i name=$PG_PRIMARY_SERVICE
		else
			echo "deleting old replica " $i
			kubectl delete pod $i
		fi
	done

	echo "failover completed @ " `date`
}
function ose_failover() {

	TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
	oc login https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT --insecure-skip-tls-verify=true --token="$TOKEN"
	oc projects $OSE_PROJECT
	echo "performing failover..."
	echo "deleting primary service to block replicas..."
	oc get service $PG_PRIMARY_SERVICE -o json > /tmp/primary-service.json
	oc delete service $PG_PRIMARY_SERVICE
	echo "sleeping for 10 to give replicas chance to halt..."
	sleep 10

	TRIGGERREPLICAS=`oc get pod --selector=name=$PG_REPLICA_SERVICE --selector=replicatype=trigger --no-headers | cut -f1 -d' '`
	echo $TRIGGERREPLICAS " is TRIGGERREPLICAS"
	if [ "$TRIGGERREPLICAS" = "" ]; then
		echo "no trigger replicas found...using any replica"
		REPLICAS=`oc get pod --selector=name=$PG_REPLICA_SERVICE --no-headers | cut -f1 -d' '`
	else
		echo "trigger replicas found!"
		REPLICAS=$TRIGGERREPLICAS
	fi

	declare -a arr=($REPLICAS)
	firstreplica=true
	for i in  "${arr[@]}"
	do
		if [ "$firstreplica" = true ] ; then
                	echo 'first replica is:' $i
			firstreplica=false
			echo "going to trigger failover on replica:" $i
			oc exec $i touch /tmp/pg-failover-trigger
			echo "sleeping 60 secs to give failover a chance before setting label"
			sleep 60
			echo "changing label of replica to " $PG_PRIMARY_SERVICE
			oc label --overwrite=true pod $i name=$PG_PRIMARY_SERVICE
			echo "recreating primary service..."
			oc create -f /tmp/primary-service.json
		else
			echo "deleting old replica " $i
			oc delete pod $i
		fi
	done

	echo "failover completed @ " `date`
}

while true; do
	sleep $SLEEP_TIME
	pg_isready  --dbname=$PG_DATABASE --host=$PG_PRIMARY_SERVICE --port=$PG_PRIMARY_PORT --username=$PG_PRIMARY_USER
	if [ $? -eq 0 ]
	then
		:
	else
		echo "Could not reach primary @ " `date`
		failover
	fi
done
