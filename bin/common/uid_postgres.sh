#!/bin/sh
if ! whoami &> /dev/null; then
  if [ -w /etc/passwd ]; then
    echo "${USER_NAME:-postgres}:x:$(id -u):0:${USER_NAME:-postgres} user:${HOME}:/bin/bash" >> /etc/passwd
  fi
fi
exec "$@"
