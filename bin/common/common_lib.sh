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

function enable_debugging() {
    if [[ ${DEBUG:-false} == "true" ]]
    then
        echo "Turning Debugging On"
        export PS4='+(${BASH_SOURCE}:${LINENO})> ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
        set -x
    fi
}

function ose_hack() {
    export USER_ID=$(id -u)
    export GROUP_ID=$(id -g)
    envsubst < /opt/cpm/conf/passwd.template > /tmp/passwd
    envsubst < /opt/cpm/conf/group.template > /tmp/group
    export LD_PRELOAD=/usr/lib64/libnss_wrapper.so
    export NSS_WRAPPER_PASSWD=/tmp/passwd
    export NSS_WRAPPER_GROUP=/tmp/group
}
