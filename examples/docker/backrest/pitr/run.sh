#!/bin/bash

source ${CCPROOT}/examples/common.sh
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker exec -ti backrest date > /dev/null
if [[ $? -ne 0 ]]
then
    echo_err "The backup example must be running prior to using this example."
    exit 1
fi

export PITR_TARGET="$(docker exec -ti backrest psql -U postgres -Atc 'select current_timestamp' | tr -d '\r')"
if [[ -z ${PITR_TARGET?} ]]
then
    echo_err "PITR_TARGET env is empty, it shouldn't be."
    exit 1
fi

$DIR/cleanup.sh

docker run \
    --volume br-pgdata:/pgdata \
    --volume br-backups:/backrestrepo \
    --volume ${DIR?}/configs:/pgconf \
    --env STANZA=db \
    --env PITR_TARGET="${PITR_TARGET?}" \
    --name=backrest-pitr-restore \
    --hostname=backrest-pitr-restore \
    --detach ${CCP_IMAGE_PREFIX?}/crunchy-backrest-restore:${CCP_IMAGE_TAG?}
