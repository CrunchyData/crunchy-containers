#!/bin/bash

source /opt/cpm/bin/common/common_lib.sh
enable_debugging

PGHA_SSL_CONFIG=""

custom_config() {
    src=${1?}
    dest=${2?}
    mode=${3?}
    if [[ -f ${src?} ]]
    then
        echo_info "Custom ${src?} detected.  Applying custom configuration.."

        cp ${src?} ${dest?}
        err_check "$?" "Applying custom configuration" "Could not copy ${src?} to ${dest?}"

        chmod ${mode?} ${dest?}
        err_check "$?" "Applying custom configuration" "Could not set mode ${mode?} on ${dest?}"
        
        case "${src?}" in
            "/pgconf/server.key")
            PGHA_SSL_CONFIG+=",\"ssl_key_file\":\"server.key\""
            ;;
            "/pgconf/server.crt")
            PGHA_SSL_CONFIG+=",\"ssl_cert_file\":\"server.crt\""
            ;;
            "/pgconf/ca.crt")
            PGHA_SSL_CONFIG+=",\"ssl_ca_file\":\"ca.crt\""
            ;;
            "/pgconf/ca.crl")
            PGHA_SSL_CONFIG+=",\"ssl_crl_file\":\"ca.crl\""
            ;;
        esac
    fi
}

# Call the custom-config function in order to configure any certificates available in the
# '/pgconf' directory as needed to enable SSL
custom_config "/pgconf/server.key" "${PATRONI_POSTGRESQL_DATA_DIR}/server.key" 600
custom_config "/pgconf/server.crt" "${PATRONI_POSTGRESQL_DATA_DIR}/server.crt" 600
custom_config "/pgconf/ca.crt" "${PATRONI_POSTGRESQL_DATA_DIR}/ca.crt" 600
custom_config "/pgconf/ca.crl" "${PATRONI_POSTGRESQL_DATA_DIR}/ca.crl" 600
custom_config "/pgconf/replicator.crt" "${PATRONI_POSTGRESQL_DATA_DIR}/replicator.crt" 600
custom_config "/pgconf/replicator.key" "${PATRONI_POSTGRESQL_DATA_DIR}/replicator.key" 600
custom_config "/pgconf/replicator.crl" "${PATRONI_POSTGRESQL_DATA_DIR}/replicator.crl" 600

export PGHA_SSL_CONFIG
