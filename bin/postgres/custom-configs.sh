#!/bin/bash

source /opt/cpm/bin/common_lib.sh
enable_debugging
ose_hack

function custom_config() {
    src=${1?}
    dest=${2?}
    mode=${3?}
    owner=${4?}
    if [[ -f ${src?} ]]
    then 
        echo_info "Custom ${src?} detected.  Applying custom configuration.."
        cp ${src?} ${dest?}
        chown ${owner?} ${dest?}
        chmod ${mode?} ${dest?}
    fi
}

custom_config "/pgconf/postgresql.conf" "${PGDATA?}/postgresql.conf" 600 "postgres:postgres"
custom_config "/pgconf/pg_hba.conf" "${PGDATA?}/pg_hba.conf" 600 "postgres:postgres"
custom_config "/pgconf/pg_ident.conf" "${PGDATA?}/pg_ident.conf" 600 "postgres:postgres"
custom_config "/pgconf/server.key" "${PGDATA?}/server.key" 600 "postgres:postgres"
custom_config "/pgconf/server.crt" "${PGDATA?}/server.crt" 600 "postgres:postgres"
custom_config "/pgconf/ca.crt" "${PGDATA?}/ca.crt" 600 "postgres:postgres"
custom_config "/pgconf/ca.crl" "${PGDATA?}/ca.crl" 600 "postgres:postgres"
