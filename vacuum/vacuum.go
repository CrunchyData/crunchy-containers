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
	"database/sql"
	"github.com/crunchydata/crunchy-containers/vacuumapi"
	_ "github.com/lib/pq"
	"log"
	"os"
)

var logger *log.Logger

func main() {
	logger = log.New(os.Stdout, "logger: ", log.Lshortfile|log.Ldate|log.Ltime)

	var VERSION = os.Getenv("CCP_VERSION")
	logger.Println("vacuum " + VERSION + ": starting")

	parms, err := vacuumapi.GetParms(logger)
	parms.Print(logger)

	var conn *sql.DB

	conn, err = sql.Open("postgres",
		"sslmode=disable user="+parms.PG_USER+
			" host="+parms.JOB_HOST+" port="+parms.PG_PORT+
			" dbname="+parms.PG_DATABASE+" password="+parms.PG_PASSWORD)
	if err != nil {
		logger.Println("could not connect to " + parms.JOB_HOST)
		logger.Println(err.Error())
		os.Exit(1)
	}
	defer conn.Close()
	err = vacuumCommand(parms, conn)
	if err != nil {
		logger.Println(err.Error())
		logger.Println("error performing query")
		os.Exit(1)
	}

}

func vacuumCommand(parms *vacuumapi.Parms, conn *sql.DB) error {
	var query = "VACUUM"
	if parms.VAC_FULL {
		query += " FULL "
	}
	if parms.VAC_FREEZE {
		query += " FREEZE "
	}
	if parms.VAC_VERBOSE {
		query += " VERBOSE "
	}
	if parms.VAC_ANALYZE {
		query += " ANALYZE "
	}
	if parms.VAC_TABLE != "" {
		query += parms.VAC_TABLE
	}
	logger.Println(query)
	rows, err := conn.Query(query)
	if err != nil {
		return err
	}
	defer rows.Close()
	return err
}
