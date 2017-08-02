#!/bin/bash
marathonctl -h http://10.0.2.15:8080 app destroy /pgmaster
marathonctl -h http://10.0.2.15:8080 app destroy /pgreplica
