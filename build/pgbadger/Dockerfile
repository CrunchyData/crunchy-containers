ARG BASEOS
ARG BASEVER
ARG PG_FULL
ARG PREFIX
FROM golang:1.15.5 as badgerserver-build
WORKDIR /go/src/github.com/crunchydata/crunchy-containers
COPY ./badger ./badger
RUN CGO_ENABLED=0 GOOS=linux go build -a -o badgerserver ./badger

FROM ${PREFIX}/crunchy-base:${BASEOS}-${PG_FULL}-${BASEVER}

# For RHEL8 all arguments used in main code has to be specified after FROM
ARG BASEOS
ARG DFSET
ARG PACKAGER

ARG PG_MAJOR

LABEL name="pgbadger" \
	summary="HTTP wrapper around the PGBadger PostgreSQL utility" \
	description="Has an HTTP REST interface. You GET http://host:10000/api/badgergenerate, and it will generate a pgbadger report on a database container's log files." \
	io.k8s.description="pgBadger" \
	io.k8s.display-name="pgBadger" \
	io.openshift.tags="postgresql,postgres,monitoring,pgbadger,database,crunchy"

RUN if [ "$DFSET" = "centos" ] ; then \
       ${PACKAGER} -y install --nodocs \
                --enablerepo="epel" \
                --setopt=skip_missing_names_on_install=False \
                pgbadger \
        && ${PACKAGER} -y clean all ; \
fi

RUN if [ "$BASEOS" = "ubi8" ] ; then \
       ${PACKAGER} -y install --nodocs \
                --enablerepo="epel" \
                shadow-utils \
                pgbadger \
        && ${PACKAGER} -y clean all ; \
fi

# Preserving PGVERSION out of paranoia
ENV PGVERSION="${PGMAJOR}"

RUN groupadd -g 26 postgres && useradd -g 26 -u 26 postgres

RUN mkdir -p /opt/crunchy/bin /opt/crunchy/conf /report

COPY --from=badgerserver-build \
	/go/src/github.com/crunchydata/crunchy-containers/badgerserver \
	/opt/crunchy/bin
COPY conf/pgbadger /opt/crunchy/conf
COPY bin/common /opt/crunchy/bin
COPY bin/pgbadger /opt/crunchy/bin

RUN chown -R postgres:postgres /opt/crunchy /report /bin && \
	chmod -R g=u /opt/crunchy /report /bin

# pgbadger port
EXPOSE 10000

# The VOLUME directive must appear after all RUN directives to ensure the proper
# volume permissions are applied when building the image
VOLUME ["/pgdata", "/report"]

# Defines a unique directory name that will be utilized by the nss_wrapper in the UID script
ENV NSS_WRAPPER_SUBDIR="pgbadger"

ENTRYPOINT ["opt/crunchy/bin/uid_postgres.sh"]

USER 26

CMD ["/opt/crunchy/bin/start-pgbadger.sh"]
