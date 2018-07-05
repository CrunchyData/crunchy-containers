package tests

import (
	"testing"
)

func TestPGPool(t *testing.T) {
	t.Parallel()
	t.Log("Testing the 'pgpool' example...")
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

	pods := []string{"pr-primary", "pr-replica", "pr-replica-2"}
	t.Log("Checking if pods are ready to use...")
	if err := harness.Client.CheckPods(harness.Namespace, pods); err != nil {
		t.Fatal(err)
	}

	_, err = harness.runExample("examples/kube/pgpool/run.sh", env, t)
	if err != nil {
		t.Fatalf("Could not run example: %s", err)
	}

	if harness.Cleanup {
		defer harness.Client.DeleteNamespace(harness.Namespace)
		defer harness.runExample("examples/kube/pgpool/cleanup.sh", env, t)
	}

	t.Log("Checking if deployment is ready...")
	if ok, err := harness.Client.IsDeploymentReady(harness.Namespace, "pgpool"); !ok {
		t.Fatal(err)
	}

	deploy, err := harness.Client.GetDeploymentPods(harness.Namespace, "pgpool")
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
	proxy, err := harness.setupProxy(deploy[0], local, remote)
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

	report, err := harness.createReport()
	if err != nil {
		t.Fatal(err)
	}
	t.Log(report)
}
