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
	"context"
	"fmt"
    "os"
    "strings"
    "testing"
 	
    "github.com/docker/docker/api/types"
    "github.com/docker/docker/api/types/filters"
	"github.com/docker/docker/client"
)

// returns Container id associated with container name
func ContainerFromName(
    docker *client.Client,
    containerName string) (c types.Container, err error) {

    args := filters.NewArgs()
    args.Add("name", containerName)

    listOpts := types.ContainerListOptions{
        Filters: args,
    }
    containers, err := docker.ContainerList(
        context.Background(), listOpts)
    if err != nil {
        return
    }
    if len(containers) == 0 {
        err = fmt.Errorf("Container Not Found: %s", containerName)
        return
    }
    c = containers[0]
    return
}

// return OS BUILDBASE variable, or fail test
func getBuildBase(t *testing.T) (buildBase string) {

    buildBase = os.Getenv("BUILDBASE")
    if buildBase == "" {
        t.Fatal("Please set BUILDBASE environment variable to run tests.")
    }

    return
}

// return OS BUILDBASE variable, or fail test
func getPgVersion(t *testing.T) (pgVersion string) {

    pgVersion = os.Getenv("CCP_PGVERSION")
    if pgVersion == "" {
        t.Fatal("Please define CCP_PGVERSION environment variable to run tests.")
    }

    return
}

// responsibility of caller to call docker.Close()
func getDockerTestClient(t *testing.T) (docker *client.Client) {

    t.Log("Initializing docker client")
    docker, err := client.NewEnvClient()
    if err != nil {
        t.Fatal(err)
    }

    return
}

// assert the named environment value in the container context (envVar) is value
func assertEnvValue(
    docker *client.Client,
    containerId string,
    envVar string,
    value string) (ok bool, foundval string, err error) {

    foundval, err = envValueFromContainer(docker, containerId, envVar)
    if err != nil {
        return
    }

    ok = (foundval==value)
    return
}

// returns the value of environment variable defined in current context of container
func envValueFromContainer(
    docker *client.Client,
    containerId string,
    envVar string) (value string, err error) {

    inspect, err := docker.ContainerInspect(
        context.Background(), containerId)
    if err != nil {
        return
    }

    env := inspect.Config.Env
    for _, e := range env {
        if strings.HasPrefix(e, envVar) {
            value = strings.Split(e, "=")[1]
            break
        }
    }
    return
}

// container state is running?
func isContainerRunning(
    docker *client.Client, 
    containerId string) (isrunning bool, err error) {

    inspect, err := docker.ContainerInspect(context.Background(), containerId)
    if err != nil {
        return
    }

    isrunning = inspect.State.Running
    return 
}

// container is dead?
func isContainerDead(
    docker *client.Client,
    containerId string) (isdead bool, err error) {

    inspect, err := docker.ContainerInspect(context.Background(), containerId)
    if err != nil {
        return
    }

    isdead = inspect.State.Dead
    return
}

// returns the map of labels assigned to this container
func getLabels(
    docker *client.Client,
    containerId string) (labels map[string]string, err error) {

    inspect, err := docker.ContainerInspect(context.Background(), containerId)
    if err != nil {
        return
    }

    labels = inspect.Config.Labels
    return
}

// assert a specified label is set to a value found in a Labels string map (use getLabels(docker, containerId))
func assertLabel(
    labels map[string]string,
    label string,
    value string) (ok bool, foundvalue string, err error) {

    if v, ok := labels[label]; ! ok {
        err = fmt.Errorf("Label Not Found: %s", label)
    } else {
        foundvalue = v
    }

    ok = (foundvalue == value)
    return
}

// type dirStat struct {
//     Path string
//     Owner string
//     Group string
//     Mode os.FileMode
// }

// func assertDirectory(
//     docker *client.Client,
//     containerId string,
//     s dirStat) (ok bool, found dirStat, err error) {

//     stat, err := docker.ContainerPathStat(context.Background(), containerId, s.Path)
//     if err != nil {
//         err = fmt.Errorf("Error trying to stat path %s\n%s", s.Path, err.Error())
//         return
//     }

//     cmd := []string{"stat", "-c", "\"%U %G\"", s.Path}

//     execConf := types.ExecConfig{
//         User: "postgres",
//         AttachStdout: true,
//         AttachStderr: true,
//         Cmd: cmd,
//     }
//     execId, err := docker.ContainerExecCreate(
//         context.Background(), containerId, execConf)
//     if err != nil {
//         return
//     }

//     err = docker.ContainerExecStart(
//         context.Background(), execId.ID, types.ExecStartCheck{})
//     if err != nil {
//         return
//     }

//     response, err := client.ContainerExecAttach(
//         context.Background(), execId.ID, execConf)
//     if err != nil {
//         return
//     }
//     defer response.Close()

//     out, err := ioutil.ReadAll(response.Reader)
//     if err != nil {
//         return
//     }

//     fmt.Println(string(out[:]))

//     return ok, s, nil
// }
