FROM centos:7

LABEL name="crunchydata/restore" \
        vendor="crunchy data" \
	PostgresVersion="9.5" \
      	PostgresFullRelease="9.5.13" \
	Version="7.6" \
	Release="2.4.0" \
        url="https://crunchydata.com" \
        summary="Performs a pg_restore on a database container" \
        description="Meant to be executed upon demand, this container will run pg_restore against a running database container and write the backup files to a mounted directory." \
        io.k8s.description="pgrestore container" \
        io.k8s.display-name="Crunchy pgrestore container" \
        io.openshift.expose-services="" \
        io.openshift.tags="crunchy,database"

ENV PGVERSION="9.5" PGDG_REPO="pgdg-redhat-repo-latest.noarch.rpm"

RUN rpm -Uvh https://download.postgresql.org/pub/repos/yum/${PGVERSION}/redhat/rhel-7-x86_64/${PGDG_REPO}

RUN yum -y update && yum install -y epel-release \
 && yum -y update glibc-common \
 && yum install -y bind-utils \
    gettext \
    hostname \
    procps-ng \
    unzip \
    file \
 && yum -y install postgresql95 postgresql95-server \
 && yum clean all -y

RUN mkdir -p /opt/cpm/bin /opt/cpm/conf /pgdata
ADD bin/pgrestore/ /opt/cpm/bin
ADD bin/common /opt/cpm/bin
ADD conf/pgrestore/ /opt/cpm/conf

RUN chown -R postgres:postgres /opt/cpm /pgdata && \
        chmod -R g=u /opt/cpm /pgdata

VOLUME ["/pgdata"]

RUN chmod g=u /etc/passwd && \
	chmod g=u /etc/group
	
ENTRYPOINT ["opt/cpm/bin/uid_postgres.sh"]

USER 26

CMD ["/opt/cpm/bin/start.sh"]
