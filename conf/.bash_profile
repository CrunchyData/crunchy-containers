#!/bin/bash

export PGHOST=/tmp
export PATH=/usr/pgsql-${PGVERSION}/bin:/opt/cpm/bin:$PATH
export LD_LIBRARY_PATH=/usr/pgsql-${PGVERSION}/lib

# export LD_PRELOAD=/usr/lib64/libnss_wrapper.so
# export NSS_WRAPPER_PASSWD=/tmp/passwd
# export NSS_WRAPPER_GROUP=/tmp/group