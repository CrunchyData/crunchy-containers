#!/bin/bash

set -e

source ${CCPROOT}/examples/common.sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo_info "Executing SQL in pitr pod.."
${CCP_CLI?} exec --namespace=${CCP_NAMESPACE?} -ti pitr -- psql -d postgres -f /pgconf/cmds.sql

exit 0
