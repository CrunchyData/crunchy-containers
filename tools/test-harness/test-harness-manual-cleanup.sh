#!/bin/bash

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
