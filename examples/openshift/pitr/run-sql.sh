#!/bin/bash
psql -h master-pitr.openshift.svc.cluster.local -U postgres postgres -f cmds.sql
