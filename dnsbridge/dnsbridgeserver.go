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

package main

import (
	"errors"
	"github.com/crunchydata/crunchy-containers/dnsbridgeapi"
	dockerapi "github.com/fsouza/go-dockerclient"
	"log"
	"os"
	"strconv"
	"time"
)

var MAX_TRIES = 3

const delaySeconds = 5
const delay = (delaySeconds * 1000) * time.Millisecond

var DOCKER_URL string
var TTL uint64
var DOMAIN string

var logger *log.Logger
var CONSUL_URL string

func main() {
	logger = log.New(os.Stdout, "logger: ", log.Lshortfile|log.Ldate|log.Ltime)
	var VERSION = os.Getenv("CCP_VERSION")

	logger.Println("dnsbridgeserver " + VERSION + ": starting")

	getEnvVars()

	var dockerConnected = false
	var tries = 0
	var docker *dockerapi.Client
	var err error
	for tries = 0; tries < MAX_TRIES; tries++ {
		docker, err = dockerapi.NewClient(DOCKER_URL)
		err = docker.Ping()
		if err != nil {
			logger.Println("could not ping docker host")
			logger.Println("sleeping and will retry in %d sec\n", delaySeconds)
			time.Sleep(delay)
		} else {
			logger.Println("no err in connecting to docker")
			dockerConnected = true
			break
		}
	}

	if dockerConnected == false {
		logger.Println("failing, could not connect to docker after retries")
		panic("cant connect to docker")
	}

	events := make(chan *dockerapi.APIEvents)
	assert(docker.AddEventListener(events))
	logger.Println("dnsbridgeserver: Listening for Docker events...")
	for msg := range events {
		switch msg.Status {
		//case "start", "create":
		case "start":
			logger.Println("event: " + msg.Status + " ID=" + msg.ID + " From:" + msg.From)
			dnsbridgeapi.Action(logger, msg.Status, msg.ID, docker, TTL, CONSUL_URL, DOMAIN)
		case "stop":
			logger.Println("event: " + msg.Status + " ID=" + msg.ID + " From:" + msg.From)
			dnsbridgeapi.Action(logger, msg.Status, msg.ID, docker, TTL, CONSUL_URL, DOMAIN)
		case "destroy":
			logger.Println("event: " + msg.Status + " ID=" + msg.ID + " From:" + msg.From)
			dnsbridgeapi.Action(logger, msg.Status, msg.ID, docker, TTL, CONSUL_URL, DOMAIN)
		case "die":
			logger.Println("event: " + msg.Status + " ID=" + msg.ID + " From:" + msg.From)
		default:
			logger.Println("event: " + msg.Status)
		}
	}

}

func getEnvVars() error {
	var err error
	CONSUL_URL = os.Getenv("CONSUL_URL")
	if CONSUL_URL == "" {
		logger.Println("error in CONSUL_URL env var, not set")
		return errors.New("CONSUL_URL env var not set")
	}
	logger.Printf("dnsbridgeserver: CONSUL_URL %s\n", CONSUL_URL)
	DOCKER_URL = os.Getenv("DOCKER_URL")
	if DOCKER_URL == "" {
		logger.Println("error in DOCKER_URL env var, not set")
		return errors.New("DOCKER_URL env var not set")
	}
	logger.Printf("dnsbridgeserver: DOCKER_URL %s\n", DOCKER_URL)
	var tempTTL = os.Getenv("TTL")
	if tempTTL == "" {
		logger.Println("error in TTL env var, not set, using default")
		TTL = 36000000
	}
	TTL, err = strconv.ParseUint(tempTTL, 10, 64)
	if err != nil {
		return err
	}
	logger.Printf("dnsbridgeserver: TTL %d\n", TTL)
	return err

}

func assert(err error) {
	if err != nil {
		logger.Println("skybridge: ", err)
		panic("can't continue")
	}
}
