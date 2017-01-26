package cct

import (
    "testing"
    "os"
    // "path"

    "github.com/docker/docker/client"
)

// docker basic example expects one container named "basic", running crunchy-postgres\
func TestDockerBackup(t *testing.T) {
    const testName = "backup"
    const testInitTimeoutSeconds = 40
    const dependsOnTestName = "basic"

    buildBase := os.Getenv("BUILDBASE")
    if buildBase == "" {
    	t.Fatal("Please set BUILDBASE environment variable to run tests.")
    }

    // pathToTest := path.Join(
    // 	buildBase, "examples", "docker", testName, "run.sh")
    // pathToCleanup := path.Join(
    // 	buildBase, "examples", "docker", testName, "cleanup.sh")

    // dependsOnTest := path.Join(
    // 	buildBase, "examples", "docker", dependsOnTestName, "run.sh")
    // dependsOnCleanup := path.Join(
    // 	buildBase, "examples", "docker", dependsOnTestName, "cleanup.sh")

    // TestMinSupportedDockerVersion 1.18 seems to work fine?
    
    t.Log("Initializing docker client")
    docker, err := client.NewEnvClient()
    if err != nil {
        t.Fatal(err)
    }

    defer docker.Close()

    // /////////// docker is available, run the example
    // t.Log("Starting Example: docker/" + dependsOnTestName)
    // t.Log("Starting Example: docker/" + testName)
    // cmdout, err := exec.Command(pathToTest).CombinedOutput()
    // t.Logf("%s\n", cmdout)
    // if err != nil {
    // 	t.Fatal(err)
    // }

    // c, err := ContainerFromName(docker, "basic")
    // if err != nil {
    // 	t.Fatal(err)
    // }

    // testCCPLabels(docker, c.ID, t)
}
