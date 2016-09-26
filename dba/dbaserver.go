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
	"github.com/crunchydata/crunchy-containers/dbaapi"
	"github.com/robfig/cron"
	"log"
	"os"
	"time"
)

var POLL_INT = int64(3)

var logger *log.Logger

func main() {
	logger = log.New(os.Stdout, "logger: ", log.Lshortfile|log.Ldate|log.Ltime)
	var VERSION = os.Getenv("VERSION")

	logger.Println("dbaserver " + VERSION + ": starting")

	cron := cron.New()

	LoadSchedules(cron)

	cron.Start()

	for true {
		time.Sleep(time.Duration(POLL_INT) * time.Minute)
	}

}

func LoadSchedules(cron *cron.Cron) {
	var BACKUP_SCHEDULE = os.Getenv("BACKUP_SCHEDULE")
	var VAC_SCHEDULE = os.Getenv("VAC_SCHEDULE")
	var JOB_HOST = os.Getenv("JOB_HOST")
	var CCP_IMAGE_TAG = os.Getenv("CCP_IMAGE_TAG")
	var CMD = os.Getenv("CMD")
	logger.Println("BACKUP_SCHEDULE=" + BACKUP_SCHEDULE)
	logger.Println("VAC_SCHEDULE=" + VAC_SCHEDULE)
	logger.Println("JOB_HOST=" + JOB_HOST)
	logger.Println("CCP_IMAGE_TAG=" + CCP_IMAGE_TAG)
	logger.Println("CMD=" + CMD)

	if VAC_SCHEDULE != "" {

		job := dbaapi.VacJob{}
		job.Host = JOB_HOST
		job.CCP_IMAGE_TAG = CCP_IMAGE_TAG
		job.Cmd = CMD
		job.Logger = logger
		cron.AddJob(VAC_SCHEDULE, job)
	}
	if BACKUP_SCHEDULE != "" {

		job := dbaapi.BackupJob{}
		job.Host = JOB_HOST
		job.CCP_IMAGE_TAG = CCP_IMAGE_TAG
		job.Cmd = CMD
		job.Logger = logger
		cron.AddJob(BACKUP_SCHEDULE, job)
	}
}
