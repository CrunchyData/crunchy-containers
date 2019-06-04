FROM centos:7

LABEL name="crunchydata/upgrade" \
        vendor="crunchy data" \
	PostgresVersion="9.6" \
	PostgresFullVersion="9.6.13" \
	Version="7.6" \
	Release="2.4.0" \
        url="https://crunchydata.com" \
        summary="Provides a pg_upgrade capability that performs a major PostgreSQL upgrade." \
        description="Provides a means to perform a major PostgreSQL upgrade from 9.5 to 9.6. Old data files are left intact." \
        io.k8s.description="postgres upgrade container" \
        io.k8s.display-name="Crunchy postgres upgrade container" \
        io.openshift.expose-services="" \
        io.openshift.tags="crunchy,database"

ENV PGDG_96_REPO="pgdg-redhat-repo-latest.noarch.rpm"

RUN rpm -Uvh https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/${PGDG_96_REPO}

RUN yum -y update && yum install -y epel-release \
 && yum -y update glibc-common \
 && yum install -y bind-utils \
	gettext \
	hostname \
	procps-ng \
	unzip \
 && yum -y install \
 postgresql95 postgresql95-server postgresql95-contrib pgaudit_95 \
 postgresql96 postgresql96-server postgresql96-contrib pgaudit_96 \
 && yum clean all -y

RUN mkdir -p /opt/cpm/bin /pgolddata /pgnewdata /opt/cpm/conf
ADD bin/upgrade/ /opt/cpm/bin
ADD bin/common /opt/cpm/bin
ADD conf/upgrade/ /opt/cpm/conf

RUN chown -R postgres:postgres /opt/cpm /pgolddata /pgnewdata && \
        chmod -R g=u /opt/cpm /pgolddata /pgnewdata

VOLUME /pgolddata /pgnewdata

RUN chmod g=u /etc/passwd && \
	chmod g=u /etc/group
	
ENTRYPOINT ["opt/cpm/bin/uid_postgres.sh"]

USER 26

CMD ["/opt/cpm/bin/start.sh"]
