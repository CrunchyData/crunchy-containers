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
	"database/sql"
	"errors"
	"github.com/crunchydata/crunchy-containers/collectapi"
	"log"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"
)

var POLL_INT = int64(3)
var PG_ROOT_PASSWORD string
var PG_PORT = "5432"
var HOSTNAME string
var PROM_GATEWAY = "http://crunchy-scope:9091"

var logger *log.Logger

func main() {
	logger = log.New(os.Stdout, "logger: ", log.Lshortfile|log.Ldate|log.Ltime)
	//set up signal catcher logic
	sigs := make(chan os.Signal, 1)
	done := make(chan bool, 1)
	signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		sig := <-sigs
		logger.Println(sig)
		done <- true
		logger.Println("collectserver caught signal, exiting...")
		os.Exit(0)
	}()

	var VERSION = os.Getenv("CCP_VERSION")

	logger.Println("collectserver " + VERSION + ": starting")

	getEnvVars()

	logger.Printf("collectserver: POLL_INT %d\n", POLL_INT)
	logger.Printf("collectserver: HOSTNAME %s\n", HOSTNAME)
	logger.Printf("collectserver: PG_PORT %s\n", PG_PORT)
	logger.Printf("collectserver: PROM_GATEWAY %s\n", PROM_GATEWAY)

	for true {
		time.Sleep(time.Duration(POLL_INT) * time.Minute)
		process()
	}

}

func process() {
	var err error
	var metrics []collectapi.Metric

	var conn *sql.DB
	var host = HOSTNAME
	var user = "postgres"
	var port = PG_PORT
	var database = "postgres"
	var password = PG_ROOT_PASSWORD

	conn, err = collectapi.GetMonitoringConnection(logger, host, user, port, database, password)
	if err != nil {
		logger.Println("could not connect to " + host)
		logger.Println(err.Error())
		return
	}
	defer conn.Close()

	metrics, err = collectapi.GetMetrics(logger, HOSTNAME, user, PG_PORT, PG_ROOT_PASSWORD, conn)
	if err != nil {
		logger.Println("error getting metrics from " + host)
		logger.Println(err.Error())
		return
	}

	//write metrics to Prometheus
	err = collectapi.WritePrometheusMetrics(logger, PROM_GATEWAY, HOSTNAME, metrics)
	if err != nil {
		logger.Println("error writing metrics from " + host)
		logger.Println(err.Error())
		return
	}
}

func getEnvVars() error {
	//get the polling interval (in minutes, 3 minutes is the default)
	var err error
	var tempval = os.Getenv("POLL_INT")
	if tempval != "" {
		POLL_INT, err = strconv.ParseInt(tempval, 10, 64)
		if err != nil {
			logger.Println(err.Error())
			logger.Println("error in POLL_INT env var format")
			return err
		}

	}
	HOSTNAME = os.Getenv("HOSTNAME")
	if HOSTNAME == "" {
		logger.Println("error in HOSTNAME env var, not set")
		return errors.New("HOSTNAME env var not set")
	}
	PROM_GATEWAY = os.Getenv("PROM_GATEWAY")
	if PROM_GATEWAY == "" {
		logger.Println("error in PROM_GATEWAY env var, not set")
		return errors.New("PROM_GATEWAY env var not set, using default")
	}
	PG_ROOT_PASSWORD = os.Getenv("PG_ROOT_PASSWORD")
	if PG_ROOT_PASSWORD == "" {
		logger.Println("error in PG_ROOT_PASSWORD env var, not set")
		return errors.New("PG_ROOT_PASSWORD env var not set")
	}
	PG_PORT = os.Getenv("PG_PORT")
	if PG_ROOT_PASSWORD == "" {
		logger.Println("possible error in PG_PORT env var, not set, using default value")
		return nil
	}

	return err

}
