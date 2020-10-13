#!/bin/bash

export PGHOST=/tmp
export PATH=/usr/pgsql-${PGVERSION}/bin:/opt/crunchy/bin:$PATH
export LD_LIBRARY_PATH=/usr/pgsql-${PGVERSION}/lib
