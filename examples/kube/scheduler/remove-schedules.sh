#!/bin/bash

source ${CCPROOT}/examples/common.sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

${CCP_CLI?} delete --namespace=${CCP_NAMESPACE?} configmap -l crunchy-scheduler=true
