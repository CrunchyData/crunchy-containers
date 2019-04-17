FROM centos:7

LABEL name="crunchydata/scheduler" \
    vendor="crunchy data" \
	Version="7.6" \
	Release="2.4.0" \
    url="https://crunchydata.com" \
    summary="Crunchy Scheduler is a cron-like microservice for scheduling automatic backups" \
    description="Crunchy Scheduler parses JSON configMaps with the label 'crunchy-scheduler=true' and transforms them into cron based tasks for automating pgBaseBackup and pgBackRest backups" \
    io.k8s.description="scheduler container" \
    io.k8s.display-name="Crunchy Scheduler container" \
    io.openshift.expose-services="" \
    io.openshift.tags="crunchy,database,cron"

RUN yum -y update \
 && yum -y install epel-release \
 && yum -y install \
      gettext \
      hostname  \
      nss_wrapper \
      procps-ng \
 && yum clean all -y

RUN mkdir -p /opt/cpm/bin /opt/cpm/conf /configs \
 && chown -R 2:2 /opt/cpm /configs

ADD bin/scheduler /opt/cpm/bin
ADD bin/common /opt/cpm/bin
ADD conf/scheduler /opt/cpm/conf

USER 2

CMD ["/opt/cpm/bin/start.sh"]
