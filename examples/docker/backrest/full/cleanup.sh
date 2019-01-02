#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker stop backrest-full-restore backrest-full-restored backrest
docker rm backrest-full-restore backrest-full-restored backrest
docker volume rm br-new-pgdata
