#!/bin/bash

# Copyright 2018 - 2021 Crunchy Data Solutions, Inc.
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

set -e -u

function echo_green() {
    echo -e "\033[0;32m"
    echo "=> $1"
    echo -e "\033[0m"
}

${CCP_CLI?} get namespaces | grep -v NAME | grep 'test-harness' | awk '{print $1}' | while read line
do
    echo_green "Deleting namespace ${line?}"
    ${CCP_CLI?} delete namespace ${line?} --cascade=true
done

echo_green "=> Done!"

exit 0
