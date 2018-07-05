package tests

import (
	"testing"
)

func TestPGDump(t *testing.T) {
	t.Parallel()
	t.Log("Testing the 'pgdump' example...")
	harness := setup(t, timeout, true)

	t.Log("Setting up primary for 'pgdump' job...")
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

	t.Log("Running the 'pgdump' example...")
	_, err = harness.runExample("examples/kube/pgdump/run.sh", env, t)
	if err != nil {
		t.Fatalf("Could not run example: %s", err)
	}

	if harness.Cleanup {
		defer harness.runExample("examples/kube/pgdump/cleanup.sh", env, t)
	}

	t.Log("Checking if job is completed..")
	if ok, err := harness.Client.IsJobComplete(harness.Namespace, "pgdump"); !ok {
		t.Fatal(err)
	}

	report, err := harness.createReport()
	if err != nil {
		t.Fatal(err)
	}
	t.Log(report)
}
