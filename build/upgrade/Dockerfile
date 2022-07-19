ARG BASEOS
ARG BASEVER
ARG PG_FULL
ARG PREFIX
FROM ${PREFIX}/crunchy-base:${BASEOS}-${PG_FULL}-${BASEVER}

# For RHEL8 all arguments used in main code has to be specified after FROM
ARG BASEOS
ARG DFSET
ARG PACKAGER
ARG PG_MAJOR
ARG UPGRADE_PG_VERSIONS

LABEL name="upgrade" \
	summary="Provides a pg_upgrade capability that performs a major PostgreSQL upgrade." \
	description="Provides a means to perform a major PostgreSQL upgrade from an earlier version to PostgreSQL ${PG_MAJOR}." \
	io.k8s.description="postgres upgrade container" \
	io.k8s.display-name="Crunchy PostgreSQL upgrade container" \
	io.openshift.tags="postgresql,postgres,upgrade,database,crunchy"

# Add in the repository files with the correct PostgreSQL versions
ADD conf/crunchypg*.repo /etc/yum.repos.d/

# install the highest version of PostgreSQL + pgAudit and its dependencies as
# well as unzip
RUN if [ "$BASEOS" = "ubi8" ] ; then \
	${PACKAGER} -y install --nodocs \
		--disablerepo=crunchypg* \
		--enablerepo="crunchypg${PG_MAJOR//.}" \
		krb5-workstation \
		"postgresql${PG_MAJOR//.}" \
		"postgresql${PG_MAJOR//.}-contrib" \
		"postgresql${PG_MAJOR//.}-server" \
		"pgaudit${PG_MAJOR//.}*" \
		"pgnodemx${PG_MAJOR//.}" \
		"orafce_${PG_MAJOR//.}" \
		unzip \
		&& ${PACKAGER} -y clean all ; \
else \
	${PACKAGER} -y install --nodocs \
		--setopt=skip_missing_names_on_install=False \
		--disablerepo=crunchypg* \
		--enablerepo="crunchypg${PG_MAJOR//.}" \
		krb5-workstation \
		"postgresql${PG_MAJOR//.}" \
		"postgresql${PG_MAJOR//.}-contrib" \
		"postgresql${PG_MAJOR//.}-server" \
		"pgaudit${PG_MAJOR//.}*" \
		"pgnodemx${PG_MAJOR//.}" \
		"orafce_${PG_MAJOR//.}" \
		unzip \
		&& ${PACKAGER} -y clean all ; \
fi

# add in all of the earlier version of PostgreSQL. It will install the version
# above, but the dependencies are handled
RUN for pg_version in $UPGRADE_PG_VERSIONS; do \
        if [ "$BASEOS" = "ubi8" ] ; then \
            ${PACKAGER} -y install --nodocs \
                --disablerepo=* \
                --enablerepo=crunchypg* \
                postgresql${pg_version} \
                postgresql${pg_version}-contrib \
                postgresql${pg_version}-server \
                pgaudit${pg_version} \
                pgnodemx${pg_version} \
				orafce_${pg_version} ; \
        else \
            ${PACKAGER} -y install --nodocs \
                --setopt=skip_missing_names_on_install=False \
                --disablerepo=* \
                --enablerepo=crunchypg* \
                postgresql${pg_version} \
                postgresql${pg_version}-contrib \
                postgresql${pg_version}-server \
                pgaudit${pg_version} \
                pgnodemx${pg_version} \
				orafce_${pg_version} ; \
        fi \
	done && ${PACKAGER} -y clean all ;

RUN mkdir -p /opt/crunchy/bin /pgolddata /pgnewdata /opt/crunchy/conf
ADD bin/upgrade/ /opt/crunchy/bin
ADD bin/common /opt/crunchy/bin
ADD conf/upgrade/ /opt/crunchy/conf

RUN chown -R postgres:postgres /opt/crunchy /pgolddata /pgnewdata && \
	chmod -R g=u /opt/crunchy /pgolddata /pgnewdata

# The VOLUME directive must appear after all RUN directives to ensure the proper
# volume permissions are applied when building the image
VOLUME /pgolddata /pgnewdata

# Defines a unique directory name that will be utilized by the nss_wrapper in the UID script
ENV NSS_WRAPPER_SUBDIR="upgrade"

ENTRYPOINT ["opt/crunchy/bin/uid_postgres.sh"]

USER 26

CMD ["/opt/crunchy/bin/start.sh"]
