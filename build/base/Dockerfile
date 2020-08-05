ARG BASEOS
ARG DOCKERBASEREGISTRY
FROM ${DOCKERBASEREGISTRY}${BASEOS}

# For RHEL8 all arguments used in main code has to be specified after FROM
ARG BASEOS
ARG RELVER
ARG DFSET
ARG PACKAGER

MAINTAINER Crunchy Data <info@crunchydata.com>

LABEL vendor="Crunchy Data" \
	url="https://crunchydata.com" \
	release="${RELVER}" \
	org.opencontainers.image.vendor="Crunchy Data" \
	os.version="7.7"

COPY conf/licenses /licenses
COPY redhat/atomic/help.1 /help.1
COPY redhat/atomic/help.md /help.md
COPY licenses /licenses

# Have to install glibc-langpack-en on UBI8 otherwise en_US.utf-8 does not exist
RUN if [ "$BASEOS" = "ubi8" ] ; then \
        echo "INSIDE UBI8" \
        ${PACKAGER} -y update \
        && ${PACKAGER} -y install \
                --setopt=skip_missing_names_on_install=False \
                glibc-langpack-en ; \
fi

ENV LC_ALL en_US.utf-8
ENV LANG en_US.utf-8

ARG EPEL7_RPM=https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
ARG EPEL8_RPM=https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

RUN if [ "$BASEOS" = "rhel7" ] ; then \
	${PACKAGER} -y --enablerepo=rhel-7-server-ose-3.11-rpms update \
	&& ${PACKAGER} -y install \
		--setopt=skip_missing_names_on_install=False \
		${EPEL7_RPM} \
		bind-utils \
		gettext \
		hostname \
		procps-ng \
	&& sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/epel*.repo \
	&& ${PACKAGER} -y clean all --enablerepo=rhel-7-server-ose-3.11-rpms ; \
fi

RUN if [ "$BASEOS" = "ubi7" ] ; then \
        ${PACKAGER} -y --enablerepo=rhel-7-server-ose-3.11-rpms update \
        && ${PACKAGER} -y install \
                --setopt=skip_missing_names_on_install=False \
                ${EPEL7_RPM} \
                bind-utils \
                gettext \
                hostname \
                procps-ng \
        && sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/epel*.repo \
        && ${PACKAGER} -y clean all --enablerepo=rhel-7-server-ose-3.11-rpms ; \
fi

RUN if [ "$BASEOS" = "ubi8" ] ; then \
        ${PACKAGER} -y update \
        && ${PACKAGER} -y install \
                --setopt=skip_missing_names_on_install=False \
                ${EPEL8_RPM} \
                bind-utils \
                gettext \
                hostname \
                procps-ng \
        && sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/epel*.repo \
        && ${PACKAGER} -y clean all ; \
fi

RUN if [ "$BASEOS" = "centos7" ] ; then \
        ${PACKAGER} -y update \
        && ${PACKAGER} -y install \
                --setopt=skip_missing_names_on_install=False \
                epel-release \
                bind-utils \
                gettext \
                hostname \
                procps-ng \
        && ${PACKAGER} -y clean all ; \
fi

RUN if [ "$BASEOS" = "centos8" ] ; then \
	${PACKAGER} -y update \
	&& ${PACKAGER} -y install \
		--setopt=skip_missing_names_on_install=False \
		epel-release \
		glibc-langpack-en \
		bind-utils \
		gettext \
		hostname \
		procps-ng \
	&& ${PACKAGER} -y clean all ; \
fi

