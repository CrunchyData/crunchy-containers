FROM registry.access.redhat.com/rhel7

MAINTAINER Crunchy Data <info@crunchydata.com>

LABEL name="crunchydata/pgdump" \
        vendor="crunchy data" \
	PostgresVersion="9.5" \
	PostgresFullVersion="9.5.17" \
	Version="7.6" \
	Release="2.4.0" \
        url="https://crunchydata.com" \
        summary="Performs a pg_dump on a database container" \
        description="Meant to be executed upon demand, this container will run pg_dump against a running database container and write the backup files to a mounted directory." \
        run="" \
        start="" \
        stop="" \
        io.k8s.description="pgdump container" \
        io.k8s.display-name="Crunchy pgdump container" \
        io.openshift.expose-services="" \
        io.openshift.tags="crunchy,database"

COPY conf/atomic/pgdump/help.1 /help.1
COPY conf/atomic/pgdump/help.md /help.md
COPY conf/licenses /licenses

ENV PGVERSION="9.5"

# PGDG Postgres repo
#RUN rpm -Uvh http://yum.postgresql.org/9.5/redhat/rhel-7-x86_64/pgdg-redhat95-9.5-3.noarch.rpm

# Crunchy Postgres repo
ADD conf/CRUNCHY-GPG-KEY.public  /
ADD conf/crunchypg95.repo /etc/yum.repos.d/
RUN rpm --import CRUNCHY-GPG-KEY.public

RUN rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
 && yum -y --enablerepo=rhel-7-server-ose-3.11-rpms --disablerepo=crunchy* update \
 && yum install -y bind-utils \
    gettext \
    hostname \
    procps-ng \
    unzip \
 && yum -y install postgresql95 postgresql95-server \
 && yum clean all -y

RUN mkdir -p /opt/cpm/bin /opt/cpm/conf /pgdata
ADD bin/pgdump/ /opt/cpm/bin
ADD bin/common /opt/cpm/bin
ADD conf/pgdump/ /opt/cpm/conf

RUN chgrp -R 0 /opt/cpm /pgdata && \
    chmod -R g=u /opt/cpm /pgdata 

VOLUME ["/pgdata"]

RUN chmod g=u /etc/passwd && \
	chmod g=u /etc/group
	
ENTRYPOINT ["opt/cpm/bin/uid_postgres.sh"]

USER 26

CMD ["/opt/cpm/bin/start.sh"]
