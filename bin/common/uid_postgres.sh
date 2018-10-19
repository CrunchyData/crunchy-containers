#!/bin/sh
if ! whoami &> /dev/null; then
  if [ -w /etc/passwd ]; then
    echo "${USER_NAME:-postgres}:x:$(id -u):26:${USER_NAME:-postgres} user:${HOME}:/bin/bash" >> /etc/passwd
  fi
  
  if [ -w /etc/group ]; then
    echo "nfsnobody:x:65534:" >> /etc/group
    echo "postgres:x:$(id -u):postgres" >> /etc/group
  fi
fi
exec "$@"
 