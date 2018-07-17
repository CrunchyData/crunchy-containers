# Automated Test Harness

This test harness is used to verify that the `kube` examples are working as intended as 
part of an integration test suite.  This harness will deploy the examples, query the Kubeneretes 
API using `client-go` and run various tests against the deployments.

The test harness creates namespaces for each test to avoid collision with object names.

This harness can be run both in and out of a Kubernetes cluster.

## Prerequisites

* An account with sufficient privileges is required (cluster-admin).
* It's recommended that all images used in the testing should be pulled prior to running
  the harness.  Pulling images over the network may be slow and cause timeouts with the 
  harness. 
* The `kubeconfig` should be found in `$HOME/.kube/config`
* [Mercurial Version Control installed](https://www.mercurial-scm.org/wiki/Download) (installed in `install-deps.sh` if 
  you're using CentOS7)
* `GOMAXPROCS` env should be set to the amount of cores the test harness should use (parallization 
  option)

### Vendor

`Godep` should restore vendor code in `$GOPATH` prior to running the harness:

```bash
cd $CCPROOT
godep restore ./...
```

## Running

*Note*: It's recommended to disable the `go test` timeout (it defaults to 10 minutes which 
is not enough time to run all tests):

#### Go `1.9`

`go test -timeout 100m` (100 minutes)

#### Go `1.10+`

`go test -timeout 0`

### All Tests

Run all tests, no timeout, max of 2 tests in parallel:

```bash
cd $CCPROOT/tools/test-harness
go test -v -timeout 0 -parallel 2
```

### Running Specific Tests

Using regex, run the `TestPrimary` test (`$` is regex for the string ends, 
meaning it won't match on say `TestPrimaryReplica`)

```bash
cd $CCPROOT/tools/test-harness
go test -v -run TestPrimary$
```

### Manual Cleanup

If for some reason the test-harness crashes, it's possible the test-harness namespaces 
have not been cleaned up correctly.  To manually delete the test harness namespaces, 
run the following script:

```bash
${CCPROOT?}/tools/test-harness/test-harness-manual-cleanup.sh
```
