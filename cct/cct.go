/*
 Copyright 2016 Crunchy Data Solutions, Inc.
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
	// "fmt"
    "path"
    // "reflect"
    "strings"
    // "time"
 	
    "github.com/docker/docker/api/types"
    // "github.com/docker/docker/api/types/container"
    // "github.com/docker/docker/api/types/network"
    "github.com/docker/docker/api/types/filters"
	"github.com/docker/docker/client"
)

// func main() {
//     docker, err := client.NewEnvClient()
//     if err != nil {
//         panic(err)
//     }
//     defer docker.Close()

//     c, err := ContainerFromName(docker, "basic")
//     if err != nil {
//         panic(err)
//     }
//     // fmt.Println(c)

//     i, err := isPostgresReady(docker, c.ID)
//     if err != nil {
//         panic(err)
//     }

//     fmt.Printf("Postgres is ready: %t\n", i)

//     fmt.Println("Kthnxbai")
// }

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

// returns the HostIP and Port reported by the service on 5432/tcp, which should always be postgresql
func pgHostFromContainer(docker *client.Client, 
    containerId string) (host string, port string, err error) {

    inspect, err := docker.ContainerInspect(
        context.Background(), containerId)
    if err != nil {
        return
    }
    binding := inspect.HostConfig.PortBindings["5432/tcp"][0]

    host, port = binding.HostIP, binding.HostPort
    return
}

// wraps pg_isready via docker exec
func isPostgresReady(
    docker *client.Client,
    containerId string) (isready bool, err error) {

    pgroot, err := envValueFromContainer(docker, containerId, "PGROOT")
    if err != nil {
        return
    }    
    cmd := []string{path.Join(pgroot, "bin/pg_isready")}

    execConf := types.ExecConfig{
        User: "postgres",
        Detach: true,
        Cmd: cmd,
    }
    execId, err := docker.ContainerExecCreate(
        context.Background(), containerId, execConf)
    if err != nil {
        return
    }

    err = docker.ContainerExecStart(
        context.Background(), execId.ID, types.ExecStartCheck{})
    if err != nil {
        return
    }

    inspect, err := docker.ContainerExecInspect(
        context.Background(), execId.ID) 
    if err != nil {
        return
    }

    isready = (inspect.ExitCode == 0)
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

    state := inspect.State
    isrunning = state.Running
    return 
}

// returns Container object associated with container name
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
    c = containers[0]
    return
}
