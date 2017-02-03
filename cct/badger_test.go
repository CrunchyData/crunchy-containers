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
	"testing"
	"fmt"
	"io/ioutil"
	"net/http"
)

func TestDockerBadger(t *testing.T) {

	// const exampleName = "badger"
    const timeoutSeconds = 60
    const skipCleanup = false

    buildBase := getBuildBase(t)

    docker := getDockerTestClient(t)
    defer docker.Close()

    fmt.Printf("Waiting maximum of %d seconds for basic container to start", timeoutSeconds)
    _, basicCleanup := startBasic(t, docker, buildBase, timeoutSeconds)
    defer basicCleanup(skipCleanup)

    /////////// basic has started, run pgbadger
    cleanup := startDockerExampleForTest(t, buildBase, "badger")
    defer cleanup(skipCleanup)

    // discard badger containerId, we will not need it
    _ = testContainer(t, "BadgerContainer", docker, "badger")
    if t.Failed() {
        t.Fatal("Cannot proceed")
    }

	t.Run("GenerateReport", func (t *testing.T) {
		response, err := http.Get("http://127.0.0.1:14000/api/badgergenerate")
		if err != nil {
			t.Fatal(err)
		}
		defer response.Body.Close()

		if body, err := ioutil.ReadAll(response.Body);
		err != nil {
			t.Fatal(err)
		} else if len(body) == 0 {
			t.Fatal("No response")
		}
	})

    t.Log("All tests complete.")
}
