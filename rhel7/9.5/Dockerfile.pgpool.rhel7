FROM registry.access.redhat.com/rhel7

MAINTAINER Crunchy Data <info@crunchydata.com>

LABEL name="crunchydata/pgpool" \
	vendor="crunchy data" \
	PostgresVersion="9.5" \
	PostgresFullVersion="9.5.17" \
	Version="7.6" \
	Release="2.4.0" \
  url="https://crunchydata.com" \
  summary="Contains the pgpool utility as a PostgreSQL-aware load balancer" \
  description="Offers a smart load balancer in front of a Postgres cluster, sending writes only to the primary and reads to the replica(s). This allows an application to only have a single connection point when interacting with a Postgres cluster." \
  run="" \
  start="" \
  stop="" \
  io.k8s.description="pgpool container" \
  io.k8s.display-name="Crunchy pgpool container" \
  io.openshift.expose-services="" \
  io.openshift.tags="crunchy,database"

COPY conf/atomic/pgpool/help.1 /help.1
COPY conf/atomic/pgpool/help.md /help.md
COPY conf/licenses /licenses

ENV PGVERSION="9.5"

# PGDG Postgres repo
#RUN rpm -Uvh http://yum.postgresql.org/9.5/redhat/rhel-7-x86_64/pgdg-redhat95-9.5-3.noarch.rpm

# set up Crunchy repo
ADD conf/CRUNCHY-GPG-KEY.public  /
ADD conf/crunchypg95.repo /etc/yum.repos.d/
RUN rpm --import CRUNCHY-GPG-KEY.public

RUN rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

RUN yum -y --enablerepo=rhel-7-server-ose-3.11-rpms --disablerepo=crunchy* update \
 && yum -y install epel-release \
 && yum -y install \
      gettext \
      hostname \
      procps-ng \
 && yum -y install \
      postgresql95 \
      pgpool-II-95 \
      pgpool-II-95-extensions \
 && yum -y clean all

RUN mkdir -p /opt/cpm/bin /opt/cpm/conf

ADD bin/pgpool /opt/cpm/bin
ADD bin/common /opt/cpm/bin
ADD conf/pgpool /opt/cpm/conf

RUN ln -sf /opt/cpm/conf/pool_hba.conf /etc/pgpool-II-95/pool_hba.conf \
  && ln -sf /opt/cpm/conf/pgpool/pool_passwd /etc/pgpool-II-95/pool_passwd

RUN chgrp -R 0 /opt/cpm && \
    chmod -R g=u /opt/cpm


# open up the postgres port
EXPOSE 5432

# add volumes to allow override of pgpool config files
VOLUME ["/pgconf"]

RUN chmod g=u /etc/passwd
ENTRYPOINT ["opt/cpm/bin/uid_daemon.sh"]

USER 2

CMD ["/opt/cpm/bin/startpgpool.sh"]
