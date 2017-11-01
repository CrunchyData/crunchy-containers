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
    "os"
    "testing"

    "github.com/docker/docker/client"
)

// verifies that container exists, and returns containerId. Checks that container labels match the build environment variables.
func testContainer(
    t *testing.T,
    testName string,
    docker *client.Client,
    containerName string) (containerId string) {

    t.Run(testName, func (t *testing.T) {
        if c, err := ContainerFromName(docker, containerName); err != nil {
            t.Fatal(err)
        } else {
            containerId = c.ID
        }
        t.Logf("Found %s container: %s\n", containerName, containerId)
    })

    // verify labels match build
    t.Run("Labels", func (t *testing.T) {
        testLabels(t, docker, containerId)
    })

    return
}

// same as testContainer, but does not check for PostgresVersion label
func testContainerNoVersion(
    t *testing.T,
    testName string,
    docker *client.Client,
    containerName string) (containerId string) {

    t.Run(testName, func (t *testing.T) {
        if c, err := ContainerFromName(docker, containerName); err != nil {
            t.Fatal(err)
        } else {
            containerId = c.ID
        }
        t.Logf("Found %s container: %s\n", containerName, containerId)
    })

    // verify labels match build
    t.Run("Labels", func (t *testing.T) {
        testReleaseLabel(t, docker, containerId)
    })

    return
}

// Compares an environment variable value to a container's label value
func testLabelMatchesEnv(
    t *testing.T,
    testName string,
    labels map[string]string,
    label string,
    env string) {

    envVal := os.Getenv(env)
    if envVal == "" {
        t.Errorf("The %s environment variable is not set.\n", env)
    }
    t.Run(testName, func (t *testing.T) {
        if ok, found, err := assertLabel(
            labels, label, envVal); err != nil {
            t.Error(err)
        } else if ! ok {
            t.Errorf("Expected the %s label to have the value: %s\nFound: %s\n",
                label, envVal, found)
        }
    })
}

// Checks the Release label matches $CCP_VERSION on build env
func testReleaseLabel(
    t *testing.T,
    docker *client.Client,
    containerId string) {

    labels, err := getLabels(docker, containerId)
    if err != nil {
        t.Error(err)
    }

    testLabelMatchesEnv(
        t, "CheckReleaseLabel",
        labels,
        "Release",
        "CCP_VERSION")
}

// Checks that PostgresVersion and Release labels match build environment
func testLabels(
    t *testing.T,
    docker *client.Client, 
    containerId string) {

    labels, err := getLabels(docker, containerId)
    if err != nil {
        t.Error(err)
    }

    testLabelMatchesEnv(
        t, "CheckPostgresVersionLabel",
        labels,
        "PostgresVersion",
        "CCP_PGVERSION")

    testLabelMatchesEnv(
        t, "CheckReleaseLabel",
        labels,
        "Release",
        "CCP_VERSION")
}
