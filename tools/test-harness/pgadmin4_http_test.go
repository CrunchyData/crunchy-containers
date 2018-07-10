package tests

import (
	"fmt"
	"testing"
)

func TestPGAdminHTTP(t *testing.T) {
	t.Parallel()
	t.Log("Testing the 'pgadmin4-http' example...")

	harness := setup(t, timeout, true)

	env := []string{}
	_, err := harness.runExample("examples/kube/pgadmin4-http/run.sh", env, t)
	if err != nil {
		t.Fatalf("Could not run example: %s", err)
	}

	if harness.Cleanup {
		defer harness.Client.DeleteNamespace(harness.Namespace)
		defer harness.runExample("examples/kube/pgadmin4-http/cleanup.sh", env, t)
	}

	pods := []string{"pgadmin4-http"}
	t.Log("Checking if pods are ready to use...")
	if err := harness.Client.CheckPods(harness.Namespace, pods); err != nil {
		t.Fatal(err)
	}

	local, remote := randomPort(), 5050
	proxy, err := harness.setupProxy("pgadmin4-http", local, remote)
	if err != nil {
		t.Fatal(err)
	}
	defer proxy.Close()

	pgadminURL := fmt.Sprintf("http://127.0.0.1:%d", local)

	if err := getStatus(pgadminURL); err != nil {
		t.Fatalf("pgAdmin4 HTTP health check failed: %s", err)
	}

	report, err := harness.createReport()
	if err != nil {
		t.Fatal(err)
	}
	t.Log(report)
}
