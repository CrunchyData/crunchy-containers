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
	"fmt"
	"github.com/ant0ine/go-json-rest/rest"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"os/exec"
	"strconv"
)

const REPORT = "/tmp/badger.html"

func main() {

	var VERSION = os.Getenv("CCP_VERSION")

	fmt.Println("badgerserver: " + VERSION + " starting")

	api := rest.NewApi()
	api.Use(rest.DefaultDevStack...)
	router, err := rest.MakeRouter(
		&rest.Route{"GET", "/badgergenerate", BadgerGenerate},
	)
	if err != nil {
		log.Fatal(err)
	}
	api.SetApp(router)

	http.Handle("/api/", http.StripPrefix("/api", api.MakeHandler()))
	http.Handle("/static/", http.StripPrefix("/static", http.FileServer(http.Dir("/tmp"))))

	log.Fatal(http.ListenAndServe(":10000", nil))
	//log.Fatal(http.ListenAndServeTLS(":10000", "/var/cpm/keys/cert.pem", "/var/cpm/keys/key.pem", nil))
}

// BadgerGenerate perform a pgbadger to create the HTML output file
func BadgerGenerate(w rest.ResponseWriter, r *rest.Request) {
	fmt.Println("badgerserver: BadgerGenerate called")

	var cmd *exec.Cmd
	cmd = exec.Command("badger-generate.sh")
	var out bytes.Buffer
	var stderr bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &stderr
	err := cmd.Run()
	if err != nil {
		fmt.Println(err.Error())
		rest.Error(w, err.Error(), 400)
		return
	}

	fmt.Println("badgerserver: BadgerGenerate run executed")

	var buf []byte
	buf, err = ioutil.ReadFile(REPORT)
	if err != nil {
		fmt.Println(err.Error())
		rest.Error(w, err.Error(), 400)
		return
	}
	var thing http.ResponseWriter
	thing = w.(http.ResponseWriter)

	thing.Header().Set("Content-Type", "text/html")
	thing.Header().Set("Content-Length", strconv.Itoa(len(buf)))
	thing.Write(buf)
	fmt.Println("badgerserver: BadgerGenerate report written")
}
