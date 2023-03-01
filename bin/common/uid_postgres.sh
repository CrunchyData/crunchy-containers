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

if ! whoami &> /dev/null
then
    if [[ -w /etc/passwd ]]
    then
        sed  "/postgres:x:26:/d" /etc/passwd >> /tmp/uid.tmp
        cp /tmp/uid.tmp /etc/passwd
        rm -f /tmp/uid.tmp
        echo "${USER_NAME:-postgres}:x:$(id -u):0:${USER_NAME:-postgres} user:${HOME}:/bin/bash" >> /etc/passwd
    fi

    if [[ -w /etc/group ]]
    then
        sed  "/postgres:x:26/d" /etc/group >> /tmp/gid.tmp
        cp /tmp/gid.tmp /etc/group
        rm -f /tmp/gid.tmp
        echo "nfsnobody:x:65534:" >> /etc/group
        echo "postgres:x:$(id -g):postgres" >> /etc/group
    fi
fi
exec "$@"
