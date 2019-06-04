FROM registry.access.redhat.com/rhel7

MAINTAINER Crunchy Data <info@crunchydata.com>

LABEL name="crunchydata/postgres" \
        vendor="crunchy data" \
	PostgresVersion="9.5" \
	PostgresFullVersion="9.5.17" \
	Version="7.6" \
	Release="2.4.0" \
        url="https://crunchydata.com" \
	summary="PostgreSQL 9.5.17 (PGDG) on a RHEL7 base image" \
        description="Allows multiple deployment methods for PostgreSQL, including basic single primary, streaming replication with synchronous and asynchronous replicas, and stateful sets. Includes utilities for Auditing (pgaudit), statement tracking, and Backup / Restore (pgbackrest, pg_basebackup)." \
        run="" \
        start="" \
        stop="" \
        io.k8s.description="postgres container" \
        io.k8s.display-name="Crunchy postgres container" \
        io.openshift.expose-services="" \
        io.openshift.tags="crunchy,database"

COPY conf/atomic/postgres/help.1 /help.1
COPY conf/atomic/postgres/help.md /help.md
COPY conf/licenses /licenses

ENV PGVERSION="9.5" BACKREST_VERSION="2.13"

# PGDG Postgres repo
#RUN rpm -Uvh http://yum.postgresql.org/9.5/redhat/rhel-7-x86_64/pgdg-redhat95-9.5-3.noarch.rpm

# if you ever need to install package docs inside the container, uncomment
#RUN sed -i '/nodocs/d' /etc/yum.conf

# Crunchy Postgres repo
ADD conf/CRUNCHY-GPG-KEY.public  /
ADD conf/crunchypg95.repo /etc/yum.repos.d/
RUN rpm --import CRUNCHY-GPG-KEY.public

RUN rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
 && yum -y --enablerepo=rhel-7-server-ose-3.11-rpms --disablerepo=crunchy* update \
 && yum -y install bind-utils \
    gettext \
    hostname \
    procps-ng \
    rsync \
    psmisc openssh-server openssh-clients \
 && yum -y reinstall glibc-common \
 && yum -y install postgresql95 postgresql95-contrib postgresql95-server \
    pgaudit95 pgaudit95_set_user \
    crunchy-backrest-"${BACKREST_VERSION}" \
 && yum -y --setopt=tsflags='' install pgaudit_analyze \
 && yum -y clean all

# add path settings for postgres user
# bash_profile is loaded in login, but not with exec
# bashrc to set permissions in OCP when using exec
# HOME is / in OCP
ADD conf/.bash_profile /var/lib/pgsql/
ADD conf/.bashrc /var/lib/pgsql
ADD conf/.bash_profile /
ADD conf/.bashrc /

# set up cpm directory
RUN mkdir -p /opt/cpm/bin /opt/cpm/conf /pgdata /pgwal /pgconf /recover /backrestrepo

RUN chown -R postgres:postgres /opt/cpm /var/lib/pgsql \
    /pgdata /pgwal /pgconf /recover /backrestrepo &&  \
    chmod -R g=u /opt/cpm /var/lib/pgsql \
    /pgdata /pgwal /pgconf /recover /backrestrepo

# add volumes to allow override of pg_hba.conf and postgresql.conf
# add volumes to offer a restore feature
# add volumes to allow storage of postgres WAL segment files
# add volumes to locate WAL files to recover with
# add volumes for pgbackrest to write to

VOLUME ["/sshd", "/pgconf", "/pgdata", "/pgwal", "/recover", "/backrestrepo"]

# open up the postgres port
EXPOSE 5432

ADD bin/postgres /opt/cpm/bin
ADD bin/common /opt/cpm/bin
ADD conf/postgres /opt/cpm/conf
ADD tools/pgmonitor/exporter/postgres /opt/cpm/bin/modules

RUN chmod g=u /etc/passwd && \
	chmod g=u /etc/group

RUN mkdir /.ssh && chown 26:0 /.ssh && chmod g+rwx /.ssh

ENTRYPOINT ["/opt/cpm/bin/uid_postgres.sh"]


USER 26

CMD ["/opt/cpm/bin/start.sh"]
