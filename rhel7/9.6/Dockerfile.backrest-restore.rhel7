FROM registry.access.redhat.com/rhel7

MAINTAINER Crunchy Data <info@crunchydata.com>

LABEL name="crunchydata/postgres" \
        vendor="crunchy data" \
	PostgresVersion="9.6" \
	PostgresFullVersion="9.6.13" \
	Version="7.6" \
	Release="2.4.0" \
        url="https://crunchydata.com" \
        summary="Executes the pgbackrest utility, allowing FULL & DELTA restore capability." \
        description="Executes pgbackrest utility, allowing FULL, DELTA & PITR restore capability. Capable of mounting the /backrestrepo for access to pgbackrest archives, while allowing for the configuration of pgbackrest using applicable pgbackrest environment variables." \
        run="" \
        start="" \
        stop="" \
        io.k8s.description="backrest restore container" \
        io.k8s.display-name="Crunchy backrest restore container" \
        io.openshift.expose-services="" \
        io.openshift.tags="crunchy,database"

COPY conf/atomic/backrestrestore/help.1 /help.1
COPY conf/atomic/backrestrestore/help.md /help.md
COPY conf/licenses /licenses

ENV PGVERSION="9.6" BACKREST_VERSION="2.13"

# Crunchy Postgres repo
ADD conf/CRUNCHY-GPG-KEY.public  /
ADD conf/crunchypg96.repo /etc/yum.repos.d/
RUN rpm --import CRUNCHY-GPG-KEY.public

RUN rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm  \
 && yum -y --enablerepo=rhel-7-server-ose-3.11-rpms --disablerepo=crunchy* update \
 && yum -y install  \
	hostname \
	gettext \
        nss_wrapper \
 	procps-ng  \
 && yum -y clean all

# Doing these separately so postgres user exists when crunchy-backrest is installed.
RUN yum -y install postgresql96-server &&  \
    yum -y install crunchy-backrest-"${BACKREST_VERSION}" \
 && yum -y clean all

ENV	PGROOT="/usr/pgsql-${PGVERSION}"

# add path settings for postgres user
ADD conf/.bash_profile /var/lib/pgsql/

# set up cpm directory
RUN mkdir -p /opt/cpm/bin /opt/cpm/conf /pgdata /backrestrepo \
	/var/lib/pgsql /var/log/pgbackrest

RUN chown -R postgres:postgres /opt/cpm  \
	/pgdata /backrestrepo  \
	/var/lib/pgsql /var/log/pgbackrest

#RUN chgrp -R 0 /opt/cpm  \
#	/pgdata /backrestrepo  \
#	/var/lib/pgsql /var/log/pgbackrest && \
#    chmod -R g=u /opt/cpm  \
#	/pgdata /backrestrepo  \
#	/var/lib/pgsql /var/log/pgbackrest

# volume backrestrepo for pgbackrest to restore from and log
VOLUME /pgdata /backrestrepo

ADD bin/backrest_restore /opt/cpm/bin

#removed to allow separate version of common_lib.sh for this container only. Its in
# the bin/backrest_restore directory.
#ADD bin/common /opt/cpm/bin

ADD conf/backrest_restore /opt/cpm/conf

# Removed to rely on nss_wrapper for now
#RUN chmod g=u /etc/passwd && \
#	chmod g=u /etc/group
#
#ENTRYPOINT ["opt/cpm/bin/uid_postgres.sh"]


USER 26
CMD ["/opt/cpm/bin/start.sh"]
