package tests

import (
	"fmt"
	"testing"
)

func TestMetrics(t *testing.T) {
	t.Parallel()
	t.Log("Testing the 'metrics' example...")
	harness := setup(t, timeout, true)
	env := []string{}
	_, err := harness.runExample("examples/kube/metrics/run.sh", env, t)
	if err != nil {
		t.Fatalf("Could not run example: %s", err)
	}

	if harness.Cleanup {
		defer harness.Client.DeleteNamespace(harness.Namespace)
		defer harness.runExample("examples/kube/metrics/cleanup.sh", env, t)
	}

	t.Log("Checking if primary deployment is ready...")
	if ok, err := harness.Client.IsDeploymentReady(harness.Namespace, "primary-metrics"); !ok {
		t.Fatal(err)
	}

	t.Log("Checking if replica deployment is ready...")
	if ok, err := harness.Client.IsDeploymentReady(harness.Namespace, "replica-metrics"); !ok {
		t.Fatal(err)
	}

	primary, err := harness.Client.GetDeploymentPods(harness.Namespace, "primary-metrics")
	if err != nil {
		t.Fatal(err)
	}

	if len(primary) == 0 {
		t.Fatal("No primary pods founds")
	}

	replica, err := harness.Client.GetDeploymentPods(harness.Namespace, "replica-metrics")
	if err != nil {
		t.Fatal(err)
	}

	if len(replica) == 0 {
		t.Fatal("No replica pods founds")
	}

	pods := []string{"metrics"}
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

	promLocal, promRemote := randomPort(), 9090
	promProx, err := harness.setupProxy("metrics", promLocal, promRemote)
	if err != nil {
		t.Fatal(err)
	}
	defer promProx.Close()

	grafLocal, grafRemote := randomPort(), 3000
	grafProx, err := harness.setupProxy("metrics", grafLocal, grafRemote)
	if err != nil {
		t.Fatal(err)
	}
	defer grafProx.Close()

	pgxpLocal, pgxpRemote := randomPort(), 9187
	pgxpProx, err := harness.setupProxy(primary[0], pgxpLocal, pgxpRemote)
	if err != nil {
		t.Fatal(err)
	}
	defer pgxpProx.Close()

	promURL := fmt.Sprintf("http://127.0.0.1:%d", promLocal)
	grafURL := fmt.Sprintf("http://127.0.0.1:%d", grafLocal)
	pgxpURL := fmt.Sprintf("http://127.0.0.1:%d", pgxpLocal)

	if err := getStatus(promURL); err != nil {
		t.Fatalf("Prometheus health check failed: %s", err)
	}

	if err := getStatus(grafURL); err != nil {
		t.Fatalf("Grafana health check failed: %s", err)
	}

	if err := getStatus(pgxpURL); err != nil {
		t.Fatalf("Postgres Exporter health check failed: %s", err)
	}

	report, err := harness.createReport()
	if err != nil {
		t.Fatal(err)
	}
	t.Log(report)
}
