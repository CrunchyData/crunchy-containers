FROM centos:7

LABEL name="crunchydata/sample-app" \
	vendor="crunchy data" \
	Version="7.6" \
	Release="2.4.0" \
	url="https://crunchydata.com" \
	summary="Implements a cron scheduler." \
	description="Sample application to connect to PostgreSQL containers" \
	io.k8s.description="Sample App container" \
	io.k8s.display-name="Crunchy Sample App container" \
	io.openshift.expose-services="" \
	io.openshift.tags="crunchy,database"

ENV PGVERSION="11" PGDG_REPO="pgdg-redhat-repo-latest.noarch.rpm"

RUN rpm -Uvh https://download.postgresql.org/pub/repos/yum/${PGVERSION}/redhat/rhel-7-x86_64/${PGDG_REPO}

RUN yum -y update \
 && yum -y install epel-release \
 && yum -y install \
      bind-utils \
      gettext \
      hostname \
      iproute \
      procps-ng \
      psmisc \
 && yum -y install postgresql10 \
 && yum clean all -y

RUN mkdir -p /opt/cpm/bin /opt/cpm/conf

ADD bin/sample-app /opt/cpm/bin
ADD bin/common /opt/cpm/bin
ADD conf/sample-app /opt/cpm/conf

RUN chgrp -R 0 /opt/cpm  && \
    chmod -R g=u /opt/cpm

EXPOSE 8000

RUN chmod g=u /etc/passwd
ENTRYPOINT ["opt/cpm/bin/uid_daemon.sh"]

USER 2

CMD ["/opt/cpm/bin/start.sh"]
