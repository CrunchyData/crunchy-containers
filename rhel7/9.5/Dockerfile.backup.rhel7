FROM registry.access.redhat.com/rhel7

MAINTAINER Crunchy Data <info@crunchydata.com>

LABEL name="crunchydata/backup" \
        vendor="crunchy data" \
	PostgresVersion="9.5" \
      	PostgresFullRelease="9.5.13" \
	Version="7.6" \
	Release="2.4.0" \
        url="https://crunchydata.com" \
        summary="Performs a pg_basebackup full database backup on a database container" \
        description="Meant to be executed upon demand, this container will run pg_basebackup against a running database container and write the backup files to a mounted directory." \
        run="" \
        start="" \
        stop="" \
        io.k8s.description="backup container" \
        io.k8s.display-name="Crunchy backup container" \
        io.openshift.expose-services="" \
        io.openshift.tags="crunchy,database"

COPY conf/atomic/backup/help.1 /help.1
COPY conf/atomic/backup/help.md /help.md
COPY conf/licenses /licenses

ENV PGVERSION="9.5"

# PGDG Postgres repo
#RUN rpm -Uvh http://yum.postgresql.org/9.5/redhat/rhel-7-x86_64/pgdg-redhat95-9.5-3.noarch.rpm

# Crunchy Postgres repo
ADD conf/CRUNCHY-GPG-KEY.public  /
ADD conf/crunchypg95.repo /etc/yum.repos.d/
RUN rpm --import CRUNCHY-GPG-KEY.public

RUN rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

# install deps
RUN yum -y --enablerepo=rhel-7-server-ose-3.11-rpms --disablerepo=crunchy* update \
 && yum -y install gettext procps-ng \
  postgresql95-server  \
  postgresql95 \
  hostname bind-utils \
 && yum clean all -y

RUN mkdir -p /opt/cpm/bin /opt/cpm/conf /pgdata
ADD bin/backup/ /opt/cpm/bin
ADD bin/common /opt/cpm/bin
ADD conf/backup/ /opt/cpm/conf

RUN chown -R postgres:postgres  /opt/cpm /pgdata && \
        chmod -R g=u /opt/cpm /pgdata 

VOLUME ["/pgdata"]

RUN chmod g=u /etc/passwd && \
	chmod g=u /etc/group
	
ENTRYPOINT ["opt/cpm/bin/uid_postgres.sh"]

USER 26

CMD ["/opt/cpm/bin/start-backupjob.sh"]
