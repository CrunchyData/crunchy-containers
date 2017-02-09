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
	"io/ioutil"
	"log"
	"os"
	"strings"
)

var logger *log.Logger

/*
this program reads an input file, and removes the master database,
replacing the slave database as the new master, and writes out the file to
the same input filename..it is used to rewrite a pgbouncer.ini file after
a failover has been performed..
*/
func main() {
	logger = log.New(os.Stdout, "logger: ", log.Lshortfile|log.Ldate|log.Ltime)
	var VERSION = os.Getenv("CCP_VERSION")

	logger.Println("bounce " + VERSION + ": starting")

	args := os.Args[1:]
	if len(args) < 1 {
		logger.Println("error:  no file passed on command line")
		os.Exit(2)
	}

	var filename = args[0]
	logger.Println("opening " + filename)

	content, err := ioutil.ReadFile(filename)
	if err != nil {
		logger.Println(err.Error())
		os.Exit(2)
	}
	lines := strings.Split(string(content), "\n")

	//logger.Println("here is the file....")
	var slaveflipped = false
	var sectionfound = false
	var outputString string
	for i := 0; i < len(lines); i++ {
		if strings.Contains(lines[i], "[databases]") {
			//logger.Println("found database section")
			//logger.Println(lines[i])
			outputString += lines[i] + "\n"
			sectionfound = true
		} else {
			if strings.Contains(lines[i], "[") {
				sectionfound = false
			}
			if sectionfound {
				if len(lines[i]) < 1 {
					//logger.Println(lines[i])
					outputString += lines[i] + "\n"
				} else {
					//logger.Println(" process this one-" + lines[i])
					if strings.Contains(lines[i], "master") {
						//logger.Println("dropping this one " + lines[i])
					} else {
						//logger.Println("should be slave " + lines[i])

						//logger.Println("master " + lines[i][pos:length])
						if slaveflipped == false {
							outputString += replace(lines[i])
							slaveflipped = true
						} else {
							outputString += lines[i] + "\n"
						}

					}
				}
			} else {
				//logger.Println(lines[i])
				outputString += lines[i] + "\n"
			}
		}

	}
	err = ioutil.WriteFile(filename, []byte(outputString), 0644)
	if err != nil {
		logger.Println(err.Error())
		os.Exit(2)
	}

}

func replace(instring string) string {
	var pos = strings.Index(instring, "=")
	var length = len(instring)
	//var OSE_PROJECT = os.Getenv("OSE_PROJECT")
	//var PG_MASTER_SERVICE = os.Getenv("PG_MASTER_SERVICE")

	return "master " + instring[pos:length] + "\n"
}
