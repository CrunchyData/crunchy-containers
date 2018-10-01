#!/bin/bash

source ${CCPROOT}/examples/common.sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} configmap backrest-schedule-full \
    --from-file=${DIR?}/configs/schedule-backrest-full.json
${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} configmap backrest-schedule-diff \
    --from-file=${DIR?}/configs/schedule-backrest-diff.json
${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} configmap pgbasebackup-backup \
    --from-file=${DIR?}/configs/schedule-pgbasebackup.json

${CCP_CLI?} label --namespace=${CCP_NAMESPACE?} configmap backrest-schedule-full crunchy-scheduler=true
${CCP_CLI?} label --namespace=${CCP_NAMESPACE?} configmap backrest-schedule-diff crunchy-scheduler=true
${CCP_CLI?} label --namespace=${CCP_NAMESPACE?} configmap pgbasebackup-backup crunchy-scheduler=true
