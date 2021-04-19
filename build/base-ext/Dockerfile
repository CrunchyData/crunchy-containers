ARG BASEOS
ARG BASEVER
ARG PG_FULL
ARG PREFIX
FROM ${PREFIX}/crunchy-base:${BASEOS}-${PG_FULL}-${BASEVER}

# For RHEL8 all arguments used in main code has to be specified after FROM
ARG BASEOS
ARG PACKAGER

LABEL name="crunchy-base-ext" \
	summary="Includes base extensions required to load in additional PostgreSQL extensions." \
	description="Includes base extensions required to load in additional PostgreSQL extensions."

RUN if [ "$BASEOS" = "centos7" ] ; then \
	${PACKAGER} -y install \
		--setopt=skip_missing_names_on_install=False \
		perl \
	&& ${PACKAGER} -y clean all ; \
fi

RUN if [ "$BASEOS" = "centos8" ] ; then \
	${PACKAGER} -y install \
		--setopt=skip_missing_names_on_install=False \
		--enablerepo="powertools" \
		perl \
	&& ${PACKAGER} -y clean all ; \
fi

RUN if [ "$BASEOS" = "ubi7" ] ; then \
	${PACKAGER} -y install \
		--enablerepo="epel,rhel-7-server-optional-rpms" \
		--setopt=skip_missing_names_on_install=False \
		perl \
	&& ${PACKAGER} -y clean all --enablerepo="epel,rhel-7-server-optional-rpms" ; \
fi

RUN if [ "$BASEOS" = "ubi8" ] ; then \
	${PACKAGER} -y --enablerepo="epel" --enablerepo="codeready-builder-for-rhel-8-x86_64-rpms" install libaec libdap armadillo \
	&& ${PACKAGER} -y install \
		--enablerepo="epel" \
		hdf5 \
		openldap \
		perl \
	&& ${PACKAGER} -y clean all --enablerepo="epel" --enablerepo="codeready-builder-for-rhel-8-x86_64-rpms" ; \
fi
