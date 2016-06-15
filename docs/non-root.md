
### Openshift Non-Root Example
This example shows how the Openshift security context can
be manipulated to allow a non-root container to run as 
a specific UID, that being, the postgres UID for this example.

Edit the scc restricted settings and change the runAsUser.Type to MustRunAsNonRoot
~~~~~~~~~~~
runAsUser:
  type: MustRunAsNonRoot
~~~~~~~~~~~

### Example 1 - pg-standlone-runasuser.json

This example is modeled after the pg-standalone example.  In this
version of the example, the pod security context specifies that
the pod UID should be 26 or that of the postgres user.

~~~~~~~~~~~
cd crunchy-postgresql-container-94/openshift
oc login
oc process -f standalone-runasuser.json | oc create -f -
~~~~~~~~~~~

Note:  if you try to run the normal standalone.json example with this
scc configuration, you will see that openshift will not allow the pod
to start due to the security configuration in place.  This is the
gist of this example to show how openshift can be locked down a bit
tighter with respect to security.

