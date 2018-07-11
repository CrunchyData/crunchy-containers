package tests

import (
	"testing"
	"time"
)

func TestStatefulSet(t *testing.T) {
	t.Parallel()
	t.Log("Testing the 'statefulset' example...")
	// This example deploys replicas after primary is ready, 
	// so extra time in the timeout is allocated
	harness := setup(t, time.Duration(time.Second*240), true)

	env := []string{}
	_, err := harness.runExample("examples/kube/statefulset/run.sh", env, t)
	if err != nil {
		t.Fatalf("Could not run example: %s", err)
	}

	if harness.Cleanup {
		defer harness.Client.DeleteNamespace(harness.Namespace)
		defer harness.runExample("examples/kube/statefulset/cleanup.sh", env, t)
	}

	t.Log("Checking if statefulset ready...")
	if ok, err := harness.Client.IsStatefulSetReady(harness.Namespace, "statefulset"); !ok {
		t.Fatal(err)
	}

	pods, err := harness.Client.GetStatefulSetPods(harness.Namespace, "statefulset")
	if err != nil {
		t.Fatal(err)
	}

    if len(pods) == 0 {
        t.Fatal("No pods found in stateful set")
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

	db, err := harness.setupDB("userdb", proxy.Hostname, "testuser", "password", "disable", local)
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()

	_ = db.RunCRUD()

	extensions, err := db.AllExtensions()
	if err != nil {
		t.Fatal(err)
	}

	if len(extensions) < 1 {
		t.Fatalf("extensions less then 1, it shouldn't be: %d", len(extensions))
	}

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
