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
	"bufio"
    "context"
    "fmt"
    "path"
    "time"
    "strings"

    "github.com/docker/docker/client"
    "github.com/docker/docker/api/types"
    "github.com/docker/docker/api/types/container"
    "github.com/docker/docker/api/types/network"
    "github.com/docker/docker/api/types/strslice"
)

import "io/ioutil"

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

func statBackupLabel(
    docker *client.Client,
    containerId string,
    backup string) (ok bool, err error) {

	pathToBackup := path.Join("/pgdata/basic-backups", backup, "backup_label")

	fmt.Println("STAT " + pathToBackup)
    stat, err := docker.ContainerStatPath(
        context.Background(),
        containerId,
        pathToBackup)
    if err != nil {
        if strings.HasPrefix(string(err.Error()),
            "Error: request returned Not Found") {
            ok, err = false, nil
            return
        }
        return
    }
    fmt.Println(stat)

    ok = (stat.Size > 0)
    return
}

func statBackupPath(
    docker *client.Client,
    containerId string,
    backup string) (ok bool, err error) {

	pathToBackup := path.Join("/pgdata/basic-backups", backup)

	fmt.Println("STAT " + pathToBackup)
    stat, err := docker.ContainerStatPath(
        context.Background(),
        containerId,
        pathToBackup)
    if err != nil {
        if strings.HasPrefix(string(err.Error()),
            "Error: request returned Not Found") {
            ok, err = false, nil
            return
        }
        return
    }
    fmt.Println(stat)

    ok = (stat.Size > 0)
    return
}

func lsBackups(
    docker *client.Client,
    fromContainerName string,
    localBackupPath string) (ok bool, name string, err error) {

    conf := container.Config{
        User: "postgres",
        Cmd: strslice.StrSlice{"-l", localBackupPath},
        Entrypoint: strslice.StrSlice{"ls"},
        Image: "crunchy-backup",
    }
    hostConf := container.HostConfig{
        VolumeDriver: "local",
        VolumesFrom: strslice.StrSlice{fromContainerName},
    }

    c, err := docker.ContainerCreate(
        context.Background(),
        &conf,
        &hostConf,
        &network.NetworkingConfig{}, 
        "ls-backup-ls")
    if err != nil {
        return
    }

    defer func () {
        if e := docker.ContainerRemove(
            context.Background(),
            c.ID,
            types.ContainerRemoveOptions{
                RemoveVolumes: true,
                Force: true,
            }); e != nil {
            err = e
        }
    } ()

    err = docker.ContainerStart(context.Background(), c.ID, types.ContainerStartOptions{})
    if err != nil {
        return
    }

    logReader, err := docker.ContainerLogs(
        context.Background(),
        c.ID,
        types.ContainerLogsOptions{
            ShowStdout: true,
            ShowStderr: true,
            Follow: true,
            Details: true,
        })
    defer logReader.Close()
    if err != nil {
        return
    }

    b, err := ioutil.ReadAll(logReader)
    if err != nil {
    	return
    }

    fmt.Printf("RESULT OF ls -l %s\n%s", localBackupPath, b)

    // name = strings.TrimLeft(name,
    //     string([]byte{1, 0, 0, 0, 0, 0, 0, 21, 32}))

    return
}


// starts a container that takes volumes-from fromContainerName (a backup container)
func getBackupName(
    docker *client.Client,
    fromContainerName string,
    localBackupPath string) (ok bool, name string, err error) {

    conf := container.Config{
        User: "postgres",
        Cmd: strslice.StrSlice{"-t", localBackupPath},
        Entrypoint: strslice.StrSlice{"ls"},
        Image: "crunchy-backup",
    }
    hostConf := container.HostConfig{
        VolumeDriver: "local",
        VolumesFrom: strslice.StrSlice{fromContainerName},
    }

    c, err := docker.ContainerCreate(
        context.Background(),
        &conf,
        &hostConf,
        &network.NetworkingConfig{}, 
        "ls-backup")
    if err != nil {
        return
    }

    defer func () {
        if e := docker.ContainerRemove(
            context.Background(),
            c.ID,
            types.ContainerRemoveOptions{
                RemoveVolumes: true,
                Force: true,
            }); e != nil {
            err = e
        }
    } ()

    err = docker.ContainerStart(context.Background(), c.ID, types.ContainerStartOptions{})
    if err != nil {
        return
    }

    logReader, err := docker.ContainerLogs(
        context.Background(),
        c.ID,
        types.ContainerLogsOptions{
            ShowStdout: true,
            ShowStderr: true,
            Follow: true,
            Details: true,
        })
    defer logReader.Close()
    if err != nil {
        return
    }

    // read the first line from the docker log (result of ls -t /pgdata/basic-backups)
    scanner := bufio.NewScanner(logReader)

    ok = scanner.Scan()
    if ! ok {
        err = scanner.Err()
        return
    }
    name = scanner.Text()

    name = strings.TrimLeft(name,
        string([]byte{1, 0, 0, 0, 0, 0, 0, 21, 32}))

    _, _, err = lsBackups(docker, c.ID, path.Join("/pgdata/basic-backups", name))

    ok, err = statBackupPath(docker, c.ID, name)
    // ok = true

    return
}
