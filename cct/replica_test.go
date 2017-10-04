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
	// "fmt"
	"testing"
)


func TestDockerReplica(t *testing.T) {

    // const exampleName = "primary-replica"
    const timeoutSeconds = 60
    const skipCleanup = false

    buildBase := getBuildBase(t)

    docker := getDockerTestClient(t)
    defer docker.Close()

    masterId, replicaId, cleanup := startPrimaryReplica(t, docker, buildBase, timeoutSeconds)
    defer cleanup(skipCleanup)

    conStr := conStrTestPostgres(t, docker, masterId)

    if t.Run("ReplicationStarted", func (t *testing.T) {
    	if ok, err := isReplicationStarted(conStr); err != nil {
    		t.Error(err)
    	} else if ! ok {
    		t.Error("Replication has not started")
    	}
    }); t.Failed() {
    	t.Fatal("Cannot proceed")
    }

    t.Log("Write some data to master")
    facts, err := writeSomeData(docker, masterId, userdb)
    if err != nil {
        t.Error(err)
    }

    t.Log("Waiting for replay")
    if err := waitForReplay(conStr, timeoutSeconds); err != nil {
    	t.Fatal(err)
    }

    t.Run("CheckReplica", func (t *testing.T) {
        ok, found, err := assertSomeData(docker, replicaId, userdb, facts)
        if err != nil {
        	t.Error(err)
        }
        if ! ok {
        	t.Errorf("Expected %n rows, %n bytes\nfound %n rows, %n bytes\n",
                facts.rowcount, facts.relsize, found.rowcount, found.relsize)
        }
    })

    t.Log("All tests complete")
}
