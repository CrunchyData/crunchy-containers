FROM centos:7

LABEL Release="0.0.1" Vendor="Crunchy Data Solutions"

ADD build/crunchy-sim /usr/bin

VOLUME /config

USER daemon

CMD ["crunchy-sim", "--config=/config/config/yaml", "queries.yaml"]
