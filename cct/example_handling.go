/*
 Copyright 2017 Crunchy Data Solutions, Inc.
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

// Crunchy Container Test
package cct

import (
	"bytes"
	"fmt"
	"os/exec"
	"path"
	"testing"

	"github.com/docker/docker/client"
)

// executes a named docker example, and traps output
func startDockerExample(
    basePath string,
    exampleName string,
    arg ...string) (pathToCleanup string, cmdout string, err error) {

    pathToExample := path.Join(
        basePath, "examples", "docker", exampleName, "run.sh")
    pathToCleanup = path.Join(
        basePath, "examples", "docker", exampleName, "cleanup.sh")


    out, err := exec.Command(pathToExample, arg...).CombinedOutput()

    cmdout = bytes.NewBuffer(out).String()
    if err != nil {
        return
    }
    return
}

// executes an example cleanup script, and traps output
func cleanupExample(pathToCleanup string) (cmdout string, err error) {
    out, err := exec.Command(pathToCleanup).CombinedOutput()
    if err != nil {
        return
    }
    cmdout = bytes.NewBuffer(out).String()
    return
}

// Starts a named example for a golang test, logs output or fails test. The returned cleanup function, which wraps the example cleanup function, will have no effect if skip=true
func startDockerExampleForTest(
    t *testing.T,
    basePath string,
    exampleName string,
    arg ...string) (cleanup func(skip bool)) {

    t.Log("Starting Example: docker/" + exampleName)
    pathToCleanup, cmdout, err := startDockerExample(basePath, exampleName, arg...)
    if err != nil {
        t.Fatal(err, cmdout)
    }
    t.Log(cmdout)

    cleanup = func (skip bool) {
        cleanupTest(t, skip, exampleName, pathToCleanup)
    }

    return
}

// wraps example cleanup script for a golang unit test, or has no effect if skip=true
func cleanupTest(t *testing.T, skip bool, name string, pathToCleanup string) {

    if skip {
        t.Logf("SKIPPING %s cleanup: %s\n", name, pathToCleanup)
    } else {
        t.Logf("Cleaning %s: %s\n", name, pathToCleanup)
        cmdout, err := cleanupExample(pathToCleanup)
        if err != nil {
            t.Error(err, cmdout)
        }
        t.Log(cmdout)
    }
}

// Starts basic example for test. It is caller's responsibility to cleanup
func startBasic(
    t *testing.T,
    docker *client.Client,
    basePath string,
    timeout int64) (id string, cleanup func(skip bool)) {

    fmt.Printf("\nWaiting maximum %d seconds to start basic example", timeout)
    cleanup = startDockerExampleForTest(t, basePath, "basic")

    var err error
    id, err = waitForPostgresContainer(docker, "basic", timeout)
    if err != nil {
        t.Fatal(err)
    }
    t.Log("Started basic container: " + id)

    return
}

// Starts the master-replica example, and wait for both servers to start
func startMasterReplica(
    t *testing.T,
    docker *client.Client,
    basePath string,
    timeoutSeconds int64) (masterId, replicaId string, cleanup func(skip bool)) {

    fmt.Println("Starting master-replica example, and pausing while example sleeps for 20 seconds")
    cleanup = startDockerExampleForTest(t, basePath, "master-replica")

    var err error

    fmt.Printf("\nWaiting maximum of %d seconds for master container", timeoutSeconds)
    masterId, err = waitForPostgresContainer(docker, "master", timeoutSeconds)
    if err != nil {
        t.Fatal("master container did not start")
    }
    t.Log("Started master container: " + masterId)

    fmt.Printf("\nWaiting maximum of %d seconds for replica container", timeoutSeconds)
    replicaId, err = waitForPostgresContainer(docker, "replica", timeoutSeconds)
    if err != nil {
        t.Fatal("replica container did not start")
    }
    t.Log("Started replica container: " + replicaId)

    return
}
