#!/bin/bash

if ! whoami &> /dev/null
then
    if [[ -w /etc/passwd ]]
    then
        sed  "/crunchyadm:x:17:/d" /etc/passwd >> /tmp/uid.tmp
        cp /tmp/uid.tmp /etc/passwd
        rm -f /tmp/uid.tmp
        echo "${USER_NAME:-crunchyadm}:x:$(id -u):0:${USER_NAME:-crunchyadm} user:${HOME}:/bin/bash" >> /etc/passwd
    fi

    if [[ -w /etc/group ]]
    then
        sed  "/crunchyadm:x:17/d" /etc/group >> /tmp/gid.tmp
        cp /tmp/gid.tmp /etc/group
        rm -f /tmp/gid.tmp
        echo "nfsnobody:x:65534:" >> /etc/group
        echo "crunchyadm:x:$(id -g):crunchyadm" >> /etc/group
    fi
fi
exec $@
