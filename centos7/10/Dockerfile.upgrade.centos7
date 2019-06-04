FROM centos:7

LABEL name="crunchydata/upgrade" \
        vendor="crunchy data" \
	PostgresVersion="10" \
	PostgresFullVersion="10.8" \
	Version="7.6" \
	Release="2.4.0" \
        url="https://crunchydata.com" \
        summary="Provides a pg_upgrade capability that performs a major PostgreSQL upgrade." \
        description="Provides a means to perform a major PostgreSQL upgrade from 9.5 to 9.6 or 9.6 to 10. Old data files are left intact." \
        io.k8s.description="postgres upgrade container" \
        io.k8s.display-name="Crunchy postgres upgrade container" \
        io.openshift.expose-services="" \
        io.openshift.tags="crunchy,database"

ENV PGDG_10_REPO="pgdg-redhat-repo-latest.noarch.rpm"

RUN rpm -Uvh https://download.postgresql.org/pub/repos/yum/10/redhat/rhel-7-x86_64/${PGDG_10_REPO}

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
 postgresql10 postgresql10-server postgresql10-contrib pgaudit12_10 \
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
