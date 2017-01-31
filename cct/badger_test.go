package cct

import (
	"testing"
	"fmt"
	"io/ioutil"
	"net/http"
)

func TestDockerBadger(t *testing.T) {
	const exampleName = "badger"
    const timeoutSeconds = 90
    const skipCleanup = true

    buildBase := getBuildBase(t)

    docker := getDockerTestClient(t)
    defer docker.Close()

    fmt.Printf("Waiting maximum of %d seconds for basic container to start", timeoutSeconds)
    basicCleanup, _ := startBasic(t, docker, buildBase, timeoutSeconds)
    defer basicCleanup(skipCleanup)

    /////////// basic has started, run pgbadger
    cleanup := startDockerExampleForTest(t, buildBase, exampleName)
    defer cleanup(skipCleanup)

    var containerId string
    if t.Run("StartContainer", func (t *testing.T) {
        c, err := ContainerFromName(docker, "badger")
        if err != nil {
            t.Fatal(err)
        }
        containerId = c.ID
        t.Log("Started badger container: " + containerId)
    }); t.Failed() {
        t.Fatal("Cannot proceed")
    }

    // verify labels match build
	t.Run("Labels", func (t *testing.T) {
		testCCPLabels(docker, containerId, t)
	})

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
