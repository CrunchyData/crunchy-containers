ARG BASE_IMAGE_OS
ARG DOCKERBASEREGISTRY
FROM ${DOCKERBASEREGISTRY}${BASE_IMAGE_OS}

# For RHEL8 all arguments used in main code has to be specified after FROM
ARG BASEOS
ARG RELVER
ARG DFSET
ARG PACKAGER
ARG PG_LBL

MAINTAINER Crunchy Data <info@crunchydata.com>

LABEL vendor="Crunchy Data" \
	url="https://crunchydata.com" \
	release="${RELVER}" \
	org.opencontainers.image.vendor="Crunchy Data" \
	os.version="7.7"

COPY redhat/atomic/help.1 /help.1
COPY redhat/atomic/help.md /help.md
COPY licenses /licenses

# Have to install glibc-langpack-en on UBI8 otherwise en_US.utf-8 does not exist
RUN if [ "$BASEOS" = "ubi8" ] ; then \
        ${PACKAGER} -y update \
        && ${PACKAGER} -y install \
                glibc-langpack-en ; \
fi

# Temporary HACK to disable postgres module
RUN if [ "$BASEOS" = "ubi8" ] ; then \
        echo "[postgresql]"  >> /etc/dnf/modules.d/postgresql.module \
        && echo "name=postgresql"  >> /etc/dnf/modules.d/postgresql.module \
        && echo "stream=10"  >> /etc/dnf/modules.d/postgresql.module \
        && echo "profiles="  >> /etc/dnf/modules.d/postgresql.module \
        && echo "state=disabled"  >> /etc/dnf/modules.d/postgresql.module ; \
fi

ENV LC_ALL en_US.utf-8
ENV LANG en_US.utf-8

ARG EPEL7_RPM=https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
ARG EPEL8_RPM=https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

RUN if [ "$BASEOS" = "rhel7" ] ; then \
	${PACKAGER} -y --enablerepo=rhel-7-server-ose-3.11-rpms update \
        && ${PACKAGER} -y install ${EPEL7_RPM} \
	&& ${PACKAGER} -y install \
		--setopt=skip_missing_names_on_install=False \
		bind-utils \
		gettext \
		hostname \
		procps-ng \
		nss_wrapper \
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
                nss_wrapper \
        && sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/epel*.repo \
        && ${PACKAGER} -y clean all --enablerepo=rhel-7-server-ose-3.11-rpms ; \
fi

RUN if [ "$BASEOS" = "ubi8" ] ; then \
        rpm -ivh ${EPEL8_RPM} && \
        ${PACKAGER} -y update \
        && ${PACKAGER} -y install \
                bind-utils \
                gettext \
                hostname \
                procps-ng \
                nss_wrapper \
                less \
                vim-minimal \
        && ${PACKAGER} reinstall tzdata -y \
        && sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/epel*.repo \
        && ${PACKAGER} -y clean all ; \
fi

RUN if [ "$BASEOS" = "centos7" ] ; then \
        ${PACKAGER} -y update \
        && ${PACKAGER} -y install epel-release \
        && ${PACKAGER} -y install \
                --setopt=skip_missing_names_on_install=False \
                bind-utils \
                gettext \
                hostname \
                procps-ng \
                nss_wrapper \
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
		nss_wrapper \
	&& ${PACKAGER} -y clean all ; \
fi

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
