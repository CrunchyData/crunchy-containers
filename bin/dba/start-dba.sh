#!/bin/bash 

# Copyright 2018 Crunchy Data Solutions, Inc.
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

export PATH=$PATH:/opt/cpm/bin

function trap_sigterm() {
	echo "doing trap logic..." 
	killall dbaserver
}

trap 'trap_sigterm' SIGINT SIGTERM

export TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"

handle_ose() {
export CMD=oc

oc login https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT --insecure-skip-tls-verify=true --token="$TOKEN"
oc project $OSE_PROJECT

oc policy add-role-to-group edit system:serviceaccounts -n $OSE_PROJECT
#oc policy add-role-to-group edit system:serviceaccounts -n default
}

handle_kube() {
	echo "KUBE environmnt assumed"
	export CMD=kubectl
}

if [ -v OSE_PROJECT ]; then
	echo "OSE_PROJECT is assumed"
	handle_ose
elif [ -v KUBE_PROJECT ]; then
	echo "KUBE_PROJECT is assumed"
	handle_kube
else
	echo "OSE_PROJECT or KUBE_PROJECT need to be set"
	exit 2
fi


echo $VAC_SCHEDULE is VAC_SCHEDULE

echo $OSE_PROJECT is OSE_PROJECT

echo $JOB_HOST is JOB_HOST
if [ ! -v JOB_HOST ]; then
	echo "JOB_HOST env var is not set, required value"
	exit 2
fi

dbaserver &

echo "waiting till signal is sent to quit..."

wait

echo "exiting...at end"
