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

func TestDockerPgBouncer(t *testing.T) {

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

    fmt.Println("Starting pgbouncer example")
    bouncerCleanup := startDockerExampleForTest(t, buildBase, "pgbouncer")
    defer bouncerCleanup(skipCleanup)

    containerId := testContainer(t, "PgBouncerContainer", docker, "pgbouncer")
    if t.Failed() {
        t.Fatal("Cannot proceed")
    }

    fmt.Println("Sleep 3 to allow pgbouncer to startup")
    time.Sleep(3 * time.Second)


    if t.Run("TestPrimary", func (t *testing.T) {
        conStr, err := buildConnectionString(docker, containerId, "master", testuser)
        if err != nil {
            t.Fatal(err)
        }

        t.Logf("PRIMARY connection string is %s\n", conStr)
        if ok, err := isAcceptingConnectionString(conStr); err != nil {
            t.Fatal(err)
        } else if ! ok {
            t.Fatal("Could not connect to pgbouncer")
        }
        t.Run("TestInsert", func (t *testing.T) {
            facts, err := writeSomeData(docker, containerId, "master")
            if err != nil {
                t.Fatal(err)
            }
            t.Logf("Inserted %v rows\n", facts.rowcount)
        })
    }); t.Failed() {
        t.Fatal("Cannot proceed")
    }


    if t.Run("TestReplica", func (t *testing.T) {
        conStr, err := buildConnectionString(docker, containerId, "replica", testuser)
        if err != nil {
            t.Fatal(err)
        }

        t.Logf("REPLICA connection string is %s\n", conStr)
        if ok, err := isAcceptingConnectionString(conStr); err != nil {
            t.Fatal(err)
        } else if ! ok {
            t.Fatal("Could not connect to pgbouncer")
        }

        t.Run("TestNoInsert", func (t *testing.T) {
            _, err := writeSomeData(docker, containerId, "replica")
            if !isReadOnlyErr(err) {
                t.Fatal(err)
            }
        })

    }); t.Failed() {
        t.Fatal("Cannot proceed")
    }

    t.Log("All tests complete.")
}
