package main

import (
	"github.com/crunchydata/crunchy-containers/dnsbridgeapi"
	"log"
	"os"
)

const REGISTER = "/v1/agent/service/register"
const DEREGISTER = "/v1/agent/service/deregister/"

var logger *log.Logger

type ReturnValue struct {
	Value string
}

func main() {
	logger = log.New(os.Stdout, "logger: ", log.Lshortfile|log.Ldate|log.Ltime)
	logger.Println("consulclient  : starting")

	//arg 1 is the consul URL (http://127.0.0.1:8500)
	//arg 2 is the command either register or deregister
	//arg 3 is the service name
	//arg 4 is the service ip address
	argsWithoutProg := os.Args[1:]

	if len(argsWithoutProg) < 4 {
		logger.Println("missing command line args")
		logger.Println("consulclient consulURL register|deregister serviceName serviceIP")
		os.Exit(1)
	}
	var consulURL = argsWithoutProg[0]
	var command = argsWithoutProg[1]
	logger.Println("args: consulURL:" + consulURL)
	logger.Println("args: command:" + command)
	logger.Println("args: service name:" + argsWithoutProg[2])
	logger.Println("args: service ip address:" + argsWithoutProg[3])

	c := new(dnsbridgeapi.Service)
	c.Name = argsWithoutProg[2]
	c.Address = argsWithoutProg[3]

	var err error

	if command == "register" {
		err = dnsbridgeapi.Register(consulURL, logger, c)
		if err != nil {
			logger.Println("could not register")
		}
	} else if command == "deregister" {
		err = dnsbridgeapi.Deregister(consulURL, logger, c.Name)
		if err != nil {
			logger.Println("could not deregister")
		}
	}

}
