#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
psql -h 172.30.98.6 -U postgres postgres -f $DIR/cmds.sql
