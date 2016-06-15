
### Openshift Secrets Example
This example shows how the Openshift secrets functionality can
be used to store and keep secret a set of postgres user id and passwords.

This example lets the user decide what passwords they want to use
instead of using system generated passwords as done in the other
examples.

This set of instructions was tested on the binary version of
Origin 1.1.1 on centos 7.

To run the example, first create a set of secrets that hold the
various postgres user ID and passwords used in the examples:
~~~~~~~~~~~
oc secrets new-basicauth pgroot --username=postgres --password=postgrespsw
oc secrets new-basicauth pgmaster --username=master --password=masterpsw
oc secrets new-basicauth pguser --username=testuser --password=somepassword
~~~~~~~~~~~

### Example 1 - pg-standlone-secret

This example is modeled after the pg-standalone example.  In this
version of the example, database credentials are pulled from secrets
which are mounted as volumes within the container.

These secrets are used by the pg-standalone-secret pod to use
as the postgres authentication strings.  Create the example pod
as follows:
~~~~~~~~~~~
cd crunchy-postgresql-container-94/openshift
oc login
oc process -f standalone-secret.json | oc create -f -
~~~~~~~~~~~

You should have a secret, running pod, and service:
~~~~~~~~~~~
oc get pods
oc get services
oc get secrets
~~~~~~~~~~~

Test the container by logging into the postgresql database:
~~~~~~~~~
psql -h serviceIP -U testuser userdb
~~~~~~~~~

### Example 2 - pg-master-slave-rc-secret.json

This example is modeled after the pg-master-slave-rc.json example but
uses secrets to obtain the database credentials.

To run the example:
~~~~~~~~~~~~~~~~
oc process -f master-slave-rc-secret.json | oc create -f -
~~~~~~~~~~~~~~~~
