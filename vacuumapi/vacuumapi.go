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

package vacuumapi

import (
	"errors"
	"log"
	"os"
	"strconv"
)

type Parms struct {
	JOB_HOST      string
	VAC_FULL      bool
	VAC_ANALYZE   bool
	VAC_VERBOSE   bool
	VAC_FREEZE    bool
	VAC_TABLE     string
	CCP_IMAGE_TAG string
	CCP_IMAGE_PREFIX string
	PG_USER       string
	PG_PORT       string
	PG_DATABASE   string
	PG_PASSWORD   string
	CMD           string
}

func GetParms(logger *log.Logger) (*Parms, error) {
	var err error

	parms := new(Parms)
	parms.VAC_FULL = true
	parms.VAC_ANALYZE = true
	parms.VAC_VERBOSE = true
	parms.VAC_FREEZE = false
	parms.VAC_TABLE = os.Getenv("VAC_TABLE")
	parms.JOB_HOST = os.Getenv("JOB_HOST")
	parms.PG_PORT = "5432"
	parms.PG_DATABASE = "postgres"
	parms.PG_PASSWORD = ""

	parms.VAC_TABLE = os.Getenv("VAC_TABLE")
	if parms.VAC_TABLE == "" {
		logger.Println("VAC_TABLE not set, assuming you want to vacuum all tables")
	}

	parms.PG_USER = os.Getenv("PG_USER")
	logger.Println("PG_USER set to " + parms.PG_USER)
	if parms.PG_USER == "" {
		logger.Println("PG_USER not set, required env var")
		return parms, errors.New("PG_USER env var not set")
	}

	parms.PG_PORT = os.Getenv("PG_PORT")
	if parms.PG_PORT == "" {
		logger.Println("PG_PORT not set, using default of 5432")
		parms.PG_PORT = "5432"
	}
	parms.PG_DATABASE = os.Getenv("PG_DATABASE")
	if parms.PG_DATABASE == "" {
		logger.Println("PG_DATABASE not set, using default of postgres")
		parms.PG_DATABASE = "postgres"
	}
	parms.PG_PASSWORD = os.Getenv("PG_PASSWORD")
	if parms.PG_PASSWORD == "" {
		logger.Println("PG_PASSWORD not set, required env var")
		return parms, errors.New("PG_PASSWORD env var not set")
	}

	parms.JOB_HOST = os.Getenv("JOB_HOST")
	if parms.JOB_HOST == "" {
		logger.Println("JOB_HOST not set, required env var")
		return parms, errors.New("JOB_HOST env var not set")
	}
	var temp = os.Getenv("VAC_FULL")
	if temp == "" {
		logger.Println("VAC_FULL not set, using default of true")
		parms.VAC_FULL = true
	} else {
		parms.VAC_FULL, err = strconv.ParseBool(temp)
		if err != nil {
			logger.Println("error parsing VAC_FULL env var")
			return parms, err
		}
	}

	temp = os.Getenv("VAC_ANALYZE")
	if temp == "" {
		logger.Println("VAC_ANALYZE not set, using default of true")
		parms.VAC_ANALYZE = true
	} else {
		parms.VAC_ANALYZE, err = strconv.ParseBool(temp)
		if err != nil {
			logger.Println("error parsing VAC_ANALYZE env var")
			return parms, err
		}
	}
	temp = os.Getenv("VAC_VERBOSE")
	if temp == "" {
		logger.Println("VAC_VERBOSE not set, using default of true")
		parms.VAC_VERBOSE = true
	} else {
		parms.VAC_VERBOSE, err = strconv.ParseBool(temp)
		if err != nil {
			logger.Println("error parsing VAC_VERBOSE env var")
			return parms, err
		}
	}
	temp = os.Getenv("VAC_FREEZE")
	if temp == "" {
		logger.Println("VAC_FREEZE not set, using default of false")
		parms.VAC_FREEZE = false
	} else {
		parms.VAC_FREEZE, err = strconv.ParseBool(temp)
		if err != nil {
			logger.Println("error parsing VAC_FREEZE env var")
			return parms, err
		}
	}

	return parms, err

}

func (t *Parms) Print(logger *log.Logger) {
	logger.Printf("VAC_FULL:%t\n", t.VAC_FULL)
	logger.Printf("JOB_HOST: %s\n", t.JOB_HOST)
	logger.Printf("VAC_ANALYZE: %t\n", t.VAC_ANALYZE)
	logger.Printf("VAC_VERBOSE: %t\n", t.VAC_VERBOSE)
	logger.Printf("VAC_FREEZE: %t\n", t.VAC_FREEZE)
	logger.Printf("VAC_TABLE: %s\n", t.VAC_TABLE)
	logger.Printf("PG_USER: %s\n", t.PG_USER)
	logger.Printf("PG_PORT: %s\n", t.PG_PORT)
	logger.Printf("PG_DATABASE: %s\n", t.PG_DATABASE)
	logger.Printf("PG_PASSWORD: %s\n", t.PG_PASSWORD)

}
