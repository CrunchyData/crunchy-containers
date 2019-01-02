#!/bin/bash

source ${CCPROOT}/examples/common.sh
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker exec -ti backrest date > /dev/null
if [[ $? -ne 0 ]]
then
    echo_err "The backup example must be running prior to using this example."
    exit 1
fi

$DIR/cleanup.sh

docker run \
    --volume br-new-pgdata:/pgdata \
    --volume br-backups:/backrestrepo \
    --env PGBACKREST_STANZA=db \
    --env PGBACKREST_PG1_PATH=/pgdata/backrest-full-restored \
    --env PGBACKREST_REPO1_PATH=/backrestrepo/backrest-backups \
    --name=backrest-full-restore \
    --hostname=backrest-full-restore \
    --detach ${CCP_IMAGE_PREFIX?}/crunchy-backrest-restore:${CCP_IMAGE_TAG?}
