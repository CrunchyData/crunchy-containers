#!/bin/bash

chown -R postgres /pgdata
chmod 700 /pgdata

chown -R postgres /pgwal

exec gosu postgres /opt/cpm/bin/start.sh "$@"