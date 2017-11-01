package main

import (
	"io/ioutil"
	"log"
	"os"
	"text/template"
)

type Parms struct {
	VAC_HOST    string
	VAC_FULL    bool
	VAC_ANALYZE bool
	VAC_ALL     bool
	VAC_VERBOSE bool
	VAC_FREEZE  bool
	VAC_TABLE   string
	PG_USER     string
	PG_PORT     string
	PG_DATABASE string
	PG_PASSWORD string
}

func main() {
	var logger *log.Logger
	logger = log.New(os.Stdout, "logger: ", log.Lshortfile|log.Ldate|log.Ltime)

	var filename = "/tmp/vacuum-job-template.json"
	buff, err := ioutil.ReadFile(filename)
	if err != nil {
		logger.Println(err.Error())
		logger.Println("error reading template file, can not continue")
		os.Exit(2)
	}
	s := string(buff)

	parms := getParms()
	tmpl, err := template.New("test").Parse(s)
	if err != nil {
		panic(err)
	}
	err = tmpl.Execute(os.Stdout, parms)
}
func getParms() *Parms {
	parms := new(Parms)
	var temp = os.Getenv("VAC_HOST")
	if temp == "" {
		parms.VAC_HOST = temp
	}
	temp = os.Getenv("VAC_FULL")
	if temp == "" {
		parms.VAC_FULL = true
	}
	temp = os.Getenv("VAC_ANALYZE")
	if temp == "" {
		parms.VAC_ANALYZE = true
	}

	temp = os.Getenv("VAC_ALL")
	if temp == "" {
		parms.VAC_ALL = true
	}

	temp = os.Getenv("VAC_VERBOSE")
	if temp == "" {
		parms.VAC_VERBOSE = true
	}
	temp = os.Getenv("VAC_FREEZE")
	if temp == "" {
		parms.VAC_FREEZE = false
	}
	temp = os.Getenv("VAC_TABLE")
	if temp == "" {
		parms.VAC_TABLE = temp
	}

	temp = os.Getenv("PG_USER")
	if temp == "" {
		parms.PG_USER = "postgres"
	}

	temp = os.Getenv("PG_PORT")
	if temp == "" {
		parms.PG_PORT = "5432"
	}
	temp = os.Getenv("PG_DATABASE")
	if temp == "" {
		parms.PG_DATABASE = "postgres"
	}

	temp = os.Getenv("PG_PASSWORD")
	if temp == "" {
		parms.PG_PASSWORD = ""
	}

	return parms

}
