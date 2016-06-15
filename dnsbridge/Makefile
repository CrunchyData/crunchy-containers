
default:
		godep go install dnsbridgeserver.go
		godep go install consulclient.go

gendeps:
		godep save  \
		github.com/crunchydata/crunchy-containers/dnsbridgeapi

clean:
		rm -rf $(GOBIN)/dnsbridgeserver
		rm -rf $(GOBIN)/consulclient


