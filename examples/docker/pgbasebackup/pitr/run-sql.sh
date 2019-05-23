#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
docker exec -i pitr psql < "${DIR}"/configs/cmds.sql
