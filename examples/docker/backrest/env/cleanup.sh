#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker stop backrest
docker rm backrest
docker volume rm br-pgdata br-backups
