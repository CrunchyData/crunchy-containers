#!/bin/bash  -x

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

function ose_hack() {
	export USER_ID=$(id -u)
	export GROUP_ID=$(id -g)
	envsubst < /opt/cpm/conf/passwd.template > /tmp/passwd
	envsubst < /opt/cpm/conf/group.template > /tmp/group
	export LD_PRELOAD=/usr/lib64/libnss_wrapper.so
	export NSS_WRAPPER_PASSWD=/tmp/passwd
	export NSS_WRAPPER_GROUP=/tmp/group
}


function start_sshd() {
    ose_hack

    echo "Creating ${HOME?}/.ssh directory..."
    mkdir -p ${HOME?}/.ssh
    chmod 755 ${HOME?}/.ssh

    echo 'Checking for SSH Host Keys in /sshd...'

    if [[ ! -f /sshd/ssh_host_rsa_key ]]; then
        echo 'No ssh_host_rsa_key found in /sshd.  Exiting..'
        exit 1
    elif [[ ! -f /sshd/ssh_host_ecdsa_key ]]; then
        echo 'No ssh_host_ecdsa_key found in /sshd.  Exiting..'
        exit 1
    elif [[ ! -f /sshd/ssh_host_ed25519_key ]]; then
        echo 'No ssh_host_ed25519_key found in /sshd.  Exiting..'
        exit 1
    fi
	
    echo 'Checking for authorized_keys in /pgconf...'

    if [[ ! -f /pgconf/authorized_keys ]]; then
        echo 'No authorized_keys file found in /pgconf.  Exiting..'
        exit 1
    fi

    cp /pgconf/authorized_keys ${HOME?}/.ssh/authorized_keys
    chmod 644 ${HOME?}/.ssh/authorized_keys

    echo 'Checking for sshd_config in /pgconf...'

    if [[ ! -f /pgconf/sshd_config ]]; then
        echo 'No sshd_config file found in /pgconf.  Exiting..'
        exit 1
    fi

    echo 'Starting SSHD...'
    /usr/sbin/sshd -f /pgconf/sshd_config
}
