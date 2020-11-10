ARG BASEOS
ARG BASEVER
ARG PG_FULL
ARG PG_MAJOR
ARG PREFIX
FROM ${PREFIX}/crunchy-base:${BASEOS}-${PG_FULL}-${BASEVER}

# For RHEL8 all arguments used in main code has to be specified after FROM
ARG DFSET
ARG PACKAGER
ARG PG_MAJOR
ARG BACKREST_VER

LABEL name="pgbackrest" \
	summary="Crunchy Containers - pgBackRest" \
	description="The Crunchy pgBackRest container that supports pgBackRest backups, restores and repo functionality modes." \
	io.k8s.description="pgBackRest" \
	io.k8s.display-name="Crunchy pgBackRest" \
	io.openshift.tags="postgresql,postgres,pgbackrest,backup,database,crunchy"


# Crunchy PostgreSQL repository configuration
ADD conf/RPM-GPG-KEY-crunchydata* /
ADD conf/crunchypg${PG_MAJOR}.repo /etc/yum.repos.d/

# Import both keys to support all required repos
RUN rpm --import RPM-GPG-KEY-crunchydata*

# Run postgres install in separate transaction ahead of backrest for postgres user
RUN ${PACKAGER} -y install  \
	--setopt=skip_missing_names_on_install=False \
	#--enablerepo="epel" \
	#nss_wrapper \
	#hostname \
	openssh-clients \
	openssh-server \
	#procps-ng \
	#psmisc \
	#rsync \
	#postgresql${PG_MAJOR_VERSION//.}-server \
	crunchy-backrest-${BACKREST_VER} \
	&& ${PACKAGER} -y clean all


# add postgres user and group
RUN groupadd postgres -g 26 && useradd postgres -u 26 -g 26

# add path settings for postgres user
#ADD conf/.bash_profile /var/lib/pgsql/

# set up crunchy directory
RUN mkdir -p /opt/crunchy/bin /opt/crunchy/conf /pgdata /backrestrepo \
	/var/log/pgbackrest

# add pgbackrest-restore files
ADD bin/pgbackrest-restore /opt/crunchy/bin
ADD conf/pgbackrest-restore /opt/crunchy/conf

# add pgbackrest files
ADD bin/pgbackrest/ /opt/crunchy/bin
ADD bin/uid_postgres.sh /opt/crunchy/bin

# add pgbackrest-common files
ADD bin/common/ /opt/crunchy/bin
ADD bin/pgbackrest-common/ /opt/crunchy/bin

# set user and group ownership
RUN chown -R postgres:postgres /opt/crunchy  \
	/backrestrepo /var/log/pgbackrest /pgdata

# add the pgbackrest-repo specific files and directories, and
# set the appropriate permissions and ownership
ADD bin/pgbackrest-repo /usr/local/bin
RUN chmod +x /usr/local/bin/pgbackrest-repo.sh /usr/local/bin/archive-push-s3.sh \
	&& mkdir -p /etc/pgbackrest \
	&& chown -R postgres:postgres /etc/pgbackrest

RUN chmod g=u /etc/passwd \
	&& chmod g=u /etc/group \
	&& chmod -R g=u /etc/pgbackrest \
	&& rm -f /run/nologin

RUN mkdir /.ssh && chown postgres:postgres /.ssh && chmod o+rwx /.ssh

# create necessary volumes for all modes
#
# /sshd and /backrestrepo required for the pgBackRest repo mode
# /pgdata required for the pgbackrest-restore mode
#
# The VOLUME directive must appear after all RUN directives to ensure the proper
# volume permissions are applied when building the image
VOLUME ["/sshd", "/pgdata", "/backrestrepo"]

USER 26

ENTRYPOINT ["/opt/crunchy/bin/uid_postgres.sh"]

CMD ["/opt/crunchy/bin/start.sh"]
