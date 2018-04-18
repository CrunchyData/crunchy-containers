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

source /opt/cpm/bin/common_lib.sh
enable_debugging
ose_hack

export PATH=$PATH:/opt/cpm/bin
export TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"

function trap_sigterm() {
    echo_info "Doing trap logic.."
    echo_warn "Clean shutdown of dbaserver.."
    killall dbaserver
}

trap 'trap_sigterm' SIGINT SIGTERM

if [[ -v OSE_PROJECT ]]
then
    echo_info "OpenShift deployment detected.."
    export CMD=oc

    env_check_err "KUBERNETES_SERVICE_HOST"
    env_check_err "KUBERNETES_SERVICE_PORT"
    env_check_err "OSE_PROJECT"

    echo_info "Current OpenShift Project is ${OSE_PROJECT?}.."

    url="https://${KUBERNETES_SERVICE_HOST?}:${KUBERNETES_SERVICE_PORT?}"

    echo_info "Logging into OpenShift.."
    oc login ${url?} --insecure-skip-tls-verify=true --token="$TOKEN"

    echo_info "Setting OpenShift Project to ${OSE_PROJECT?}.."
    oc project ${OSE_PROJECT?}

    echo_info "Adding role to group system:serviceaccounts in ${OSE_PROJECT?}.."
    oc policy add-role-to-group edit system:serviceaccounts -n ${OSE_PROJECT?}
elif [[ -v KUBE_PROJECT ]]
then
    echo_info "Kubernetes deployment detected.."
	export CMD=kubectl
else
	echo_err "OSE_PROJECT or KUBE_PROJECT need to be set"
	exit 2
fi

echo_info "Vacuum Schedule is ${VAC_SCHEDULE}.."

env_check_err "JOB_HOST"
echo_info "Job Host is ${JOB_HOST?}.."

echo_info "Starting dbaserver.."
dbaserver &

wait
