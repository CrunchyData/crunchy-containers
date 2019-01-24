#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker stop backrest-delta-restore backrest-delta-restored backrest
docker rm backrest-delta-restore backrest-delta-restored backrest
