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
	"github.com/crunchydata/crunchy-containers/vacuumapi"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"text/template"
)

type VacJob struct {
	Logger        *log.Logger
	Host          string
	CCP_IMAGE_TAG string
	Cmd           string
}

// Run this is the func that implements the cron Job interface
func (t VacJob) Run() {

	var s = getTemplate(t.Logger)

	parms, err := vacuumapi.GetParms(t.Logger)
	if err != nil {
		panic(err)
	}
	parms.CCP_IMAGE_TAG = t.CCP_IMAGE_TAG

	tmpl, err := template.New("jobtemplate").Parse(s)
	if err != nil {
		panic(err)
	}

	var tmpfile *os.File
	tmpfile, err = ioutil.TempFile("/tmp", "vacjob")
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

	var stdout, stderr string
	stdout, stderr, err = createJob(parms, tmpfile.Name(), t.Cmd)
	if err != nil {
		t.Logger.Println(err.Error())
	}
	t.Logger.Println(stdout)
	t.Logger.Println(stderr)
}

func getTemplate(logger *log.Logger) string {
	var filename = "/opt/cpm/conf/vacuum-job-template.json"
	buff, err := ioutil.ReadFile(filename)
	if err != nil {
		logger.Println(err.Error())
		logger.Println("error reading template file, can not continue")
		os.Exit(2)
	}
	s := string(buff)
	return s
}

func createJob(parms *vacuumapi.Parms, templateFile string, environ string) (string, string, error) {

	var cmd *exec.Cmd
	cmd = exec.Command("create-vac-job.sh", templateFile, parms.JOB_HOST, environ)

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
