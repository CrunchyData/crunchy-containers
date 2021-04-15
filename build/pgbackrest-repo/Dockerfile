ARG BASEOS
ARG BASEVER
ARG PG_FULL
ARG PREFIX
FROM ${PREFIX}/crunchy-pgbackrest:${BASEOS}-${PG_FULL}-${BASEVER}

LABEL name="pgbackrest-repo" \
	summary="Crunchy pgBackRest-repo" \
	description="Capable of mounting the /backrestrepo for access to pgbackrest archives, while allowing for the configuration of pgBackRest using applicable pgBackRest environment variables." \
	io.k8s.description="pgBackRest-repo" \
	io.k8s.display-name="Crunchy pgBackRest-repo" \
	io.openshift.tags="postgresql,postgres,pgbackrest,backup,database,crunchy"

# run the following at root user
USER 0

RUN if [ "$BASEOS" = "ubi8" ] ; then \
        ${PACKAGER} -y install  \
                shadow-utils \
                && ${PACKAGER} -y clean all ; \
fi

# add pgbackrest user and group
RUN groupadd pgbackrest -g 2000 && useradd pgbackrest -u 2000 -g 2000

# set ownership and permissions for pgbackrest user and group
RUN chown -R pgbackrest:pgbackrest /opt/crunchy \
	&& chown -R pgbackrest:root /etc/pgbackrest

# add pgbackrest user and group script
ADD bin/pgbackrest-repo/uid_pgbackrest.sh /opt/crunchy/bin

# set permissions for pgbackrest user
RUN chmod -R g=u /etc/pgbackrest \
	&& rm -f /run/nologin

# set ownership to pgbackrest user
RUN chown pgbackrest:pgbackrest /.ssh && chmod o+rwx /.ssh

# set user to pgbackrest user
USER 2000

# Defines a unique directory name that will be utilized by the nss_wrapper in the UID script
ENV NSS_WRAPPER_SUBDIR="pgbackrest-repo"

ENTRYPOINT ["/opt/crunchy/bin/uid_pgbackrest.sh"]

CMD ["pgbackrest-repo.sh"]
