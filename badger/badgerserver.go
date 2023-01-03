/*
 Copyright 2016 - 2023 Crunchy Data Solutions, Inc.
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
	"fmt"
	"log"
	"net/http"
	"os"
	"os/exec"
)

const REPORT = "/report/index.html"
const PG_BADGER_SERVICE_PORT = "PGBADGER_SERVICE_PORT"
const DEFAULT_PGBADGER_PORT = "10000"

func init() {
	log.SetOutput(os.Stdout)
	log.Println("BadgerServer starting..")
}

func main() {
	http.HandleFunc("/api/badgergenerate", BadgerGenerate)
	http.Handle("/static/", http.StripPrefix("/static", http.FileServer(http.Dir("/report"))))
	http.HandleFunc("/", RootPathRedirect)
	port := os.Getenv(PG_BADGER_SERVICE_PORT)
	if port == "" {
		log.Printf("PGBadger port not found. Using default %s\n", DEFAULT_PGBADGER_PORT)
		port = DEFAULT_PGBADGER_PORT
	}
	log.Fatal(http.ListenAndServe(":" + port, nil))
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
		errorMsg := fmt.Sprintf("Error running badger-generate: %s\n%s", err, stderr.String())
		log.Println(errorMsg)
		http.Error(w, errorMsg, http.StatusInternalServerError)
		return
	}

	log.Println("Report generated.  Redirecting..")
	http.Redirect(w, r, "/static", 302)
}

func RootPathRedirect(w http.ResponseWriter, r *http.Request) {
	redirect_url := "/static/"
	if _, err := os.Stat(REPORT); os.IsNotExist(err) {
		redirect_url = "/api/badgergenerate"
	}
	http.Redirect(w, r, redirect_url, 302)
}
