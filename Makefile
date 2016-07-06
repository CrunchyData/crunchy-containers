OSFLAVOR=centos7
PGVERSION=9.5

ifndef BUILDBASE
	export BUILDBASE=$(GOPATH)/src/github.com/crunchydata/crunchy-containers
endif

versiontest:
	if test -z "$$CCP_VERSION"; then echo "CCP_VERSION undefined"; exit 1;fi;
setup:
	$(BUILDBASE)/bin/install-deps.sh
gendeps:
	godep save \
	github.com/crunchydata/crunchy-containers/collectapi \
	github.com/crunchydata/crunchy-containers/dnsbridgeapi \
	github.com/crunchydata/crunchy-containers/badger 

docbuild:
	cd docs && ./build-docs.sh
postgres:
	make versiontest
	docker build -t crunchy-postgres -f $(OSFLAVOR)/$(PGVERSION)/Dockerfile.postgres.$(OSFLAVOR) .
	docker tag -f crunchy-postgres crunchydata/crunchy-postgres:$(OSFLAVOR)-$(PGVERSION)-$(CCP_VERSION)
watch:
	cp /usr/bin/oc bin/watch
	cp /usr/bin/kubectl bin/watch
	docker build -t crunchy-watch -f $(OSFLAVOR)/$(PGVERSION)/Dockerfile.watch.$(OSFLAVOR) .
	docker tag -f crunchy-watch crunchydata/crunchy-watch:$(OSFLAVOR)-$(PGVERSION)-$(CCP_VERSION)
version:
	docker build -t crunchy-version -f $(OSFLAVOR)/$(PGVERSION)/Dockerfile.version.$(OSFLAVOR) .
	docker tag -f crunchy-version crunchydata/crunchy-version:$(OSFLAVOR)-$(PGVERSION)-$(CCP_VERSION)
pgbouncer:
	make versiontest
	cp /usr/bin/oc bin/pgbouncer
	cp /usr/bin/kubectl bin/pgbouncer
	cd bounce && godep go install bounce.go
	cp $(GOBIN)/bounce bin/pgbouncer/
	sudo docker build -t crunchy-pgbouncer -f $(OSFLAVOR)/$(PGVERSION)/Dockerfile.pgbouncer.$(OSFLAVOR) .
	docker tag -f crunchy-pgbouncer crunchydata/crunchy-pgbouncer:$(OSFLAVOR)-$(PGVERSION)-$(CCP_VERSION)
pgpool:
	make versiontest
	sudo docker build -t crunchy-pgpool -f $(OSFLAVOR)/$(PGVERSION)/Dockerfile.pgpool.$(OSFLAVOR) .
	docker tag -f crunchy-pgpool crunchydata/crunchy-pgpool:$(OSFLAVOR)-$(PGVERSION)-$(CCP_VERSION)
pgbadger:
	make versiontest
	cd badger && godep go install badgerserver.go
	cp $(GOBIN)/badgerserver bin/pgbadger
	sudo docker build -t crunchy-pgbadger -f $(OSFLAVOR)/$(PGVERSION)/Dockerfile.pgbadger.$(OSFLAVOR) .
	docker tag -f crunchy-pgbadger crunchydata/crunchy-pgbadger:$(OSFLAVOR)-$(PGVERSION)-$(CCP_VERSION)
collectserver:
	make versiontest
	cd collect && godep go install collectserver.go
	cp $(GOBIN)/collectserver bin/collect
	sudo docker build -t crunchy-collect -f $(OSFLAVOR)/$(PGVERSION)/Dockerfile.collect.$(OSFLAVOR) .
	docker tag -f crunchy-collect crunchydata/crunchy-collect:$(OSFLAVOR)-$(PGVERSION)-$(CCP_VERSION)
dns: 
	cd dnsbridge && godep go install dnsbridgeserver.go
	cd dnsbridge && godep go install consulclient.go
	cp $(GOBIN)/consul bin/dns/
	cp $(GOBIN)/dnsbridgeserver bin/dns/
	cp $(GOBIN)/consulclient bin/dns/
	sudo docker build -t crunchy-dns -f $(OSFLAVOR)/Dockerfile.dns.$(OSFLAVOR) .
	docker tag -f crunchy-dns crunchydata/crunchy-dns:$(OSFLAVOR)-$(PGVERSION)-$(CCP_VERSION)
backup:
	make versiontest
	sudo docker build -t crunchy-backup -f $(OSFLAVOR)/$(PGVERSION)/Dockerfile.backup.$(OSFLAVOR) .
	docker tag -f crunchy-backup crunchydata/crunchy-backup:$(OSFLAVOR)-$(PGVERSION)-$(CCP_VERSION)
prometheus: 
	make versiontest
	sudo docker build -t crunchy-prometheus -f $(OSFLAVOR)/Dockerfile.prometheus.$(OSFLAVOR) .
	docker tag -f crunchy-prometheus crunchydata/crunchy-prometheus:$(OSFLAVOR)-$(PGVERSION)-$(CCP_VERSION)
promgateway: 
	make versiontest
	sudo docker build -t crunchy-promgateway -f $(OSFLAVOR)/Dockerfile.promgateway.$(OSFLAVOR) .
	docker tag -f crunchy-promgateway crunchydata/crunchy-promgateway:$(OSFLAVOR)-$(PGVERSION)-$(CCP_VERSION)
grafana:
	make versiontest
	sudo docker build -t crunchy-grafana -f $(OSFLAVOR)/Dockerfile.grafana.$(OSFLAVOR) .
	docker tag -f crunchy-grafana crunchydata/crunchy-grafana:$(OSFLAVOR)-$(PGVERSION)-$(CCP_VERSION)

all:
	make versiontest
	make postgres
	make backup
	make watch
	make pgpool
	make pgbadger
	make collectserver
	make dns
	make grafana
	make promgateway
	make prometheus
push:
	./bin/push-to-dockerhub.sh
default:
	all
test:
	./tests/standalone/test-master.sh; /usr/bin/test "$$?" -eq 0
	./tests/standalone/test-replica.sh; /usr/bin/test "$$?" -eq 0
	./tests/standalone/test-pgpool.sh; /usr/bin/test "$$?" -eq 0
	./tests/standalone/test-backup.sh; /usr/bin/test "$$?" -eq 0
	./tests/standalone/test-restore.sh; /usr/bin/test "$$?" -eq 0
	./tests/standalone/test-watch.sh; /usr/bin/test "$$?" -eq 0
	./tests/standalone/test-badger.sh; /usr/bin/test "$$?" -eq 0
	sudo docker stop master
testopenshift:
	./tests/openshift/test-master.sh; /usr/bin/test "$$?" -eq 0
	./tests/openshift/test-replica.sh; /usr/bin/test "$$?" -eq 0
	./tests/openshift/test-pgpool.sh; /usr/bin/test "$$?" -eq 0
	./tests/openshift/test-watch.sh; /usr/bin/test "$$?" -eq 0
	./tests/openshift/test-scope.sh; /usr/bin/test "$$?" -eq 0
	./tests/openshift/test-backup.sh; /usr/bin/test "$$?" -eq 0

