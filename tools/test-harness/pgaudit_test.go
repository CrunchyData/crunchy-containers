package tests

import (
	"testing"
)

func TestPGAudit(t *testing.T) {
	t.Parallel()
	t.Log("Testing the 'pgaudit' example...")
	harness := setup(t, timeout, true)

	env := []string{}
	_, err := harness.runExample("examples/kube/pgaudit/run.sh", env, t)
	if err != nil {
		t.Fatalf("Could not run example: %s", err)
	}

	if harness.Cleanup {
		defer harness.Client.DeleteNamespace(harness.Namespace)
		defer harness.runExample("examples/kube/pgaudit/cleanup.sh", env, t)
	}

	t.Log("Checking if pods are ready to use...")
	if err := harness.Client.CheckPods(harness.Namespace, []string{"pgaudit"}); err != nil {
		t.Fatal(err)
	}

    output, err := harness.runExample("examples/kube/pgaudit/test-pgaudit.sh", env, t)
    if err != nil {
        t.Fatalf("Could not run example: %s\n%s", output, err)
    }

    t.Logf("Output of test script: %s", output)

	report, err := harness.createReport()
	if err != nil {
		t.Fatal(err)
	}
	t.Log(report)
}
