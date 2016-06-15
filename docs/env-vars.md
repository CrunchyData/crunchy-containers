
### Postgresql Tuning Environment Variables

The following examples demonstrate how to adjust the
Postgresql configuration for some selective tuning parameters:
~~~~
standalone-pg-env-vars.json
master-slave-rc-pg-env-vars.json
~~~~

You can adjust the following Postgresql configuration parameters
by setting environment variables in the Openshift templates:
~~~~~~~
MAX_CONNECTIONS - defaults to 100
SHARED_BUFFERS - defaults to 128MB
TEMP_BUFFERS - defaults to 8MB
WORK_MEM - defaults to 4MB
MAX_WAL_SENDERS - defaults to 6
~~~~~~~

If you do not specify these environment variables the defaults will
be taken.

