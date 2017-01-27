package cct

import (
    "testing"
    "os"
    // "path"

    "github.com/docker/docker/client"
)


// docker basic example expects one container named "basic", running crunchy-postgres\
func TestDockerBackup(t *testing.T) {
    const exampleName = "backup"
    const exampleTimeoutSeconds = 90

    buildBase := os.Getenv("BUILDBASE")
    if buildBase == "" {
    	t.Fatal("Please set BUILDBASE environment variable to run tests.")
    }

    // TestMinSupportedDockerVersion 1.18 seems to work fine?
    
    t.Log("Initializing docker client")
    docker, err := client.NewEnvClient()
    if err != nil {
        t.Fatal(err)
    }

    defer docker.Close()

    /////////// docker is available; run basic, then backup
    t.Log("Starting Example: docker/basic")
    basicCleanup, basicOut, err := startDockerExample(buildBase, "basic")
    if err != nil {
        t.Fatal(err, basicOut)
    }
    basicId, err := waitForPostgresContainer(docker, "basic", 60)
    t.Log("Started container ", basicId)


    /////////// basic has started, run backup
    t.Log("Starting Example: docker/" + exampleName)
    pathToCleanup, cmdOut, err := startDockerExample(buildBase, exampleName)
    if err != nil {
    	t.Fatal(err, cmdOut)
    }

    c, err := ContainerFromName(docker, "backup")
    if err != nil {
        return
    }
    containerId := c.ID
    t.Log("Started container ", containerId)

    // verify labels match build
    testCCPLabels(docker, containerId, t)

    t.Log(pathToCleanup, cmdOut, basicCleanup, basicId)

    ///////// completed tests, cleanup
    t.Log("Calling cleanup: " + pathToCleanup)
    cmdout, err = cleanupExample(pathToCleanup)
    if err != nil {
        t.Fatal(err, cmdout)
    }
    t.Log(cmdout)
    cmdout, err = cleanupExample(basicCleanup)

    t.Log("All tests complete")
}
