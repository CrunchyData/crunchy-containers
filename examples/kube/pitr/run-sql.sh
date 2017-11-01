#!/bin/bash
psql -h primary-pitr -U postgres postgres -f cmds.sql
