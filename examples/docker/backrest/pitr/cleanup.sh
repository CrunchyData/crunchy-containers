#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker stop backrest-pitr-restore backrest
docker rm backrest-pitr-restore backrest
