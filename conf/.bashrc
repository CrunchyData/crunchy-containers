#!/bin/bash

export PGHOST=/tmp
export PGROOT=$(find /usr/ -type d -name 'pgsql-*')
export PATH=${PGROOT?}/bin:/opt/cpm/bin:$PATH
export LD_LIBRARY_PATH=${PGROOT?}/lib:$LD_LIBRARY_PATH
export LD_PRELOAD=/usr/lib64/libnss_wrapper.so
export NSS_WRAPPER_PASSWD=/tmp/passwd
export NSS_WRAPPER_GROUP=/tmp/group
