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
    "fmt"
    "os"
    "testing"

    "github.com/docker/docker/client"
)

// all example user passwords are the same
const pgpassword string = "password"
const testuser string = "testuser"
const userdb string = "userdb"

// create connection string for postgres user on postgres database
func conStrTestPostgres(
    t *testing.T,
    docker *client.Client,
    containerId string) (conStr string) {
 
    conStr, err := buildConnectionString(
        docker, containerId, "postgres", "postgres")
    if err != nil {
        t.Fatal(err)
    }

    return conStr
}

// create connection string for testuser user on userdb database
func conStrTestUser(
    t *testing.T,
    docker *client.Client,
    containerId string) (conStr string) {
 
    conStr, err := buildConnectionString(
        docker, containerId, userdb, testuser)
    if err != nil {
        t.Fatal(err)
    }

    return conStr
}

// return a simple connection string to docker host with password in plaintext
func buildConnectionString(
    docker *client.Client,
    containerId string, 
    database string, 
    user string) (conStr string, err error) {

    host, port, err := pgHostFromContainer(docker, containerId)
    if err != nil {
        return
    }

    if host == "" {
        dockerHost := os.Getenv("DOCKER_HOST")
        if dockerHost == "" {
            host = "localhost"
        } else {
            host = dockerHost
        }
    }
    conStr = fmt.Sprintf("host=%s port=%s dbname=%s user=%s password=%s sslmode=disable",
        host, port, database, user, pgpassword)
    return
}