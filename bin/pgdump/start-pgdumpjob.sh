#!/bin/bash

# Copyright 2018 Crunchy Data Solutions, Inc.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#
# Starting the pgdump job -
#
# The service looks for the following environment variables to be set by
# the cpm-admin -
#
# STANDARD ARGS:
#
# /pgdata is a volume that gets mapped into this container
# $PGDUMP_DB database we are connecting to
# $PGDUMP_HOST host we are connecting to
# $PGDUMP_PASS pg user password we are connecting with
# $PGDUMP_PORT pg port we are connecting to
# $PGDUMP_USER pg user we are connecting with
#
# ADDITIONAL ARGS:
#
# $PGDUMP_ALL option to run pg_dumpall instead of pg_dump (extra all databases of a cluster into a single script file)
# $PGDUMP_BLOBS option to include large objects in the dump
# $PGDUMP_CLEAN option to cleanly drop database objects prior to recreating them
# $PGDUMP_COLUMNINSERTS option to dump data as INSERT commands with explicit column names
# $PGDUMP_COMPRESSION option to specify the compression level to be applied to the output from pg_dump
# $PGDUMP_CREATE option to begin pg_dump output with the commands to create the database itself
# $PGDUMP_DATAONLY option to dump only the data (no schema)
# $PGDUMP_DISABLETRIGGERS option to disable triggers when running a data-only dump
# $PGDUMP_ENABLEROWSECURITY option to allow dumping content of tables with RLS turned on
# $PGDUMP_ENCODING option to specify the character set encoding
# $PGDUMP_EXCLUDEPRIVILEGES option to exclude commands which specify access privileges from the output by pg_dump
# $PGDUMP_FILE option to send the output to the specified file
# $PGDUMP_FORMAT option to select the output format (plain, custom, directory and tar)
# $PGDUMP_INSERTS option to dump data as INSERT commands rather than COPY commands
# $PGDUMP_LOCKWAITTIMEOUT option to specify the length of time to wait to acquire shared locks at the beginning of the dump
# $PGDUMP_NOOWNER option to exclude commands that set table ownership from the output by pg_dump
# $PGDUMP_MOTABLESPACES option to exclude tablespaces from being set in the output by pg_dump
# $PGDUMP_NUMJOBS option to specify the number of jobs to run the dump in parallel
# $PGDUMP_OIDS option to include object identifiers (OIDs) as part of the data for every table
# $PGDUMP_QUOTEIDENTIFIERS option to force quoting of all identifiers
# $PGDUMP_SCHEMA option to specify which schemas matched by the specified pattern are output by pg_dump
# $PGDUMP_SCHEMASTOEXCLUDE option to specify schemas matched by the specified pattern should be excluded from the output by pg_dump
# $PGDUMP_SCHEMAONLY option to dump the schema information only (no data)
# $PGDUMP_SUPERUSER option to specify the superuser name to use when disabling triggers
# $PGDUMP_TABLE option to specify which tables matched by the specified pattern are output by pg_dump
# $PGDUMP_TABLESTOEXCLUDE option to specify which tables matched by the specified pattern should be excluded from the output by pg_dump
# $PGDUMP_VERBOSE option to specify verbose mode to output detailed object comments and start/stop times to the output by pg_dump; as well as progress messages to standard error (STDERR)

# ls -l /
# ls -l /pgdata

# env

source /opt/cpm/bin/common_lib.sh
enable_debugging
ose_hack

TS=`date +%Y-%m-%d-%H-%M-%S`
PGDUMP_BASE=/pgdata/$PGDUMP_HOST-dumps
PGDUMP_PATH=$PGDUMP_BASE/$TS

if [ ! -d "$PGDUMP_BASE" ]; then
    echo_info "Creating PGDUMP_BASE directory as ${PGDUMP_BASE}.."
    mkdir -p $PGDUMP_BASE
fi

echo_info "PGDUMP_PATH is set to ${PGDUMP_PATH}."
mkdir $PGDUMP_PATH

export PGDUMP_LABEL=${PGDUMP_LABEL:-crunchypgdump}
env_check_info "PGDUMP_LABEL" "PGDUMP_LABEL is set to ${PGDUMP_LABEL}."

opts=""

if [[ ! -z "$PGDUMP_ALL" && "$PGDUMP_ALL" == "true" ]]; then
    echo_info "PGDUMP_ALL is set to $PGDUMP_ALL - Executing PGDUMP_ALL instead of PG_DUMP."
    echo_info "Any specified options that don't apply to pg_dumpall will be ignored."
    ALL_OPTS_ONLY=true
fi

# -z "$ALL_OPTS_ONLY" will only evaluate to true if $ALL_OPTS_ONLY is set (not a null string)
if [[ -z "$ALL_OPTS_ONLY" && ! -z "$PGDUMP_DB" ]]; then
    opts+=" --dbname=$PGDUMP_DB"
    echo_info "PGDUMP_DB is set to $PGDUMP_DB and has been added to the pg_dump options."
fi

if [[ -z "$ALL_OPTS_ONLY" && ! -z "$PGDUMP_BLOBS" && $PGDUMP_BLOBS == "true" ]]; then
    opts+=" --blobs=$PGDUMP_BLOBS"
    echo_info "PGDUMP_BLOBS is set to $PGDUMP_BLOBS and has been added to the pg_dump options."
fi

if [[ ! -z "$PGDUMP_CLEAN" && $PGDUMP_CLEAN == "true" ]]; then
    opts+=" --clean"
    echo_info "PGDUMP_CLEAN is set to $PGDUMP_CLEAN and has been added to the pg_dump options."
fi

if [[ ! -z "$PGDUMP_COLUMNINSERTS" && $PGDUMP_COLUMNINSERTS == "true" ]]; then
    opts+=" --column-inserts"
    echo_info "PGDUMP_COLUMNINSERTS is set to $PGDUMP_COLUMNINSERTS and has been added to the pg_dump options."
fi

if [[ -z "$ALL_OPTS_ONLY" && ! -z "$PGDUMP_COMPRESSION" ]]; then
    opts+=" --compress=$PGDUMP_COMPRESSION"
    echo_info "PGDUMP_COMPRESSION is set to $PGDUMP_COMPRESSION and has been added to the pg_dump options."
fi

if [[ -z "$ALL_OPTS_ONLY" && ! -z "$PGDUMP_CREATE" && $PGDUMP_CREATE == "true" ]]; then
    opts+=" --create"
    echo_info "PGDUMP_CREATE is set to $PGDUMP_CREATE and has been added to the pg_dump options."
fi

if [[ ! -z "$PGDUMP_DATAONLY" && $PGDUMP_DATAONLY == "true" ]]; then
    opts+=" --data-only"
    echo_info "PGDUMP_DATAONLY is set to $PGDUMP_DATAONLY and has been added to the pg_dump options."
fi

if [[ ! -z "$PGDUMP_DISABLETRIGGERS" && $PGDUMP_DISABLETRIGGERS == "true" ]]; then
    opts+=" --disable-triggers"
    echo_info "PGDUMP_DISABLETRIGGERS is set to $PGDUMP_DISABLETRIGGERS and has been added to the pg_dump options."
fi

if [[ -z "$ALL_OPTS_ONLY" && ! -z "$PGDUMP_ENABLEROWSECURITY" && $PGDUMP_ENABLEROWSECURITY == "true" ]]; then
    opts+=" --enable-row-security"
    echo_info "PGDUMP_ENABLEROWSECURITY is set to $PGDUMP_ENABLEROWSECURITY and has been added to the pg_dump options."
fi

if [[ -z "$ALL_OPTS_ONLY" && ! -z "$PGDUMP_ENCODING" ]]; then
    opts+=" --encoding=$PGDUMP_ENCODING"
    echo_info "PGDUMP_ENCODING is set to $PGDUMP_ENCODING and has been added to the pg_dump options."
fi

if [[ -z "$ALL_OPTS_ONLY" && ! -z "$PGDUMP_EXCLUDEPRIVILEGES" && $PGDUMP_EXCLUDEPRIVILEGES == "true" ]]; then
    opts+=" --no-privileges"
    echo_info "PGDUMP_EXCLUDEPRIVILEGES is set to $PGDUMP_EXCLUDEPRIVILEGES and has been added to the pg_dump options."
fi

if [[ ! -z "$PGDUMP_FILE" ]]; then # PGDUMPPATH set on line 80
    opts+=" --file=$PGDUMP_FILE"
    echo_info "PGDUMP_FILE is set to $PGDUMP_FILE and has been added to the PGDUMP_PATH options."
fi

if [[ -z "$ALL_OPTS_ONLY"  && ! -z "$PGDUMP_FORMAT" ]]; then
    opts+=" --format=$PGDUMP_FORMAT"
    echo_info "PGDUMP_FORMAT is set to $PGDUMP_FORMAT and has been added to the pg_dump options."

        if [[ $PGDUMP_FORMAT == "tar" || $PGDUMP_FORMAT == "t" ]]; then
        PGDUMP_EXT=".tar"
        elif [[ $PGDUMP_FORMAT == "plain" || $PGDUMP_FORMAT == "p" ]]; then
                PGDUMP_EXT=".sql"
        elif [[ $PGDUMP_FORMAT == "directory" || $PGDUMP_FORMAT == "d" ]]; then
                PGDUMP_EXT=""
        elif [[ $PGDUMP_FORMAT == "custom" || $PGDUMP_FORMAT == "c" ]]; then
                PGDUMP_EXT=".dump"
        fi
fi

if [[ ! -z "$PGDUMP_INSERTS" && $PGDUMP_INSERTS == "true" ]]; then
    opts+=" --inserts"
    echo_info "PGDUMP_INSERTS is set to $PGDUMP_INSERTS and has been added to the pg_dump options."
fi

if [[ ! -z "$PGDUMP_LOCKWAITTIMEOUT" ]]; then
    opts+=" --lock-wait-timeout=$PGDUMP_LOCKWAITTIMEOUT"
    echo_info "PGDUMP_LOCKWAITTIMEOUT is set to $PGDUMP_LOCKWAITTIMEOUT and has been added to the pg_dump options."
fi

if [[ ! -z "$PGDUMP_NOOWNER" && $PGDUMP_NOOWNER == "true" ]]; then
    opts+=" --noowner"
    echo_info "PGDUMP_NOOWNER is set to $PGDUMP_NOOWNER and has been added to the pg_dump options."
fi

if [[ ! -z "$PGDUMP_NOTABLESPACES" && $PGDUMP_NOTABLESPACES == "true" ]]; then
    opts+=" --no-tablespaces"
    echo_info "PGDUMP_NOTABLESPACES is set to $PGDUMP_NOTABLESPACES and has been added to the pg_dump options."
fi

if [[ -z "$ALL_OPTS_ONLY" && ! -z "$PGDUMP_NUMJOBS" ]]; then
    opts+=" --jobs=$PGDUMP_NUMJOBS"
    echo_info "PGDUMP_NUMJOBS is set to $PGDUMP_NUMJOBS and has been added to the pg_dump options."
fi

if [[ ! -z "$PGDUMP_OIDS" && $PGDUMP_OIDS == "true" ]]; then
    opts+=" --oids"
    echo_info "PGDUMP_OIDS is set to $PGDUMP_OIDS and has been added to the pg_dump options."
fi

if [[ ! -z "$PGDUMP_QUOTEIDENTIFIERS" && $PGDUMP_QUOTEIDENTIFIERS == "true" ]]; then
    opts+=" --quote-all-identifiers"
    echo_info "PGDUMP_QUOTEIDENTIFIERS is set to $PGDUMP_QUOTEIDENTIFIERS and has been added to the pg_dump options."
fi

if [[ ! -z "$PGDUMP_SCHEMA" ]]; then
    opts+=" --schema=$PGDUMP_SCHEMA"
    echo_info "PGDUMP_SCHEMA is set to $PGDUMP_SCHEMA and has been added to the pg_dump options."
fi

if [[ ! -z "$PGDUMP_SCHEMASTOEXCLUDE" ]]; then
    opts+=" --exclude-schema=$PGDUMP_SCHEMASTOEXCLUDE"
    echo_info "PGDUMP_SCHEMASTOEXCLUDE is set to $PGDUMP_SCHEMASTOEXCLUDE and has been added to the pg_dump options."
fi

if [[ ! -z "$PGDUMP_SCHEMAONLY" && $PGDUMP_SCHEMAONLY == "true" ]]; then
    opts+=" --schema-only"
    echo_info "PGDUMP_SCHEMAONLY is set to $PGDUMP_SCHEMAONLY and has been added to the pg_dump options."
fi

if [[ ! -z "$PGDUMP_SUPERUSER" ]]; then
    opts+=" --superuser=$PGDUMP_SUPERUSER"
    echo_info "PGDUMP_SUPERUSER is set to $PGDUMP_SUPERUSER and has been added to the pg_dump options."
fi

if [[ -z "$ALL_OPTS_ONLY" && ! -z "$PGDUMP_TABLE" ]]; then
    opts+=" --table=$PGDUMP_TABLE"
    echo_info "PGDUMP_TABLE is set to $PGDUMP_TABLE and has been added to the pg_dump options."
fi

if [[ -z "$ALL_OPTS_ONLY" && ! -z "$PGDUMP_TABLESTOEXCLUDE" ]]; then
    opts+=" --exclude-table=$PGDUMP_TABLESTOEXCLUDE"
    echo_info "PGDUMP_TABLESTOEXCLUDE is set to $PGDUMP_TABLESTOEXCLUDE and has been added to the pg_dump options."
fi

if [[ ! -z "$PGDUMP_VERBOSE" && $PGDUMP_VERBOSE == "true" ]]; then
    opts+=" --verbose"
    echo_info "PGDUMP_VERBOSE is set to $PGDUMP_VERBOSE and has been added to the pg_dump options."
fi

echo_info "The options specified for pg_dump include: ${opts}"

export PGPASSFILE=/tmp/pgpass

echo "*:*:*:"$PGDUMP_USER":"$PGDUMP_PASS  >> $PGPASSFILE

chmod 600 $PGPASSFILE

chown $UID:$UID $PGPASSFILE

# cat $PGPASSFILE

# If PGDUMP_ALL is set and set to true, run pg_dumpall
if [[ ! -z "$PGDUMP_ALL" && "$PGDUMP_ALL" == "true" ]]; then
    if [[ ! -z "$PGDUMP_FILE" ]]; then # If PG_DUMPFILE is set - it will output to the fully-qualified filename specified (included in the opts)
        pg_dumpall --host=$PGDUMP_HOST --port=$PGDUMP_PORT --username $PGDUMP_USER -w $opts
        chown -R $UID:$UID $PGDUMP_FILE
        echo_info "PGDUMP_ALL output file has been written to: $PGDUMP_FILE"
    else # Else, dump everything to the $PGDUMP_PATH via stdout
        pg_dumpall --host=$PGDUMP_HOST --port=$PGDUMP_PORT --username $PGDUMP_USER -w $opts > "$PGDUMP_PATH/pgdumpall.sql"
    chown -R $UID:$UID "$PGDUMP_PATH/pgdumpall.sql"
    echo_info "PGDUMP_ALL output file has been written to: $PGDUMP_PATH/pgdumpall.sql"
    fi

else # Else, run pg_dump
    if [[ ! -z "$PGDUMP_FILE" ]]; then # If PG_DUMPFILE is set - it will output to the fully-qualified filename specified (included in the opts)
        pg_dump --host=$PGDUMP_HOST --port=$PGDUMP_PORT --username $PGDUMP_USER --dbname $PGDUMP_DB -w $opts
        chown -R $UID:$UID $PGDUMP_FILE
        echo_info "PGDUMP_FILE output file has been written to: $PGDUMP_FILE"
    else # Else, dump everything to the $PGDUMP_PATH via stdout
        pg_dump --host=$PGDUMP_HOST --port=$PGDUMP_PORT --username $PGDUMP_USER --dbname $PGDUMP_DB -w $opts > "$PGDUMP_PATH/pgdump.$PGDUMPEXT"
        chown -R $UID:$UID "$PGDUMP_PATH/pgdumpall$PGDUMPEXT"
        echo_info "PG_DUMP output file has been written to: $PGDUMP_PATH/pgdump$PGDUMPEXT"
    fi
fi

echo_info "Backup has completed."
