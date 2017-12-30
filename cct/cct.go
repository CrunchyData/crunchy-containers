/*
 Copyright 2018 Crunchy Data Solutions, Inc.
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

// return OS CCPROOT variable, or fail test
func getBuildBase(t *testing.T) (buildBase string) {

    buildBase = os.Getenv("CCPROOT")
    if buildBase == "" {
        t.Fatal("Please set CCPROOT environment variable to run tests.")
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
