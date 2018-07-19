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
    if [[ -d ${CCP_STORAGE_PATH?}/${1?} ]]
    then
        sudo rm -rf ${CCP_STORAGE_PATH?}/${1?} && echo_info "Deleted ${1?} from the data directory." || echo_err "${1?} was not successfully deleted from the data directory."
    fi
}

function file_check_rm() {
    if [[ -f ${CCP_STORAGE_PATH?}/${1?} ]]
    then
        sudo rm -f ${CCP_STORAGE_PATH?}/${1?} && echo_info "Deleted ${1?} from the data directory." || echo_err "${1?} was not successfully deleted from the data directory."
    fi
}

function create_storage {
    env_check_err "CCP_STORAGE_CAPACITY"
    env_check_err "CCP_STORAGE_MODE"

    if [ ! -z "$CCP_STORAGE_CLASS" ]; then
        echo_info "CCP_STORAGE_CLASS is set. Using the existing storage class for the PV."
        expenv -f $DIR/$1-pvc-sc.json | ${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} -f -
        echo_info "Creating the example components.."
    elif [ ! -z "$CCP_NFS_IP" ]; then
        echo_info "CCP_NFS_IP is set. Creating NFS based storage volumes."
        expenv -f $DIR/$1-pv-nfs.json | ${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} -f -
        expenv -f $DIR/$1-pvc.json | ${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} -f -
        echo_info "Creating the example components.."
    else
        echo_info "CCP_NFS_IP and CCP_STORAGE_CLASS not set. Creating HostPath based storage volumes."
        expenv -f $DIR/$1-pv.json | ${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} -f -
        expenv -f $DIR/$1-pvc.json | ${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} -f -
        echo_info "Creating the example components.."
    fi
}
