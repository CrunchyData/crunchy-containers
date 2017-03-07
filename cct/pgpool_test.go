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
    "fmt"
    "testing"
    "time"
)

func TestDockerPgPool(t *testing.T) {

    // const exampleName = "pgpool"
    const timeoutSeconds = 60
    const skipCleanup = false

    buildBase := getBuildBase(t)

    docker := getDockerTestClient(t)
    defer docker.Close()

    // masterId, replicaId
    masterId, _, cleanup := startMasterReplica(t, docker, buildBase, timeoutSeconds)
    defer cleanup(skipCleanup)

    if t.Run("ReplicationStarted", func (t *testing.T) {
        conStr := conStrTestPostgres(t, docker, masterId)

        if ok, err := isReplicationStarted(conStr); err != nil {
            t.Error(err)
        } else if ! ok {
            t.Error("Replication has not started")
        }
    }); t.Failed() {
        t.Fatal("Cannot proceed")
    }

    fmt.Println("Starting pgpool example")
    poolCleanup := startDockerExampleForTest(t, buildBase, "pgpool")
    defer poolCleanup(skipCleanup)

    containerId := testContainer(t, "PgPoolContainer", docker, "pgpool")
    if t.Failed() {
        t.Fatal("Cannot proceed")
    }

    conStr := conStrTestUser(t, docker, containerId)

    fmt.Println("Sleep 3 to allow pgpool to startup")
    time.Sleep(3 * time.Second)

    if t.Run("TestConnect", func (t *testing.T) {
        if ok, err := isAcceptingConnectionString(conStr); err != nil {
            t.Fatal(err)
        } else if ! ok {
            t.Fatal("Could not connect to pgpool")
        }
    }); t.Failed() {
        t.Fatal("Cannot proceed")
    }

    t.Run("TestInsert", func (t *testing.T) {
        if _, err := insertTestTable(conStr);
        err != nil {
            t.Fatal(err)
        }
    })
    t.Log("All tests complete.")
}