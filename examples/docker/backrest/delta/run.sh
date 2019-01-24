#!/bin/bash

source ${CCPROOT}/examples/common.sh
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ -z ${CCP_BACKREST_TIMESTAMP} ]]
then
    echo_err "Please provide a valid timestamp for the delta PITR using varibale CCP_BACKREST_TIMESTAMP."
    exit 1
fi

docker exec -ti backrest date > /dev/null
if [[ $? -ne 0 ]]
then
    echo_err "The backup example must be running prior to using this example."
    exit 1
fi

$DIR/cleanup.sh

docker run \
    --volume br-pgdata:/pgdata \
    --volume br-backups:/backrestrepo \
    --env PGBACKREST_STANZA=db \
    --env PGBACKREST_PG1_PATH=/pgdata/backrest \
	--env PGBACKREST_REPO1_PATH=/backrestrepo/backrest-backups \
    --env PGBACKREST_DELTA=y \
    --env PGBACKREST_TYPE=time \
    --env PGBACKREST_TARGET="${CCP_BACKREST_TIMESTAMP}" \
    --env PGBACKREST_LOG_PATH=/tmp \
    --name=backrest-delta-restore \
    --hostname=backrest-delta-restore \
    --detach ${CCP_IMAGE_PREFIX?}/crunchy-backrest-restore:${CCP_IMAGE_TAG?}
