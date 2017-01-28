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

package dbaapi

import (
	"bytes"
	"errors"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"text/template"
)

type BackupJobParms struct {
	JOB_HOST           string
	CCP_IMAGE_TAG      string
	CMD                string
	PG_USER            string
	PG_PASSWORD        string
	PG_PORT            string
	BACKUP_PV_CAPACITY string
	BACKUP_PV_PATH     string
	BACKUP_PV_HOST     string
	BACKUP_PVC_STORAGE string
}

type BackupJob struct {
	Logger        *log.Logger
	Host          string
	CCP_IMAGE_TAG string
	Cmd           string
}

// Run this is the func that implements the cron Job interface
func (t BackupJob) Run() {

	parms, err := GetBackupJobParms(t.Logger)
	if err != nil {
		panic(err)
	}
	parms.CCP_IMAGE_TAG = t.CCP_IMAGE_TAG

	var s = getBackupJobTemplate(t.Logger)
	var pvc = getBackupJobPVCTemplate(t.Logger)

	tmpl, err := template.New("jobtemplate").Parse(s)
	if err != nil {
		panic(err)
	}
	tmplpvc, err := template.New("pvctemplate").Parse(pvc)
	if err != nil {
		panic(err)
	}

	var tmpfile, tmpfilePVC *os.File
	tmpfile, err = ioutil.TempFile("/tmp", "backupjob")
	if err != nil {
		t.Logger.Println(err.Error())
		panic(err)
	}
	tmpfilePVC, err = ioutil.TempFile("/tmp", "backupjobpvc")
	if err != nil {
		t.Logger.Println(err.Error())
		panic(err)
	}

	err = tmpl.Execute(tmpfile, parms)

	if err := tmpfile.Close(); err != nil {
		t.Logger.Println(err.Error())
		panic(err)
	}
	t.Logger.Println("tmpfile is " + tmpfile.Name())

	err = tmplpvc.Execute(tmpfilePVC, parms)
	if err := tmpfilePVC.Close(); err != nil {
		t.Logger.Println(err.Error())
		panic(err)
	}
	t.Logger.Println("tmpfilePVC is " + tmpfilePVC.Name())

	var stdout, stderr string
	stdout, stderr, err = createBackupJob(parms, tmpfile.Name(), tmpfilePVC.Name(), t.Cmd)
	if err != nil {
		t.Logger.Println(err.Error())
	}
	t.Logger.Println(stdout)
	t.Logger.Println(stderr)

}

func getBackupJobTemplate(logger *log.Logger) string {
	var filename = "/opt/cpm/conf/backup-job-template.json"
	buff, err := ioutil.ReadFile(filename)
	if err != nil {
		logger.Println(err.Error())
		logger.Println("error reading template file, can not continue")
		os.Exit(2)
	}
	s := string(buff)
	return s
}

func getBackupJobPVCTemplate(logger *log.Logger) string {
	var filename = "/opt/cpm/conf/backup-job-pvc-template.json"
	buff, err := ioutil.ReadFile(filename)
	if err != nil {
		logger.Println(err.Error())
		logger.Println("error reading pvc template file, can't continue")
		os.Exit(2)
	}
	s := string(buff)
	return s
}

func createBackupJob(parms *BackupJobParms, templateFile string,
	templatePVCFile string, environ string) (string, string, error) {

	var cmd *exec.Cmd
	cmd = exec.Command("create-backup-job.sh", templateFile,
		templatePVCFile, parms.JOB_HOST, environ, parms.CCP_IMAGE_TAG)

	var out bytes.Buffer
	var stderr bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &stderr
	err := cmd.Run()
	if err != nil {
		return out.String(), stderr.String(), err
	}
	return out.String(), stderr.String(), err

}

func GetBackupJobParms(logger *log.Logger) (*BackupJobParms, error) {
	var err error
	parms := new(BackupJobParms)

	parms.JOB_HOST = os.Getenv("JOB_HOST")
	if parms.JOB_HOST == "" {
		return parms, errors.New("JOB_HOST env var not found")
	}
	parms.CCP_IMAGE_TAG = os.Getenv("CCP_IMAGE_TAG")
	if parms.CCP_IMAGE_TAG == "" {
		return parms, errors.New("CCP_IMAGE_TAG env var not found")
	}
	parms.PG_USER = os.Getenv("PG_USER")
	if parms.PG_USER == "" {
		return parms, errors.New("PG_USER env var not found")
	}
	parms.PG_PASSWORD = os.Getenv("PG_PASSWORD")
	if parms.PG_PASSWORD == "" {
		return parms, errors.New("PG_PASSWORD env var not found")
	}
	parms.PG_PORT = os.Getenv("PG_PORT")
	if parms.PG_PORT == "" {
		return parms, errors.New("PG_PORT env var not found")
	}
	parms.BACKUP_PVC_STORAGE = os.Getenv("BACKUP_PVC_STORAGE")
	if parms.BACKUP_PVC_STORAGE == "" {
		return parms, errors.New("BACKUP_PVC_STORAGE env var not found")
	}

	return parms, err
}
