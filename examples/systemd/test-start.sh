#!/bin/bash

docker start crunchy-pg

while true; do 
	sleep 10
	echo "sleeping to keep crunchy-pg up"
done
