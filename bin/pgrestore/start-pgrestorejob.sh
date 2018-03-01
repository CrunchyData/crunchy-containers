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
# start the pgrestore job
#
# the service looks for the following env vars to be set by
# the cpm-admin that provisioned us
#
# STANDARD ARGS:
#
# /pgdata is a volume that gets mapped into this container
# $PGRESTORE_DB database we are connecting and restoring to
# $PGRESTORE_HOST host we are connecting to
# $PGRESTORE_PASS pg user password we are connecting with
# $PGRESTORE_PORT pg port we are connecting to
# $PGRESTORE_USER pg user we are connecting with
# $PGRESTORE_RESTOREFILE which filename (only) to use as the input source for pg_restore
# $PGRESTORE_VOLUMEPATH which path (only) to use as the input source for pg_restore
#
# ADDITIONAL ARGS:
#
# $PGRESTORE_CLEAN option to cleanly drop database objects prior to recreating them.
# $PGRESTORE_CREATE option to begin pg_restore by creating the datbase before restoring into it.
# $PGRESTORE_DATAONLY option to restore only the data (no schema).
# $PGRESTORE_DISABLETRIGGERS option to disable triggers when running a data-only restore
# $PGRESTORE_ENABLEROWSECURITY option to allow restoring content of tables with RLS turned on.
# $PGRESTORE_EXCLUDEPRIVILEGES option to exclude commands which specify access privileges from the restore.
# $PGRESTORE_EXITONERROR option to exit if an error occurs when sending SQL commands to the Postgres DB instance (default: false).
# $PGRESTORE_FORMAT option to select the output format (plain (p), custom (c), directory (d) and tar (t))
# $PGRESTORE_IFEXISTS option to use conditional commands (IF EXISTS clause) to the restore process when cleaning database objects.
# $PGRESTORE_INDEX option to restore definition of named index only.
# $PGRESTORE_LIST option to list the contents of the archive.
# $PGRESTORE_LISTFILE option to restore only the archived elements that are listed in the named list file.
# $PGRESTORE_NODATAFORFAILEDTABLES option to skip data restoration if the creation command for the table failed.
# $PGRESTORE_NOOWNER option to exclude commands that set table ownership from the restore.
# $PGRESTORE_NOSECURITYLABELS option to exclude commands to restore security labels.
# $PGRESTORE_NOTABLESPACES option to exclude tablespaces from the restore - all objects are created in the default namespace.
# $PGRESTORE_NUMJOBS option to specify the number of jobs to run the restore in parallel.
# $PGRESTORE_ROLE specifies a role name to be used to perform the restore. This option causes pg_restore to issue a SET ROLE rolename command after connecting to the database. It is useful when the authenticated user (specified by -U) lacks privileges needed by pg_restore, but can switch to a role with the required rights.
# $PGRESTORE_SCHEMA option to restore only objects that are in the named schema.
# $PGRESTORE_SCHEMAONLY option to restore the schema information only (no data).
# $PGRESTORE_SECTION option to restore only the named section; the section name can be pre-data, data, or post-data.
# $PGRESTORE_SINGLETRANSACTION option to execute rhe restore as a single transaction (all commands wrapped in a BEGIN/COMMIT block); this ensures that all commands complete successfully or no changes are applied.
# $PGRESTORE_SUPERUSER option to specify the superuser name to use when disabling triggers.
# $PGRESTORE_TABLE option to restore only the definition and/or data of the named table.
# $PGRESTORE_TRIGGER option to restore only the the named trigger.
# $PGRESTORE_USESESSIONAUTH option for pg_restore to output SQL-standard SET SESSION AUTHORIZATION commands instead of ALTER OWNER commands to determine object ownership.
# $PGRESTORE_VERBOSE option to specify verbose mode to output detailed object comments and start/stop times to the output from pg_restore; as well as progress messages to standard error (STDERR).
# $PGRESTORE_VERSION option to output the pg_restore version and exit.

# ls -l /
# ls -l /pgdata

# env

source /opt/cpm/bin/common_lib.sh
enable_debugging
ose_hack

if [ ! -d "$PGRESTORE_VOLUMEPATH" ]; then
  echo "PGRESTORE_VOLUMEPATH $PGRESTORE_VOLUMEPATH does not exist; exiting."
  exit 1
else
  PGRESTORE_FULLPATH=$(realpath -s "$PGRESTORE_VOLUMEPATH")"/$PGRESTORE_FILE"
  echo "PGRESTORE_FULLPATH has been concatenated together as: $PGRESTORE_FULLPATH."
  if [ ! -f "$PGRESTORE_FULLPATH" ]; then
    echo "PGRESTORE_FULLPATH $PGRESTORE_FULLPATH does not exist; exiting."
    exit 1
  fi
  echo "The restore process will pickup the file from that location on the container filesytem."
fi

if [[ ! -v "PGRESTORELABEL" ]]; then
	PGRESTORE_LABEL="crunchypgrestore"
fi
echo "PGRESTORE_LABEL is set to " $PGRESTORE_LABEL

opts=""

if [[ ! -z "$PGRESTORE_CLEAN" && $PGRESTORE_CLEAN == "true" ]]; then
	opts+=" --clean"
  echo "PGRESTORE_CLEAN is set to $PGRESTORE_CLEAN and has been added to the pg_restore options"
fi

if [[ ! -z "$PGRESTORE_CREATE" && $PGRESTORE_CREATE == "true" ]]; then
	opts+=" --create"
  echo "PGRESTORE_CREATE is set to $PGRESTORE_CREATE and has been added to the pg_restore options"
fi

if [[ ! -z "$PGRESTORE_DATAONLY" && $PGRESTORE_DATAONLY == "true" ]]; then
	opts+=" --data-only"
  echo "PGRESTORE_DATAONLY is set to $PGRESTORE_DATAONLY and has been added to the pg_restore options"
fi

if [[ ! -z "$PGRESTORE_DB" ]]; then
        opts+=" --dbname=$PGRESTORE_DB"
  echo "PGRESTORE_DB is set to $PGRESTORE_DB and has been added to the pg_restore options"
fi

if [[ ! -z "$PGRESTORE_DISABLETRIGGERS" && $PGRESTORE_DISABLETRIGGERS == "true" ]]; then
	opts+=" --disable-triggers"
  echo "PGRESTORE_DISABLETRIGGERS is set to $PGRESTORE_DISABLETRIGGERS and has been added to the pg_restore options"
fi

if [[ ! -z "$PGRESTORE_ENABLEROWSECURITY" && $PGRESTORE_ENABLEROWSECURITY == "true" ]]; then
	opts+=" --enable-row-security"
  echo "PGRESTORE_ENABLEROWSECURITY is set to $PGRESTORE_ENABLEROWSECURITY and has been added to the pg_restore options"
fi

if [[ ! -z "$PGRESTORE_EXCLUDEPRIVILEGES" && $PGRESTORE_EXCLUDEPRIVILEGES == "true" ]]; then
	opts+=" --no-privileges"
  echo "PGRESTORE_EXCLUDEPRIVILEGES is set to $PGRESTORE_EXCLUDEPRIVILEGES and has been added to the pg_restore options"
fi

if [[ ! -z "$PGRESTORE_EXITONERROR" && $PGRESTORE_EXITONERROR == "true" ]]; then
	opts+=" --exit-on-error"
  echo "PGRESTORE_DATAONLY is set to $PGRESTORE_EXITONERROR and has been added to the pg_restore options"
fi

if [[ ! -z "$PGRESTORE_FORMAT" ]]; then
  if [[ $PGRESTORE_FORMAT == "plain" || $PGRESTORE_FORMAT == "p" ]]; then
    USE_PSQL="true"
    echo "As the restore format is plaintext, using psql instead of pg_restore."
  else
    opts+=" --format=$PGRESTORE_FORMAT"
    echo "PGRESTORE_FORMAT is set to $PGRESTORE_FORMAT and has been added to the pg_restore options"
  fi
fi

if [[ ! -z "$PGRESTORE_IFEXISTS" && $PGRESTORE_IFEXISTS == "true" ]]; then
	opts+=" --if-exists"
  echo "PGRESTORE_IFEXISTS is set to $PGRESTORE_IFEXISTS and has been added to the pg_restore options"
fi

if [[ ! -z "$PGRESTORE_INDEX" ]]; then
	opts+=" --index=$PGRESTORE_INDEX"
  echo "PGRESTORE_INDEX is set to $PGRESTORE_INDEX and has been added to the pg_restore options"
fi

if [[ ! -z "$PGRESTORE_LIST" && $PGRESTORE_LIST == "true" ]]; then
	opts+=" --list"
  echo "PGRESTORE_LIST is set to $PGRESTORE_LIST and has been added to the pg_restore options"
fi

if [[ ! -z "$PGRESTORE_LISTFILE" ]]; then
	opts+=" --use-list=$PGRESTORE_LISTFILE"
  echo "PGRESTORE_LISTFILE is set to $PGRESTORE_LISTFILE and has been added to the pg_restore options"
fi

if [[ ! -z "$PGRESTORE_NODATAFORFAILEDTABLES" && $PGRESTORE_NODATAFORFAILEDTABLES == "true" ]]; then
	opts+=" --no-data-for-failed-tables"
  echo "PGRESTORE_NODATAFORFAILEDTABLES is set to $PGRESTORE_NODATAFORFAILEDTABLES and has been added to the pg_restore options"
fi

if [[ ! -z "$PGRESTORE_NOOWNER" && $PGRESTORE_NOOWNER == "true" ]]; then
	opts+=" --noowner"
  echo "PGRESTORE_NOOWNER is set to $PGRESTORE_NOOWNER and has been added to the pg_restore options"
fi

if [[ ! -z "$PGRESTORE_NOTABLESPACES" && $PGRESTORE_NOTABLESPACES == "true" ]]; then
	opts+=" --no-tablespaces"
  echo "PGRESTORE_NOTABLESPACES is set to $PGRESTORE_NOTABLESPACES and has been added to the pg_restore options"
fi

if [[ ! -z "$PGRESTORE_NUMJOBS" ]]; then
	opts+=" --jobs=$PGRESTORE_NUMJOBS"
  echo "PGRESTORE_NUMJOBS is set to $PGRESTORE_NUMJOBS and has been added to the pg_restore options"
fi

if [[ ! -z "$PGRESTORE_SCHEMA" ]]; then
	opts+=" --schema=$PGRESTORE_SCHEMA"
  echo "PGRESTORE_SCHEMA is set to $PGRESTORE_SCHEMA and has been added to the pg_restore options"
fi

if [[ ! -z "$PGRESTORE_SCHEMAONLY" && $PGRESTORE_SCHEMAONLY == "true" ]]; then
	opts+=" --schema-only"
  echo "PGRESTORE_SCHEMAONLY is set to $PGRESTORE_SCHEMAONLY and has been added to the pg_restore options"
fi

if [[ ! -z "$PGRESTORE_SUPERUSER" ]]; then
	opts+=" --superuser=$PGRESTORE_SUPERUSER"
  echo "PGRESTORE_SUPERUSER is set to $PGRESTORE_SUPERUSER and has been added to the pg_restore options"
fi

if [[ ! -z "$PGRESTORE_TABLE" ]]; then
	opts+=" --table=$PGRESTORE_TABLE"
  echo "PGRESTORE_TABLE is set to $PGRESTORE_TABLE and has been added to the pg_restore options"
fi

if [[ ! -z "$PGRESTORE_TRIGGER" ]]; then
	opts+=" --trigger=$PGRESTORE_TRIGGER"
  echo "PGRESTORE_TRIGGER is set to $PGRESTORE_TRIGGER and has been added to the pg_restore options"
fi

if [[ ! -z "$PGRESTORE_USESESSIONAUTH" && $PGRESTORE_USESESSIONAUTH == "true" ]]; then
	opts+=" --use-set-session-authorization"
  echo "PGRESTORE_USESESSIONAUTH is set to $PGRESTORE_USESESSIONAUTH and has been added to the pg_restore options"
fi

if [[ ! -z "$PGRESTORE_VERBOSE" && $PGRESTORE_VERBOSE == "true" ]]; then
	opts+=" --verbose"
  echo "PGRESTORE_VERBOSE is set to $PGRESTORE_VERBOSE and has been added to the pg_restore options"
fi

if [[ ! -z "$PGRESTORE_VERSION" && $PGRESTORE_VERSION == "true" ]]; then
	opts+=" --version"
  echo "PGRESTORE_VERSION is set to $PGRESTORE_VERSION and has been added to the pg_restore options"
fi

echo "pg_restore opts: $opts"

export PGPASSFILE=/tmp/pgpass

echo "*:*:*:""$PGRESTORE_USER:$PGRESTORE_PASS"  >> $PGPASSFILE

chmod 600 $PGPASSFILE

chown $UID:$UID $PGPASSFILE

# cat $PGPASSFILE

# If file is plain text format, use PSQL instead of PG_RESTORE
if [[ ! -z "$USE_PSQL" && "$USE_PSQL" == "true" ]]; then
  psql --host=$PGRESTORE_HOST --port=$PGRESTORE_PORT --username $PGRESTORE_USER -w $opts --file=$PGRESTORE_FULLPATH
else
  pg_restore --host=$PGRESTORE_HOST --port=$PGRESTORE_PORT --username $PGRESTORE_USER -w $opts $PGRESTORE_FULLPATH
fi
