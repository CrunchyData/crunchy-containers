package tests

import (
	"testing"
)

func TestPrimaryReplicaDC(t *testing.T) {
	t.Parallel()
	t.Log("Testing the 'primary-replica-dc' example...")
	harness := setup(t, timeout, true)

	env := []string{}
	_, err := harness.runExample("examples/kube/primary-replica-dc/run.sh", env, t)
	if err != nil {
		t.Fatalf("Could not run example: %s", err)
	}
	if harness.Cleanup {
		defer harness.Client.DeleteNamespace(harness.Namespace)
		defer harness.runExample("examples/kube/primary-replica-dc/cleanup.sh", env, t)
	}

	pods := []string{"primary-dc"}
	t.Log("Checking if pods are ready to use...")
	if err := harness.Client.CheckPods(harness.Namespace, pods); err != nil {
		t.Fatal(err)
	}

	t.Log("Checking if replica deployment is ready...")
	if ok, err := harness.Client.IsDeploymentReady(harness.Namespace, "replica-dc"); !ok {
		t.Fatal(err)
	}

	deploy, err := harness.Client.GetDeploymentPods(harness.Namespace, "replica-dc")
	if err != nil {
		t.Fatal(err)
	}

	for _, pod := range deploy {
		pods = append(pods, pod)
	}

	t.Log("Checking if pods are ready to use...")
	if err := harness.Client.CheckPods(harness.Namespace, pods); err != nil {
		t.Fatal(err)
	}

	local, remote := randomPort(), 5432
	proxy, err := harness.setupProxy("primary-dc", local, remote)
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
