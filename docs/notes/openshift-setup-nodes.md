
crunchy-pg Openshift Setup
==========================

The crunchy-pg container lets you run PostgreSQL in Openshift (v1.0.1)
as well as the normal Docker standalone container method.

In this example, I am assuming that you are running Openshift using the
Docker container version of Openshift.  I followed the installation 
openshift instructions found here:
~~~~~~~~~~~~~~~~~~~~~~
https://github.com/openshift/origin#getting-started
~~~~~~~~~~~~~~~~~~~~~~

The Openshift example that is described here will deploy
the following to your Openshift server:
*   pg-master service
*   pg-slave service
*   pg-master pod
*   pg-slave pod

The example makes use of hostPath volumes on the host that runs
the PostgreSQL containers (pods).

The 'hostDir' volume source requires you to predefine
on your Linux host, the data directories used by the 
pg-master and pg-slave containers.  Openshift will mount
these directories from your host to the Docker containers
running in your pods.

Define the PostgreSQL hostDir Data Directories
----------------------------------------------
A script is included to define some sample data directories
and set the permissions correctly.  They require you
to have PostgreSQL installed on your Linux host prior
to running the script.  The script also requires your
user have sudo privs.

IMPORTANT:  if you are going to test and retest using
the same container names, you will need to manually
remove all files from the previous database instance
each time you recreate the pods for this example.  If
you do not, postgres will fail in various ways thinking
that an old database is already present.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
git clone git@github.com:CrunchyData/crunchy-pg.git
cd crunchy-pg/openshift
source setup-data-dirs
sudo ls -l /host
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


Openshift Setup Steps
----------------------------

Origin requires some steps to make this example work.  Thanks
to Paul Morie (Redhat) for helping me get this working!

First, We need to run our Postgresql containers as the postgres
user.  By default, Origin locks down containers to run with 
a root UID and GID which is not what we want.  Postgres likes
to run as the postgres user which has a UID and GID of 26.  Typically
I install PostgreSQL upon the Origin host we are working on to provide
both PostgreSQL client utilities and also the predefined postgres
user account of UID 26.  This is used to set the permissions on the
data directories that we define for each PostgreSQL container
we instantiate.

Steps to make Origin run our containers as the postgres user
-------------------------------
You need to log into Origin as the 'admin' user.  This is done
as follows:

View your configuration of Origin contexts, to find the system admin
context:
~~~~~~~~~~~~~~~~~~~~~~~~~~
oc config view -o template -t "{{range .contexts}}{{.name}} {{end}}"
oc config use-context default/192-168-0-107:8443/system:admin
~~~~~~~~~~~~~~~~~~~~~~~~~~

Edit your security context settings as the admin user:
~~~~~~~~~~~~~~~~~~~~~~~~~~
oc edit scc restricted --config=/var/lib/openshift/openshift.local.config/master/admin.kubeconfig
~~~~~~~~~~~~~~~~~~~~~~~~~~

Specify the 'runAsUser' value as follows and save the editor session to make the
changes permanent:
~~~~~~~~~~~~~~~~~~~~~~~
runAsUser:
  type: RunAsAny
~~~~~~~~~~~~~~~~~~~~~~~

Also, add this line to your security context file:
~~~~~~~~~~~~~~~~~~~~~~~
allowHostDirVolumePlugin: true
~~~~~~~~~~~~~~~~~~~~~~~

Now, when you run the PostgreSQL containers, you should be running
as the postgres user and NOT the root user.

Test this out by entering the 'id' command when you are exec'd inside
your running pods (e.g. sudo docker exec -it <your container id> /bin/bash or
the equivalent 'oc exec' command):
~~~~~~~~~~~~~~
id
~~~~~~~~~~~~~~

The 'id' command will show your effective UID/GID you are running as.  It should
be 'postgres' user after making the changes above.

If things are working as expected you will see the postgres user as your ID.  This is
because the crunchy-pg container specifies a USER of postgres in its Dockerfile.

Sample Openshift Template
--------------------------

There is a sample openshift template provided in this git repo, called:
~~~~~~~~~~~~~~
pgrepl_master_slave.json
~~~~~~~~~~~~~~

Some interesting things to point out include how the hostPath volumes
are specified.

Within the template, we specify for each container
a hostPath volume as follows:

~~~~~~~~~~~~~~~~~~~~~~~
"volumeMounts": [{
"name": "pgdata",
"mountPath": "/pgdata",
"readOnly": false
}],
~~~~~~~~~~~~~~~~~~~~~~~

These refer to a volumes section in the template that looks like the following:
~~~~~~~~~~~~~~~~~~~~~~
"volumes": [ {
"name": "pgdata",
"hostPath": { "path": "/host/pg-master" }
} ]
~~~~~~~~~~~~~~~~~~~~~~

These configuration lines will provide to the container a predefined (on the host)
directory, set with the correct permissions, into which the container will
store the PostgreSQL data files.


Deploying to Openshift
----------------------

Copy the openshift sample template to your openshift container.  In this example,
I am assuming you are running openshift as a Docker container.

Inside your openshift container you will execute this command
to process the template and create the openshift objects:
~~~~~~~~~~~~~~~~~~~~~~~~~
oc process -f pgrepl_master_slave.json | oc create -f -
~~~~~~~~~~~~~~~~~~~~~~~~~

After about 30 seconds you will have a couple of running
pods.  You should see something similar to this:
~~~~~~~~~~~~~~~~~~~~~~~~~
[root@origin openshift]# oc get pods
NAME        READY     REASON    RESTARTS   AGE
pg-master   1/1       Running   0          1h
pg-slave    1/1       Running   0          1h
[root@origin openshift]# oc get services
NAME        LABELS           SELECTOR         IP(S)            PORT(S)
pg-master   name=pg-master   name=pg-master   172.30.204.5     5432/TCP
pg-slave    name=pg-slave    name=pg-slave    172.30.237.232   5432/TCP
~~~~~~~~~~~~~~~~~~~~~~~~~

If you look on the local linux host file system, you will see that
the data directories you created are now populated:
~~~~~~~~~~~~~~~~~~~~~~~~~
sudo ls /host/pg*

/host/pg-master:
base	     pg_hba.conf    pg_multixact  pg_snapshots	pg_tblspc    postgresql.auto.conf
global	     pg_ident.conf  pg_notify	  pg_stat	pg_twophase  postgresql.conf
pg_clog      pg_log	    pg_replslot   pg_stat_tmp	PG_VERSION   postmaster.opts
pg_dynshmem  pg_logical     pg_serial	  pg_subtrans	pg_xlog      postmaster.pid

/host/pg-slave:
backup_label.old  pg_dynshmem	 pg_logical    pg_serial     pg_subtrans  pg_xlog		postmaster.pid
base		  pg_hba.conf	 pg_multixact  pg_snapshots  pg_tblspc	  postgresql.auto.conf	recovery.conf
global		  pg_ident.conf  pg_notify     pg_stat	     pg_twophase  postgresql.conf
pg_clog		  pg_log	 pg_replslot   pg_stat_tmp   PG_VERSION   postmaster.opts
~~~~~~~~~~~~~~~~~~~~~~~~~


Testing the openshift deployment
--------------------------------

On your Linux host that is running openshift, you can now test out the running postgres pods as follows:
~~~~~~~~~~~~~~~~~~~~~~~~~~~
sudo docker ps | grep master
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Find the container ID of the master, and issue the following to log into the pg-master
container:

~~~~~~~~~~~~~~~~~~~~~~~~~
sudo docker exec -it <your container id> /bin/bash
psql -U postgres postgres
psql (9.4.4)
Type "help" for help.

postgres=# select * from pg_stat_replication;
   72 |    16384 | master  | walreceiver      | 172.17.42.1 |                 |       38316 | 2015-07-09 17:06:27.230672-04 |              | streaming | 0/3000060     | 0/3000060      | 0/3000060      | 0/3000060       |             0 | async
   (1 row)

   postgres=# create table foo (id int);
   CREATE TABLE
   postgres=# insert into foo values (2);
   INSERT 0 1
   postgres=# select * from foo;
~~~~~~~~~~~~~~~~~~~~~~~~~

In the above commands, you are connecting to the pg-master postgres database,
verifying that postgres replication is working by querying the pg_stat_replication
table, and then creating a test table adding a single row.

Now, lookup the pg-standby container, and log into that container.

If postgres replication is working, you should be able to log into postgres
and see the sample test table you created on the master.

~~~~~~~~~~~~~~~~~~~~~~~~~~
[jeffmc@origin openshift]$ sudo docker ps | grep slave
14caf0a48ce4        crunchydata/pgrepl:latest 
[jeffmc@origin openshift]$ sudo docker exec -it 14caf0a48ce4 /bin/bash
bash-4.2$ psql -U postgres postgres
psql (9.4.4)
Type "help" for help.

postgres=# select * from foo;
 id 
 ----
   2
   (1 row)

postgres=# 
~~~~~~~~~~~~~~~~~~~~~~~~~~

Testing DNS
--------------------------

So, this example depends upon the DNS in Openshift to be
working and configured on your linux host that is hosting openshift.

Make sure your local Linux host IP address is specified in the
/etc/resolv.conf and that you are resolving names using the Openshift
DNS server.

From your local linux host, you should be able to access the pg-slave
and pg-master containers via their openshift/kube services.

In this example, I am assuming that your openshift project is named
'pgproject'.  Notice the default DNS naming convention used by openshift:
~~~~~~~~~~~~~~~~~~~~~~~~
psql -h pg-master.pgproject.svc.cluster.local -U master userdb
psql -h pg-slave.pgproject.svc.cluster.local -U master userdb
~~~~~~~~~~~~~~~~~~~~~~~~

You will be prompted for a password when running the above commands.
You can find the password by inspecting the pg-master container
and looking for the environment variable named PG_MASTER_PASSWORD, copy
that value out and paste it when prompted for the password.

~~~~~~~~~~~~~~~~~~
sudo docker inspect 14caf0a48ce4
~~~~~~~~~~~~~~~~~~

By default, crunchy-pg creates a sample database called userdb and
grants permissions to a user called 'master'.

If you have made it this far, then you are likely in good shape and
have a working system.


