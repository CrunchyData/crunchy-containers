#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
psql -h 127.0.0.1 -p 12000 -U postgres postgres -f $DIR/cmds.sql
