package cct

import (
    "testing"
    "os"
    "time"

    "github.com/docker/docker/client"
)

func waitForBackup(
    docker *client.Client,
    containerId string,
    timeoutSeconds int64) (ok bool, err error) {

    ok = false

    conStr, err := buildConnectionString(
        docker, containerId, "postgres", "postgres")
    if err != nil {
        return
    }

    doneC := make(chan bool)
    timer := time.AfterFunc(time.Second * time.Duration(timeoutSeconds), func () {
        close(doneC)
    })
    ticker := time.NewTicker(time.Millisecond * 100)

    tick := func () error {
        if isrun, err := isContainerRunning(docker, containerId); err != nil {
            return err
        } else if ! isrun {
            close(doneC)
        }
        if bkup, err := isInBackup(conStr); err != nil {
            return err
        } else if ! bkup {
            ok = true
            close(doneC)
        }
        return nil
    }

    for {
        select {
        case <- ticker.C:
            err = tick()
            if err != nil {
                close(doneC)
            }
        case <- doneC:
            _ = timer.Stop()
            return
        }
    }
}

func getBackupName(
    docker *client.Client,
    string fromContainerName) (name string, err error) {


    conf := container.Config{
        User: postgres,
        Cmd: "ls",
        Image: "crunchy-backup",
        WorkingDir: "/pgdata/basic",
    }
    hostConf := container.HostConfig{
        VolumeDriver: "local",
    }

    createBody, err = docker.ContainerCreate(
        context.Background(),
        &conf,
        &hostConf,
        &network.NetworkingConfig{}, 
        containerName)
    if err != nil {
        return
    }

    return


}

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
    basicCleanup, cmdout, err := startDockerExample(buildBase, "basic")
    if err != nil {
        t.Fatal(err, cmdout)
    }
    basicId, err := waitForPostgresContainer(docker, "basic", 60)
    t.Log("Started container ", basicId)


    /////////// basic has started, run backup
    t.Log("Starting Example: docker/" + exampleName)
    pathToCleanup, cmdout, err := startDockerExample(buildBase, exampleName)
    if err != nil {
    	t.Fatal(err, cmdout)
    }

    c, err := ContainerFromName(docker, "basicbackup")
    if err != nil {
        return
    }
    containerId := c.ID
    t.Log("Started basicbackup container: ", containerId)

    // verify labels match build
    testCCPLabels(docker, containerId, t)

    // wait for backup to finish on basic container
    ok, err := waitForBackup(docker, basicId, exampleTimeoutSeconds)
    if err != nil {
        t.Fatal(err)
    } else if ! ok {
        t.Fatalf("Backup did not complete after %n seconds.\n", exampleTimeoutSeconds)
    }

    // we will test the backup by trying to restore
    name, err := getBackupName(docker, "basicbackup")
    if err != nil {
        t.Fatal(err)
    }
    if name == "" {
        t.Fatalf("No backup found in basicbackup container.")
    }

    restoreCleanup, cmdout, err := startDockerExample(buildBase, "restore", name)
    if err != nil {
        t.Error(err, cmdout)
    }

    ///////// completed tests, cleanup
    t.Log("Calling cleanup: " + pathToCleanup)
    cmdout, err = cleanupExample(pathToCleanup)
    if err != nil {
        t.Error(err, cmdout)
    }
    t.Log(cmdout)

    // cleanup basic container
    cmdout, err = cleanupExample(basicCleanup)
    if err != nil {
        t.Error(err, cmdout)
    }
    t.Log(cmdout)

    // cleanup master-restore container
    cmdout, err = cleanupExample(restoreCleanup)
    if err != nil {
        t.Error(err, cmdout)
    }
    t.Log(cmdout)

    t.Log("All tests complete")
}
