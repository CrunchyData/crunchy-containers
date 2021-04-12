#!/bin/bash

# First grab the env vars set for PGBACKREST during node initialization
source /tmp/pgbackrest_env.sh


# Now override any pgBackRest environment variables as needed

# If a bootstrap repo type is specified in the 'replica-bootstrap-repo-type' file (assuming it
# exists), then use the value within it to override the PGBACKREST_REPO1_TYPE env var setting
# currently set within the environment.  This is needed in scenarios where it is necessary to 
# override the repo type for specific pgBackRest commands but want to leave the env var set as
# is within the environment.  
#
# For instance, when bootstrapping and fetching archives for a standby cluster, it is necessary
# to ensure only "s3" is utilized for pgBackRest 'restore' and 'archive-get' commands.  However, 
# when the cluster is no longer a standby, this override setting can be removed, and the original
# value for PGBACKREST_REPO1_TYPE can be used instead.  This effectively allows this setting to be
# changed dynamically without requiring a container restart to update the PGBACKREST_REPO1_TYPE env
# var.
if [[ -f /pgconf/replica-bootstrap-repo-type ]]
then
    replica_bootstrap_repo_type="$(cat /pgconf/replica-bootstrap-repo-type)"
    if [[ "${replica_bootstrap_repo_type}" != "" ]]
    then
        export PGBACKREST_REPO1_TYPE=${replica_bootstrap_repo_type}
    fi
fi

# for an S3 repo, if TLS verification is disabled, pass in the appropriate flag
# otherwise, leave the default behavior and verify the S3 server certificate
if [[ $PGBACKREST_REPO1_TYPE == "s3" && $PGHA_PGBACKREST_S3_VERIFY_TLS == "false" ]]
then
    export PGBACKREST_REPO1_S3_VERIFY_TLS="n"
fi
