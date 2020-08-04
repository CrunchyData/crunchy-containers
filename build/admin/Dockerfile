ARG BASEOS
ARG BASEVER
ARG PG_FULL
ARG PREFIX
FROM ${PREFIX}/crunchy-pg-base:${BASEOS}-${PG_FULL}-${BASEVER}

# For RHEL8 all arguments used in main code has to be specified after FROM
ARG DFSET
ARG PACKAGER
ARG PG_MAJOR

LABEL name="admin" \
	summary="Administrative sidecar container for 'crunchy-postgres-ha'" \
	description="Sidecar container deployed alongside 'crunchy-postgres-ha' that can be utilized to perform administrative functions" \
	io.k8s.description="crunchyadm sidecar for crunchy-postgres-ha" \
	io.k8s.display-name="Crunchy admin sidecar container" \
	io.openshift.tags="postgresql,postgres,crunchy"

ENV PGROOT="/usr/pgsql-${PG_MAJOR}"
ENV PATH="${PGROOT}/bin:${PATH}"

ADD bin/crunchyadm /opt/cpm/bin
ADD bin/common /opt/cpm/bin

RUN chmod g=u /etc/passwd && \
	chmod g=u /etc/group

ENTRYPOINT ["/opt/cpm/bin/uid_crunchyadm.sh"]

# uid set in postgres-ha image build
USER 17

CMD ["tail -f /dev/null"]
