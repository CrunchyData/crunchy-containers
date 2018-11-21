#!/bin/bash

source /opt/cpm/bin/common_lib.sh
NAMESPACE=${HOSTNAME?}
BACKREST_CONF='/pgconf/pgbackrest.conf'

if [[ -v PGDATA_PATH_OVERRIDE ]]
then
    NAMESPACE=${PGDATA_PATH_OVERRIDE?}
fi

if [[ -f ${BACKREST_CONF?} ]]
then
    cp ${BACKREST_CONF?} /tmp/pgbackrest.conf
    sed -i -e "s|HOSTNAME|${NAMESPACE?}|" /tmp/pgbackrest.conf
fi

if [[ -f ${BACKREST_CONF?} ]] || [[ -v PGBACKREST_REPO_PATH ]]
then
    # Spooling directories for async archiving
    if [[ ! -d /pgdata/${NAMESPACE?}-spool ]]
    then
        mkdir -p /pgdata/${NAMESPACE?}-spool
    fi

    if [[ ! -d /pgwal/${NAMESPACE?}-spool ]] && [[ -v XLOGDIR ]]
    then
        mkdir -p /pgwal/${NAMESPACE?}-spool
    fi

    # Backup/Archive Namespace
    if [[ ! -d /backrestrepo/${NAMESPACE?}-backups ]]
    then
        mkdir -p /backrestrepo/${NAMESPACE?}-backups
    fi

    if [[ -f ${BACKREST_CONF?} ]]
    then
        stanza_exists=$(pgbackrest info | grep 'No stanzas exist')
        if [[ $? -eq 0 ]]
        then
            echo_info "pgBackRest: Creating stanza.."
            pgbackrest --stanza=db stanza-create --no-online
        fi
    fi

    if [[ -v PGBACKREST_REPO_PATH ]]
    then
        stanza_exists=$(pgbackrest info | grep 'missing stanza path')
        if [[ $? -eq 0 ]]
        then
            echo_info "pgBackRest: Creating stanza.."
            pgbackrest --stanza=db stanza-create --no-online
        fi
    fi
fi
