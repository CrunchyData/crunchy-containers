#!/bin/bash
psql -h master-pitr.pgproject.svc.cluster.local -U postgres postgres -f cmds.sql
