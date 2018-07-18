package tests

import (
	"fmt"
	"testing"
)

func TestPGBadger(t *testing.T) {
	t.Parallel()
	t.Log("Testing the 'pgbadger' example...")

	harness := setup(t, timeout, true)
	env := []string{}
	_, err := harness.runExample("examples/kube/pgbadger/run.sh", env, t)
	if err != nil {
		t.Fatalf("Could not run example: %s", err)
	}

	if harness.Cleanup {
		defer harness.Client.DeleteNamespace(harness.Namespace)
		defer harness.runExample("examples/kube/pgbadger/cleanup.sh", env, t)
	}

	pods := []string{"pgbadger"}
	t.Log("Checking if pods are ready to use...")
	if err := harness.Client.CheckPods(harness.Namespace, pods); err != nil {
		t.Fatal(err)
	}

	local, remote := randomPort(), 10000
	proxy, err := harness.setupProxy("badger", local, remote)
	if err != nil {
		t.Fatal(err)
	}
	defer proxy.Close()

	badgerURL := fmt.Sprintf("http://127.0.0.1:%d/api/badgergenerate", local)

	if err := getStatus(badgerURL); err != nil {
		t.Fatalf("pgBadger HTTP health check failed: %s", err)
	}

	report, err := harness.createReport()
	if err != nil {
		t.Fatal(err)
	}
	t.Log(report)
}
