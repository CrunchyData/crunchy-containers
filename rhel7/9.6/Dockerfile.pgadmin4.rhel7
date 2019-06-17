FROM registry.access.redhat.com/rhel7

MAINTAINER Crunchy Data <info@crunchydata.com>

LABEL name="crunchydata/pgadmin4" \
        vendor="crunchy data" \
	PostgresVersion="9.6" \
	PostgresFullVersion="9.6.13" \
	Version="7.6" \
	Release="2.4.0" \
        url="https://crunchydata.com" \
        summary="Crunchy Data pgAdmin4 GUI utility" \
        description="Provides GUI for the pgAdmin utility." \
        run="" \
        start="" \
        stop="" \
        io.k8s.description="pgadmin4 container" \
        io.k8s.display-name="Crunchy pgadmin4 container" \
        io.openshift.expose-services="" \
        io.openshift.tags="crunchy,database"

COPY conf/atomic/pgadmin4/help.1 /help.1
COPY conf/atomic/pgadmin4/help.md /help.md
COPY conf/licenses /licenses

ENV PGVERSION="9.6"

# Crunchy Postgres repo
ADD conf/CRUNCHY-GPG-KEY.public  /
ADD conf/crunchypg96.repo /etc/yum.repos.d/
RUN rpm --import CRUNCHY-GPG-KEY.public

RUN rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

RUN yum -y --enablerepo=rhel-7-server-ose-3.11-rpms --disablerepo=crunchy* update \
 && yum -y install epel-release \
 && yum -y install \
	glibc-common \
	gcc \
	gettext \
	hostname \
	openssl \
	procps-ng \
	mod_wsgi mod_ssl \
 && yum --enablerepo rhel-7-server-extras-rpms -y install pgadmin4-web \
 && yum -y install postgresql96-devel postgresql96-server \
 && yum -y clean all

ENV PGROOT="/usr/pgsql-${PGVERSION}"

RUN mkdir -p /opt/cpm/bin /opt/cpm/conf /var/lib/pgadmin /certs /run/httpd

ADD bin/pgadmin4/ /opt/cpm/bin
ADD bin/common /opt/cpm/bin
ADD conf/pgadmin4/ /opt/cpm/conf

RUN cp /opt/cpm/conf/httpd.conf /etc/httpd/conf/httpd.conf \
  && rm /etc/httpd/conf.d/welcome.conf /etc/httpd/conf.d/ssl.conf

RUN chown -R 2:0 /usr/lib/python2.7/site-packages/pgadmin4-web \
   /var/lib/pgadmin /certs /etc/httpd /run/httpd /var/log/httpd && \
    chmod -R g=u /usr/lib/python2.7/site-packages/pgadmin4-web \
   /var/lib/pgadmin /certs /etc/httpd /run/httpd /var/log/httpd

RUN ln -sf /var/lib/pgadmin/config_local.py /usr/lib/python2.7/site-packages/pgadmin4-web/config_local.py \
  && ln -sf /var/lib/pgadmin/pgadmin.conf /etc/httpd/conf.d/pgadmin.conf

EXPOSE 5050

VOLUME ["/var/lib/pgadmin", "/certs", "/run/httpd"]

RUN chmod g=u /etc/passwd
ENTRYPOINT ["opt/cpm/bin/uid_daemon.sh"]

USER 2

CMD ["/opt/cpm/bin/start-pgadmin4.sh"]
