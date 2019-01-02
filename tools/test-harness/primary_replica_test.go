package tests

import (
	"testing"
)

func TestPrimaryReplica(t *testing.T) {
	t.Parallel()
	t.Log("Testing the 'primary-replica' example...")
	harness := setup(t, timeout, true)
	env := []string{}
	_, err := harness.runExample("examples/kube/primary-replica/run.sh", env, t)
	if err != nil {
		t.Fatalf("Could not run example: %s", err)
	}
	if harness.Cleanup {
		defer harness.Client.DeleteNamespace(harness.Namespace)
		defer harness.runExample("examples/kube/primary-replica/cleanup.sh", env, t)
	}

	t.Log("Checking if primary deployment is ready...")
	if ok, err := harness.Client.IsDeploymentReady(harness.Namespace, "pr-primary"); !ok {
		t.Fatal(err)
	}

	t.Log("Checking if replica deployment is ready...")
	if ok, err := harness.Client.IsDeploymentReady(harness.Namespace, "pr-replica"); !ok {
		t.Fatal(err)
	}

	primary, err := harness.Client.GetDeploymentPods(harness.Namespace, "pr-primary")
	if err != nil {
		t.Fatal(err)
	}

	replica, err := harness.Client.GetDeploymentPods(harness.Namespace, "pr-replica")
	if err != nil {
		t.Fatal(err)
	}

	if len(primary) == 0 {
		t.Fatal("Primary deployment ready but no pods found")
	}

	if len(replica) == 0 {
		t.Fatal("Primary deployment ready but no pods found")
	}

	var pods []string
	for _, pod := range primary {
		pods = append(pods, pod)
	}

	t.Log("Checking if pods are ready to use...")
	if err := harness.Client.CheckPods(harness.Namespace, pods); err != nil {
		t.Fatal(err)
	}

	local, remote := randomPort(), 5432
	proxy, err := harness.setupProxy(pods[0], local, remote)
	if err != nil {
		t.Fatal(err)
	}
	defer proxy.Close()

	db, err := harness.setupDB("userdb", proxy.Hostname, "postgres", "password", "disable", local)
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()

	replicas, err := db.Replication()
	if err != nil {
		t.Fatal(err)
	}

	if len(replicas) < 1 {
		t.Fatalf("Replica count should be greater than 0: actual %d", len(replicas))
	}

	var sync bool
	for _, v := range replicas {
		if v.SyncState == "sync" {
			sync = true
		}
	}

	if sync {
		t.Fatalf("Sync replica detected, there shouldn't be.")
	}

	report, err := harness.createReport()
	if err != nil {
		t.Fatal(err)
	}
	t.Log(report)
}
