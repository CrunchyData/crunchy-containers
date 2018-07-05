package tests

import (
	"testing"
)

func TestPrimary(t *testing.T) {
	t.Parallel()
	t.Log("Testing the 'primary' example...")
	harness := setup(t, timeout, true)

	env := []string{}
	_, err := harness.runExample("examples/kube/primary/run.sh", env, t)
	if err != nil {
		t.Fatalf("Could not run example: %s", err)
	}

	if harness.Cleanup {
		defer harness.Client.DeleteNamespace(harness.Namespace)
		defer harness.runExample("examples/kube/primary/cleanup.sh", env, t)
	}

	t.Log("Checking if pods are ready to use...")
	if err := harness.Client.CheckPods(harness.Namespace, []string{"primary"}); err != nil {
		t.Fatal(err)
	}

	local, remote := randomPort(), 5432
	proxy, err := harness.setupProxy("primary", local, remote)
	if err != nil {
		t.Fatal(err)
	}
	defer proxy.Close()

	db, err := harness.setupDB("userdb", proxy.Hostname, "postgres", "password", "disable", local)
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()

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
