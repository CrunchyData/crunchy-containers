#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
psql -h primary-pitr -U postgres postgres -f $DIR/cmds.sql
