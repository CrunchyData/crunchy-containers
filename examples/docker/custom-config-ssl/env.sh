#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export PGSSLROOTCERT=${DIR?}/certs/ca.crt
export PGSSLCRL=${DIR?}/certs/ca.crl
export PGSSLCERT=${DIR?}/certs/client.crt
export PGSSLKEY=${DIR?}/certs/client.key
