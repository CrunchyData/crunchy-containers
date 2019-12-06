= pgbasebackup-restore (1)
Crunchy Data
2019
== NAME
Crunchy pgbasebackup-restore - provides the ability to restore a database using a pg_basebackup backup.

== DESCRIPTION
The Crunchy pgbasebackup-restore container restores a database into a specified PGDATA directory using a pg_basebackup 
backup, while also preparing for a PITR if a recovery target is specified.

The container itself consists of:
    - RHEL7 base image
    - bash script that performs the container startup
    - rsync to restore the pg_basebackup backup

== USAGE
See the crunchy docs.

The Red Hat Enterprise Linux version from which the container was built. For example, Version="7.7"

`Release=`

The specific release number of the container. For example, Release="4.1.2"
