#!/bin/bash
# Start script for the compacted pgBackRest image
# Used to run correct start script based on MODE

CRUNCHY_DIR=${CRUNCHY_DIR:-'/opt/crunchy'}
source "${CRUNCHY_DIR}/bin/common_lib.sh"
enable_debugging

env_check_err "MODE"

echo_info "Image mode found: ${MODE}"

# sleep infinity

case $MODE in 
    pgbackrest)
      echo_info "Starting in 'pgbackrest' mode"

#      if [ "$COMMAND" == "backup" ]
#      then
#        echo_info "BACKUP command called...."
#        sleep infinity
#      fi

      "${CRUNCHY_DIR}/bin/pgbackrest"
      ;;
    pgbackrest-repo)
      echo_info "Starting in 'pgbackrest-repo' mode"
      /bin/bash "/usr/local/bin/pgbackrest-repo.sh"
      ;;
    pgbackrest-restore)
      echo_info "Starting in 'pgbackrest-restore' mode"
      /bin/bash "${CRUNCHY_DIR}/bin/pgbackrest-restore.sh"
      ;;
    *)
      echo_err "Invalid Image Mode; Please set the MODE environment variable to a supported mode"
      exit 1
      ;;
esac