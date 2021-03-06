#!/bin/bash

# Copyright 2019 - 2021 Crunchy Data Solutions, Inc.
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

if [[ ${ENABLE_SSHD} == "true" ]]
then
    echo_info "Applying SSHD.."
    echo_info 'Checking for SSH Host Keys in /sshd..'

    if [[ ! -f /sshd/ssh_host_ed25519_key ]]; then
        echo_err 'No ssh_host_ed25519_key found in /sshd.  Exiting..'
        exit 1
    fi

    echo_info 'Checking for authorized_keys in /sshd'

    if [[ ! -f /sshd/authorized_keys ]]; then
        echo_err 'No authorized_keys file found in /sshd  Exiting..'
        exit 1
    fi

    echo_info 'Checking for sshd_config in /sshd'

    if [[ ! -f /sshd/sshd_config ]]; then
        echo_err 'No sshd_config file found in /sshd  Exiting..'
        exit 1
    fi

    echo_info "setting up .ssh directory"
    if [ -d "${HOME}/.ssh" ]; then 
        echo_info ".ssh directory already exists and will not be created"
    else 
        mkdir ~/.ssh
    fi
    cp /sshd/config ~/.ssh/
    cp /sshd/id_ed25519 /tmp
    chmod 400 /tmp/id_ed25519 ~/.ssh/config

    echo_info 'Starting SSHD..'
    /usr/sbin/sshd -f /sshd/sshd_config
fi
