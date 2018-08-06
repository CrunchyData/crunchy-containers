#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker stop backrest-async-archive
docker rm backrest-async-archive
docker volume rm br-aa-pgdata br-aa-backups
