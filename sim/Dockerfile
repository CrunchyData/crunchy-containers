FROM centos:7

LABEL Release="2.2.0"

ADD build/crunchy-sim /usr/bin

VOLUME /config

USER daemon

CMD ["crunchy-sim", "--config=/config/config/yaml", "queries.yaml"]
