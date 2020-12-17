ARG BASEOS
ARG BASEVER
ARG PG_FULL
ARG PREFIX
FROM ${PREFIX}/crunchy-base:${BASEOS}-${PG_FULL}-${BASEVER}

# For RHEL8 all arguments used in main code has to be specified after FROM
ARG DFSET
ARG BASEOS
ARG PACKAGER
ARG PG_MAJOR

# Needed due to lack of environment substitution trick on ADD
ARG PG_LBL

LABEL name="admin" \
	summary="Administrative sidecar container for 'crunchy-postgres-ha'" \
	description="Sidecar container deployed alongside 'crunchy-postgres-ha' that can be utilized to perform administrative functions" \
	io.k8s.description="crunchyadm sidecar for crunchy-postgres-ha" \
	io.k8s.display-name="Crunchy admin sidecar container" \
	io.openshift.tags="postgresql,postgres,crunchy"

# Crunchy Postgres repo GPG Keys
# Both keys are added to support building all PG versions
# of this container. PG 11+ requires RPM-GPG-KEY-crunchydata
# PG 9.5, 9.6 and 10 require CRUNCHY-GPG-KEY.public on RHEL machines
ADD conf/*KEY* /

# Add any available Crunchy PG repo files
ADD conf/crunchypg${PG_LBL}.repo /etc/yum.repos.d/
# Import both keys to support all required repos
RUN rpm --import RPM-GPG-KEY-crunchydata*
RUN if [ "$DFSET" = "rhel" ] ; then rpm --import CRUNCHY-GPG-KEY.public ; fi

RUN if [ "$BASEOS" = "centos8" ] ; then \
	${PACKAGER} -qy module disable postgresql ; \
fi

RUN if [ "$BASEOS" = "ubi8" ] ; then \
	${PACKAGER} -qy module disable postgresql ; \
fi

RUN ${PACKAGER} -y install \
		--setopt=skip_missing_names_on_install=False \
		--disablerepo=crunchypg* \
		--enablerepo="crunchypg${PG_LBL}" \
		postgresql${PG_LBL} \
	&& ${PACKAGER} -y clean all

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
