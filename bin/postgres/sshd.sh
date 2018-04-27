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

function start_sshd() {
    echo_info 'Checking for SSH Host Keys in /sshd..'

    if [[ ! -f /sshd/ssh_host_rsa_key ]]; then
        echo_err 'No ssh_host_rsa_key found in /sshd.  Exiting..'
        exit 1
    elif [[ ! -f /sshd/ssh_host_ecdsa_key ]]; then
        echo_err 'No ssh_host_ecdsa_key found in /sshd.  Exiting..'
        exit 1
    elif [[ ! -f /sshd/ssh_host_ed25519_key ]]; then
        echo_err 'No ssh_host_ed25519_key found in /sshd.  Exiting..'
        exit 1
    fi

    echo_info 'Checking for authorized_keys in /pgconf..'

    if [[ ! -f /pgconf/authorized_keys ]]; then
        echo_err 'No authorized_keys file found in /pgconf.  Exiting..'
        exit 1
    fi

    echo_info 'Checking for sshd_config in /pgconf..'

    if [[ ! -f /pgconf/sshd_config ]]; then
        echo_err 'No sshd_config file found in /pgconf.  Exiting..'
        exit 1
    fi

    echo_info 'Starting SSHD..'
    /usr/sbin/sshd -f /pgconf/sshd_config
}
