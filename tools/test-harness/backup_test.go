package tests

import (
	"testing"
)

func TestBackup(t *testing.T) {
	t.Parallel()
	t.Log("Testing the 'backup' example...")

	harness := setup(t, timeout, true)

	t.Log("Starting primary...")
	env := []string{}
	_, err := harness.runExample("examples/kube/primary/run.sh", env, t)
	if err != nil {
		t.Fatalf("Could not run example: %s", err)
	}
	if harness.Cleanup {
		defer harness.Client.DeleteNamespace(harness.Namespace)
		defer harness.runExample("examples/kube/primary/cleanup.sh", env, t)
	}

	pods := []string{"primary"}
	t.Log("Checking if pods are ready to use...")
	if err := harness.Client.CheckPods(harness.Namespace, pods); err != nil {
		t.Fatal(err)
	}

	t.Log("Starting backup job...")
	_, err = harness.runExample("examples/kube/backup/run.sh", env, t)
	if err != nil {
		t.Fatalf("Could not run example: %s", err)
	}
	if harness.Cleanup {
		defer harness.runExample("examples/kube/backup/cleanup.sh", env, t)
	}

	t.Log("Checking if job has completed...")
	if ok, err := harness.Client.IsJobComplete(harness.Namespace, "backup"); !ok {
		t.Fatal(err)
	}

	report, err := harness.createReport()
	if err != nil {
		t.Fatal(err)
	}
	t.Log(report)
}
