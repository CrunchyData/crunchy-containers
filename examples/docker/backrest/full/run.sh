#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

$DIR/cleanup.sh

docker run \
    --volume br-new-pgdata:/pgdata \
    --volume br-backups:/backrestrepo \
    --volume ${DIR?}/configs:/pgconf \
    --env STANZA=db \
    --env PG_HOSTNAME=backrest \
    --name=backrest-full-restore \
    --hostname=backrest-full-restore \
    --detach ${CCP_IMAGE_PREFIX?}/crunchy-backrest-restore:${CCP_IMAGE_TAG?}
