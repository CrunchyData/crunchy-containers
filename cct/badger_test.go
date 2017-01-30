package cct

import (
	"testing"
	"fmt"
	"io/ioutil"
	"net/http"
)

func TestDockerBadger(t *testing.T) {
	const exampleName = "badger"
    const exampleTimeoutSeconds = 90

    buildBase := getBuildBase(t)

    docker := getDockerTestClient(t)
    defer docker.Close()

    fmt.Printf("Waiting maximum of %d seconds for basic container to start", exampleTimeoutSeconds)
    /////////// docker is available; run basic, then pgbadger
    t.Log("Starting Example: docker/basic")
    basicCleanup, cmdout, err := startDockerExample(buildBase, "basic")
    if err != nil {
        t.Fatal(err, cmdout)
    }
    basicId, err := waitForPostgresContainer(docker, "basic", exampleTimeoutSeconds)
    t.Log("Started basic container: ", basicId)

    /////////// basic has started, run pgbadger
    t.Log("Starting Example: docker/" + exampleName)
    pathToCleanup, cmdout, err := startDockerExample(buildBase, exampleName)
    if err != nil {
    	t.Fatal(err, cmdout)
    }

    c, err := ContainerFromName(docker, "badger")
    if err != nil {
        return
    }
    containerId := c.ID
    t.Log("Started badger container: " + containerId)

    // verify labels match build
	t.Run("Container", func (t *testing.T) {
		testCCPLabels(docker, containerId, t)
	})

	t.Run("GenerateReport", func (t *testing.T) {
		response, err := http.Get("http://127.0.0.1:14000/api/badgergenerate")
		if err != nil {
			t.Fatal(err)
		}
		defer response.Body.Close()

		body, err := ioutil.ReadAll(response.Body)
		if err != nil {
			t.Fatal(err)
		}
		if len(body) == 0 {
			t.Fatal("No response")
		}
	})

    ///////// completed tests, cleanup
    t.Log("Cleaning up badger: ", pathToCleanup)
    cmdout, err = cleanupExample(pathToCleanup)
    if err != nil {
        t.Error(err, cmdout)
    }
    t.Log(cmdout)

    // cleanup basic container
    t.Log("Cleaning up basic: ", basicCleanup)
    cmdout, err = cleanupExample(basicCleanup)
    if err != nil {
        t.Error(err, cmdout)
    }
    t.Log(cmdout)
}
