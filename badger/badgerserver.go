/*
 Copyright 2016 - 2018 Crunchy Data Solutions, Inc.
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
	"bytes"
	"log"
	"net/http"
	"os"
	"os/exec"
)

const REPORT = "/report/index.html"

func init() {
	log.SetOutput(os.Stdout)
	log.Println("BadgerServer starting..")
}

func main() {
	http.HandleFunc("/api/badgergenerate", BadgerGenerate)
	http.Handle("/static/", http.StripPrefix("/static", http.FileServer(http.Dir("/report"))))
	log.Fatal(http.ListenAndServe(":10000", nil))
}

// BadgerGenerate perform a pgbadger to create the HTML output file
func BadgerGenerate(w http.ResponseWriter, r *http.Request) {
	log.Println("Generating report..")

	var cmd *exec.Cmd
	cmd = exec.Command("badger-generate.sh")
	var out bytes.Buffer
	var stderr bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &stderr
	err := cmd.Run()
	if err != nil {
		log.Fatalf("Error running badger-generate: %s", err)
		return
	}

	log.Println("Report generated.  Redirecting..")
	http.Redirect(w, r, "/static", 301)
}
