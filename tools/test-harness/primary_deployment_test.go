package tests

import (
	"testing"
)

func TestPrimaryDeployment(t *testing.T) {
	t.Parallel()
	t.Log("Testing the 'primary-deployment' example...")
	harness := setup(t, timeout, true)

	env := []string{}
	_, err := harness.runExample("examples/kube/primary-deployment/run.sh", env, t)
	if err != nil {
		t.Fatalf("Could not run example: %s", err)
	}

	if harness.Cleanup {
		defer harness.Client.DeleteNamespace(harness.Namespace)
		defer harness.runExample("examples/kube/primary-deployment/cleanup.sh", env, t)
	}

	t.Log("Checking if primary deployment is ready...")
	if ok, err := harness.Client.IsDeploymentReady(harness.Namespace, "primary-deployment"); !ok {
		t.Fatal(err)
	}

	t.Log("Checking if replica deployment is ready...")
	if ok, err := harness.Client.IsStatefulSetReady(harness.Namespace, "replica-deployment"); !ok {
		t.Fatal(err)
	}

	primary, err := harness.Client.GetDeploymentPods(harness.Namespace, "primary-deployment")
	if err != nil {
		t.Fatal(err)
	}

	replica, err := harness.Client.GetStatefulSetPods(harness.Namespace, "replica-deployment")
	if err != nil {
		t.Fatal(err)
	}

	var pods []string
	for _, pod := range primary {
		pods = append(pods, pod)
	}

	for _, pod := range replica {
		pods = append(pods, pod)
	}

	t.Log("Checking if pods are ready to use...")
	if err := harness.Client.CheckPods(harness.Namespace, pods); err != nil {
		t.Fatal(err)
	}

	local, remote := randomPort(), 5432
	proxy, err := harness.setupProxy(primary[0], local, remote)
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
