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

RUN if [ "$DFSET" = "centos" ] ; then \
	${PACKAGER} -y install --nodocs \
		--setopt=skip_missing_names_on_install=False \
		--enablerepo="powertools" \
		perl \
	&& ${PACKAGER} -y clean all ; \
fi

RUN if [ "$DFSET" = "rhel" ] ; then \
	${PACKAGER} -y --enablerepo="epel" --enablerepo="codeready-builder-for-rhel-8-x86_64-rpms" --nodocs install libaec libdap armadillo \
	&& ${PACKAGER} -y install --nodocs \
		--enablerepo="epel" \
		hdf5 \
		openldap \
		perl \
	&& ${PACKAGER} -y clean all --enablerepo="epel" --enablerepo="codeready-builder-for-rhel-8-x86_64-rpms" ; \
fi
