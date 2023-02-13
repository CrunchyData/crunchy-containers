#!/bin/bash
# Copyright 2018 - 2023 Crunchy Data Solutions, Inc.
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

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RESET="\033[0m"

function echo_err() {
    echo -e "${RED?}$(date) ERROR: ${1?}${RESET?}"
}

function echo_info() {
    echo -e "${GREEN?}$(date) INFO: ${1?}${RESET?}"
}

function echo_warn() {
    echo -e "${YELLOW?}$(date) WARN: ${1?}${RESET?}"
}

function env_check_err() {
    if [[ -z ${!1} ]]
    then
        echo_err "$1 environment variable is not set, aborting.."
        exit 1
    fi
}

function dir_check_rm() {
    dir="${CCP_NAMESPACE?}-${1?}"
    if [[ -d ${CCP_STORAGE_PATH}/${dir?} ]]
    then
        sudo rm -rf ${CCP_STORAGE_PATH?}/${dir?} && \
            echo_info "Deleted ${dir?} from the data directory." || \
            echo_err "${dir?} was not successfully deleted from the data directory."
    fi
}

function create_storage {
    env_check_err "CCP_STORAGE_CAPACITY"
    env_check_err "CCP_STORAGE_MODE"
    PVC="${1?}-pvc.json"
    dir="${CCP_NAMESPACE?}-${1?}"

    if [[ ! -z ${CCP_STORAGE_CLASS} ]]
    then
        echo_info "CCP_STORAGE_CLASS is set. Using the existing storage class for the PV."
        PVC="${1?}-pvc-sc.json"
        if [[ ! -f ${DIR?}/${PVC?} ]]
        then
            echo_err "CCP_STORAGE_CLASS is set but ${DIR?}/${PVC?} does not exist.  Exiting.."
            exit 1
        fi
    elif [[ ! -z ${CCP_NFS_IP} ]]
    then
        echo_info "CCP_NFS_IP is set. Creating NFS based storage volumes."
        env_check_err "CCP_STORAGE_PATH"
        sudo mkdir -p ${CCP_STORAGE_PATH?}/${dir?}
        sudo chmod -R 777 ${CCP_STORAGE_PATH?}/${dir?}
        PV="${1?}-pv-nfs.json"
    else
        echo_info "CCP_NFS_IP and CCP_STORAGE_CLASS not set. Creating HostPath based storage volumes."
        env_check_err "CCP_STORAGE_PATH"
        sudo mkdir -p ${CCP_STORAGE_PATH?}/${dir?}
        sudo chmod -R 777 ${CCP_STORAGE_PATH?}/${dir?}
        PV="${1?}-pv.json"
    fi

    if [[ ${PV:-none} != "none" ]] && [[ ! -f ${DIR?}/${PV?} ]]
    then
        echo_err "Required PV definition ${DIR?}/${PV?} does not exist.  Exiting.."
        exit 1
    fi

    if [[ -f ${DIR?}/${PV:-none} ]]
    then
       cat ${DIR?}/${PV?} | envsubst | ${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} -f -
    fi

    if [[ -f ${DIR?}/${PVC?} ]]
    then
       cat ${DIR?}/${PVC?} | envsubst | ${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} -f -
    fi
}

function cleanup() {
    label="cleanup=${1?}"

    CONFIG="configmap,secret"
    DEPLOY="deployment,daemonset,job,pod,replicaset,service"
    RBAC="role,rolebinding,serviceaccount"
    VOLUME="pvc,pv"
    OBJECTS="${CONFIG?},${DEPLOY?},${RBAC?},${VOLUME?}"

    ${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} ${OBJECTS?} --selector=${label?}
}
