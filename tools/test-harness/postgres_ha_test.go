package tests

import (
	"encoding/json"
	"testing"
)

// Test the Postgres HA container by running the relevant example and validated the
// various resources are created and running with the correct statuses
func TestPostgresHA(t *testing.T) {
	t.Parallel()
	t.Log("Testing the 'postgres-ha' example...")
	harness := setup(t, timeout, true)
	var pods []string
	env := []string{}

	t.Run("Run the Postgres HA container example", func(t *testing.T) {
		_, err := harness.runExample("examples/kube/postgres-ha/run.sh", env, t)
		if err != nil {
			t.Fatalf("Could not run example: %s", err)
		}
	})

	// Validate that deployments are created, that relevant pods are created for those deployments
	// and validates that they are ready to use
	t.Run("Checking pods statuses", func(t *testing.T) {
		t.Log("Checking if postgres-ha-01 deployment is ready...")
		if ok, err := harness.Client.IsDeploymentReady(harness.Namespace, "postgres-ha-01"); !ok {
			t.Fatal(err)
		}

		t.Log("Checking if postgres-ha-02 deployment is ready...")
		if ok, err := harness.Client.IsDeploymentReady(harness.Namespace, "postgres-ha-02"); !ok {
			t.Fatal(err)
		}

		ha01, err := harness.Client.GetDeploymentPods(harness.Namespace, "postgres-ha-01")
		if err != nil {
			t.Fatal(err)
		}

		ha02, err := harness.Client.GetDeploymentPods(harness.Namespace, "postgres-ha-02")
		if err != nil {
			t.Fatal(err)
		}

		if len(ha01) == 0 {
			t.Fatal("Postgres HA #1 deployment ready but no pods found")
		}

		if len(ha02) == 0 {
			t.Fatal("Postgres HA #2 deployment ready but no pods found")
		}

		for _, pod := range ha01 {
			pods = append(pods, pod)
		}
		for _, pod := range ha02 {
			pods = append(pods, pod)
		}

		t.Log("Checking if Postgres HA pods are ready to use")
		if err := harness.Client.CheckPods(harness.Namespace, pods); err != nil {
			t.Fatal(err)
		}
	})

	t.Run("Testing database connectivity", func(t *testing.T) {
		// If the pods were not found, this test fails.
		if len(pods) == 0 {
			t.FailNow()
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
	})

	t.Run("Grabbing Patroni output", func(t *testing.T) {
		// If the pods were not found, this test fails.
		if len(pods) == 0 {
			t.FailNow()
		}
		// Struct to hold relevant Patroni data
		type PatroniData struct {
			State   string
			Member  string
			Cluster string
			Host    string
			Role    string
		}
		// Exec into the first pod listed and run the Patroni client to gather status information
		patronictl := []string{"patronictl", "list", "--format", "json"}
		output, stderr, err := harness.Client.Exec(harness.Namespace, pods[0], "postgres", patronictl)
		if err != nil {
			t.Logf("\n%s", stderr)
			t.Fatalf("Error execing into container: %s", err)
		}

		// Store unmarshalled
		var pd []PatroniData
		json.Unmarshal([]byte(output), &pd)

		// Variables to store numer of pods running and the number of leaders
		numRunning := 0
		numLeader := 0

		// Print Patroni data gathered
		t.Log("PATRONI DATA\n")
		for _, element := range pd {
			t.Logf("STATE: %+v\n", element.State)
			if element.State == "running" {
				numRunning += 1
			}
			t.Logf("MEMBER: %+v\n", element.Member)
			t.Logf("CLUSTER: %+v\n", element.Cluster)
			t.Logf("HOST: %+v\n", element.Host)
			t.Logf("ROLE: %+v\n\n", element.Role)
			if element.Role == "Leader" {
				numLeader += 1
			}
		}

		// Failure conditions are:
		// 1) A Patroni enabled pod does not have a running status at this point
		// 2) There is more than one 'leader' pod
		// 3) There is not a 'leader' pod
		if numRunning != len(pd) {
			t.Fatal("Not all Pods are running")
		}
		if numLeader > 1 {
			t.Fatal("There is more than one leader.")
		}

		if numLeader < 1 {
			t.Fatal("There is no leader.")
		}
	})
	// Cleanup resources created for test
	if harness.Cleanup {
		defer harness.Client.DeleteNamespace(harness.Namespace)
		defer harness.runExample("examples/kube/postgres-ha/cleanup.sh", env, t)
	}
}
