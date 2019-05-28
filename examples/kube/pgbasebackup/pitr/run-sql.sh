#!/bin/bash

set -e

source "${CCPROOT}"/examples/common.sh

echo_info "Executing SQL in pitr pod.."

"${CCP_CLI?}" exec --namespace="${CCP_NAMESPACE?}" \
    -ti "$(kubectl get pod --selector=name=pitr -o name | sed "s/^pod\///")" \
    -- psql -d postgres -f /pgconf/cmds.sql

exit 0
