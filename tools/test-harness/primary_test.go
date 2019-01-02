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

	t.Log("Checking if primary deployment is ready...")
	if ok, err := harness.Client.IsDeploymentReady(harness.Namespace, "primary"); !ok {
		t.Fatal(err)
	}

	primary, err := harness.Client.GetDeploymentPods(harness.Namespace, "primary")
	if err != nil {
		t.Fatal(err)
	}

	if len(primary) == 0 {
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

	extensions, err := db.AllExtensions()
	if err != nil {
		t.Fatal(err)
	}

	if len(extensions) < 1 {
		t.Fatalf("extensions less then 1, it shouldn't be: %d", len(extensions))
	}

	settings, err := db.Settings()
	if err != nil {
		t.Fatal(err)
	}

	for _, setting := range settings {
		if setting.Name == "log_timezone" && setting.Value != "UTC" {
			t.Fatalf("log_timezone isn't UTC, it should be: %s = %s", setting.Name, setting.Value)
		}
	}

	report, err := harness.createReport()
	if err != nil {
		t.Fatal(err)
	}
	t.Log(report)
}
