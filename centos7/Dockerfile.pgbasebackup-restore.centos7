FROM centos:7

LABEL name="crunchydata/pgbasebackup-restore" \
        vendor="crunchy data" \
	Version="7.6" \
	Release="2.4.0" \
        url="https://crunchydata.com" \
        summary="Restores a database using a pg_basebackup backup" \
        description="Restores a database into a specified PGDATA directory using a pg_basebackup backup, while also preparing for PITR if a recovery target is specified." \
        io.k8s.description="pg_basebackup restore container" \
        io.k8s.display-name="Crunchy pg_basebackup restore container" \
        io.openshift.expose-services="" \
        io.openshift.tags="crunchy,database"

RUN yum -y update \
 && yum -y install rsync  \
 && yum -y clean all

RUN groupadd postgres -g 26 \
 &&  useradd postgres -g 26 -u 26

RUN mkdir -p /opt/cpm/bin /opt/cpm/conf /pgdata

RUN chown -R postgres:postgres /opt/cpm /pgdata

VOLUME ["/backup","/pgdata"]

ADD bin/pgbasebackup_restore /opt/cpm/bin
ADD bin/common /opt/cpm/bin
ADD conf/pgbasebackup_restore /opt/cpm/conf

RUN chmod g=u /etc/passwd \
 && chmod g=u /etc/group

ENTRYPOINT ["/opt/cpm/bin/uid_postgres.sh"]

USER 26

CMD ["/opt/cpm/bin/start.sh"]
