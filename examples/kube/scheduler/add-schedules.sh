#!/bin/bash

source ${CCPROOT}/examples/common.sh

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

expenv -f ${DIR?}/configs/schedule-pgbasebackup.json > /tmp/schedule-pgbasebackup.json
expenv -f ${DIR?}/configs/schedule-backrest-full.json > /tmp/schedule-backrest-full.json
expenv -f ${DIR?}/configs/schedule-backrest-diff.json > /tmp/schedule-backrest-diff.json

${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} configmap backrest-schedule-full \
    --from-file=/tmp/schedule-backrest-full.json
${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} configmap backrest-schedule-diff \
    --from-file=/tmp/schedule-backrest-diff.json
${CCP_CLI?} create --namespace=${CCP_NAMESPACE?} configmap pgbasebackup-backup \
    --from-file=/tmp/schedule-pgbasebackup.json

${CCP_CLI?} label --namespace=${CCP_NAMESPACE?} configmap backrest-schedule-full crunchy-scheduler=true
${CCP_CLI?} label --namespace=${CCP_NAMESPACE?} configmap backrest-schedule-diff crunchy-scheduler=true
${CCP_CLI?} label --namespace=${CCP_NAMESPACE?} configmap pgbasebackup-backup crunchy-scheduler=true
