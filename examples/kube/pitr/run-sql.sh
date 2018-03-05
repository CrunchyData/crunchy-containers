#!/bin/bash
psql -h primary-pitr -U postgres postgres -f $DIR/cmds.sql
