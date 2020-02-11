package tests

/*
Copyright 2018 - 2020 Crunchy Data Solutions, Inc.
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

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

	t.Log("Starting backup job...")
	_, err = harness.runExample("examples/kube/pgbasebackup/backup/run.sh", env, t)
	if err != nil {
		t.Fatalf("Could not run example: %s", err)
	}
	if harness.Cleanup {
		defer harness.runExample("examples/kube/pgbasebackup/backup/cleanup.sh", env, t)
	}

	t.Log("Checking if job has completed...")
	job, err := harness.Client.GetJob(harness.Namespace, "backup")
	if err != nil {
		t.Fatal(err)
	}

	if err := harness.Client.IsJobComplete(harness.Namespace, job); err != nil {
		t.Fatal(err)
	}

	report, err := harness.createReport()
	if err != nil {
		t.Fatal(err)
	}
	t.Log(report)
}
