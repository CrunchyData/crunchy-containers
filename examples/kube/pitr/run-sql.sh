#!/bin/bash
psql -h master-pitr -U postgres postgres -f cmds.sql
