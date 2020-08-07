ARG BASEOS
ARG BASEVER
ARG PG_FULL
ARG PREFIX
FROM ${PREFIX}/crunchy-pg-base:${BASEOS}-${PG_FULL}-${BASEVER}

# For RHEL8 all arguments used in main code has to be specified after FROM
ARG DFSET
ARG PACKAGER
ARG PG_MAJOR

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
RUN ${PACKAGER} -y install \
	--setopt=skip_missing_names_on_install=False \
	--disablerepo=crunchypg* \
	--enablerepo="crunchypg${PG_MAJOR//.}" \
	"postgresql${PG_MAJOR//.}" \
	"postgresql${PG_MAJOR//.}-contrib" \
	"postgresql${PG_MAJOR//.}-server" \
	"pgaudit${PG_MAJOR//.}*" \
	unzip \
	&& ${PACKAGER} -y clean all

# add in all of the earlier version of PostgreSQL. It will install the version
# above, but the dependencies are handled
RUN ${PACKAGER} -y install \
	--setopt=skip_missing_names_on_install=False \
	--disablerepo=* \
	--enablerepo=crunchypg* \
	postgresql[1-9][0-9] \
	postgresql[1-9][0-9]-contrib \
	postgresql[1-9][0-9]-server \
	pgaudit[1-9][0-9] \
	&& ${PACKAGER} -y clean all

RUN mkdir -p /opt/cpm/bin /pgolddata /pgnewdata /opt/cpm/conf
ADD bin/upgrade/ /opt/cpm/bin
ADD bin/common /opt/cpm/bin
ADD conf/upgrade/ /opt/cpm/conf

RUN chown -R postgres:postgres /opt/cpm /pgolddata /pgnewdata && \
	chmod -R g=u /opt/cpm /pgolddata /pgnewdata

RUN chmod g=u /etc/passwd && \
	chmod g=u /etc/group

# The VOLUME directive must appear after all RUN directives to ensure the proper
# volume permissions are applied when building the image
VOLUME /pgolddata /pgnewdata

ENTRYPOINT ["opt/cpm/bin/uid_postgres.sh"]

USER 26

CMD ["/opt/cpm/bin/start.sh"]
