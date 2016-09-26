
ifndef BUILDBASE
	export BUILDBASE=$(GOPATH)/src/github.com/crunchydata/crunchy-containers
endif

versiontest:
	if test -z "$$CCP_PGVERSION"; then echo "CCP_PGVERSION undefined"; exit 1;fi;
	if test -z "$$CCP_BASEOS"; then echo "CCP_BASEOS undefined"; exit 1;fi;
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
	docker build -t crunchy-postgres -f $(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.postgres.$(CCP_BASEOS) .
	docker tag crunchy-postgres crunchydata/crunchy-postgres:$(CCP_BASEOS)-$(CCP_PGVERSION)-$(CCP_VERSION)
watch:
	cp /usr/bin/oc bin/watch
	cp /usr/bin/kubectl bin/watch
	docker build -t crunchy-watch -f $(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.watch.$(CCP_BASEOS) .
	docker tag crunchy-watch crunchydata/crunchy-watch:$(CCP_BASEOS)-$(CCP_PGVERSION)-$(CCP_VERSION)
version:
	docker build -t crunchy-version -f $(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.version.$(CCP_BASEOS) .
	docker tag crunchy-version crunchydata/crunchy-version:$(CCP_BASEOS)-$(CCP_PGVERSION)-$(CCP_VERSION)
pgbouncer:
	make versiontest
	cp /usr/bin/oc bin/pgbouncer
	cp /usr/bin/kubectl bin/pgbouncer
	cd bounce && godep go install bounce.go
	cp $(GOBIN)/bounce bin/pgbouncer/
	sudo docker build -t crunchy-pgbouncer -f $(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.pgbouncer.$(CCP_BASEOS) .
	docker tag crunchy-pgbouncer crunchydata/crunchy-pgbouncer:$(CCP_BASEOS)-$(CCP_PGVERSION)-$(CCP_VERSION)
pgpool:
	make versiontest
	sudo docker build -t crunchy-pgpool -f $(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.pgpool.$(CCP_BASEOS) .
	docker tag crunchy-pgpool crunchydata/crunchy-pgpool:$(CCP_BASEOS)-$(CCP_PGVERSION)-$(CCP_VERSION)
pgbadger:
	make versiontest
	cd badger && godep go install badgerserver.go
	cp $(GOBIN)/badgerserver bin/pgbadger
	docker build -t crunchy-pgbadger -f $(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.pgbadger.$(CCP_BASEOS) .
	docker tag crunchy-pgbadger crunchydata/crunchy-pgbadger:$(CCP_BASEOS)-$(CCP_PGVERSION)-$(CCP_VERSION)
collectserver:
	make versiontest
	cd collect && godep go install collectserver.go
	cp $(GOBIN)/collectserver bin/collect
	sudo docker build -t crunchy-collect -f $(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.collect.$(CCP_BASEOS) .
	docker tag crunchy-collect crunchydata/crunchy-collect:$(CCP_BASEOS)-$(CCP_PGVERSION)-$(CCP_VERSION)
dns: 
	cd dnsbridge && godep go install dnsbridgeserver.go
	cd dnsbridge && godep go install consulclient.go
	cp $(GOBIN)/consul bin/dns/
	cp $(GOBIN)/dnsbridgeserver bin/dns/
	cp $(GOBIN)/consulclient bin/dns/
	sudo docker build -t crunchy-dns -f $(CCP_BASEOS)/Dockerfile.dns.$(CCP_BASEOS) .
	docker tag crunchy-dns crunchydata/crunchy-dns:$(CCP_BASEOS)-$(CCP_PGVERSION)-$(CCP_VERSION)
backup:
	make versiontest
	sudo docker build -t crunchy-backup -f $(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.backup.$(CCP_BASEOS) .
	docker tag crunchy-backup crunchydata/crunchy-backup:$(CCP_BASEOS)-$(CCP_PGVERSION)-$(CCP_VERSION)
pgadmin4: 
	make versiontest
	sudo docker build -t crunchy-pgadmin4 -f $(CCP_BASEOS)/$(CCP_PGVERSION)/Dockerfile.pgadmin4.$(CCP_BASEOS) .
	docker tag crunchy-pgadmin4 crunchydata/crunchy-pgadmin4:$(CCP_BASEOS)-$(CCP_PGVERSION)-$(CCP_VERSION)
prometheus: 
	make versiontest
	sudo docker build -t crunchy-prometheus -f $(CCP_BASEOS)/Dockerfile.prometheus.$(CCP_BASEOS) .
	docker tag crunchy-prometheus crunchydata/crunchy-prometheus:$(CCP_BASEOS)-$(CCP_PGVERSION)-$(CCP_VERSION)
promgateway: 
	make versiontest
	sudo docker build -t crunchy-promgateway -f $(CCP_BASEOS)/Dockerfile.promgateway.$(CCP_BASEOS) .
	docker tag crunchy-promgateway crunchydata/crunchy-promgateway:$(CCP_BASEOS)-$(CCP_PGVERSION)-$(CCP_VERSION)
grafana:
	make versiontest
	sudo docker build -t crunchy-grafana -f $(CCP_BASEOS)/Dockerfile.grafana.$(CCP_BASEOS) .
	docker tag crunchy-grafana crunchydata/crunchy-grafana:$(CCP_BASEOS)-$(CCP_PGVERSION)-$(CCP_VERSION)

all:
	make versiontest
	make postgres
	make backup
	make watch
	make pgpool
	make pgbouncer
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

