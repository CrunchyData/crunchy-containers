package tests

import (
	"bytes"
	"strings"
	"testing"
	"time"

	"github.com/crunchydata/crunchy-containers/tools/kubeapi"
)

func TestScheduler(t *testing.T) {
	t.Parallel()
	t.Log("Testing the 'scheduler' example...")
	harness := setup(t, timeout, true)

	env := []string{}
	_, err := harness.runExample("examples/kube/scheduler/primary/run.sh", env, t)
	if err != nil {
		t.Fatalf("Could not run example: %s", err)
	}

	if harness.Cleanup {
		defer harness.Client.DeleteNamespace(harness.Namespace)
		defer harness.runExample("examples/kube/scheduler/primary/cleanup.sh", env, t)
	}

	t.Log("Checking if primary deployment is ready...")
	if ok, err := harness.Client.IsDeploymentReady(harness.Namespace, "primary-deployment"); !ok {
		t.Fatal(err)
	}

	primary, err := harness.Client.GetDeploymentPods(harness.Namespace, "primary-deployment")
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

	t.Log("Starting scheduler..")
	out, err := harness.runExample("examples/kube/scheduler/run.sh", env, t)
	if err != nil {
		t.Fatalf("Could not run example: %s\n%s", err, out)
	}

	if harness.Cleanup {
		defer harness.runExample("examples/kube/scheduler/cleanup.sh", env, t)
	}

	t.Log("Checking if pods are ready to use...")
	if err := harness.Client.CheckPods(harness.Namespace, []string{"scheduler"}); err != nil {
		t.Fatal(err)
	}

	t.Log("Adding schedules..")
	out, err = harness.runExample("examples/kube/scheduler/add-schedules.sh", env, t)
	if err != nil {
		t.Fatalf("Could not add schedules: %s\n%s", err, out)
	}

	// Extra 10 seconds to account for discovery of configmaps
	t.Log("Sleeping for 2:10 minutes to let scheduler run backups..")
	time.Sleep(130 * time.Second)

	t.Log("Adding schedules..")
	out, err = harness.runExample("examples/kube/scheduler/remove-schedules.sh", env, t)
	if err != nil {
		t.Fatalf("Could not remove schedules: %s\n%s", err, out)
	}

	t.Log("Sleeping for 15 seconds to let scheduler remove schedules..")
	time.Sleep(15 * time.Second)

	logOpts := &kubeapi.LogOpts{
		Container:  "scheduler",
		Namespace:  harness.Namespace,
		Pod:        "scheduler",
		Follow:     false,
		Previous:   false,
		Timestamps: false,
	}
	var logs bytes.Buffer
	if err := harness.Client.Logs(logOpts, &logs); err != nil {
		t.Fatalf("Could not retrieve logs from scheduler: %s", err)
	}

	if strings.Contains(logs.String(), "level=error") {
		t.Fatalf("Scheduler logs contains errors (it shouldn't): %s", logs.String())
	}

	report, err := harness.createReport()
	if err != nil {
		t.Fatal(err)
	}
	t.Log(report)
}
