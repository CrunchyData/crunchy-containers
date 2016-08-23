#!/bin/bash
marathonctl -h http://10.0.2.15:8080 app create pgmaster.json
echo "sleeping before creating the slave to give master a chance to start.."
sleep 50
marathonctl -h http://10.0.2.15:8080 app create pgslave.json
