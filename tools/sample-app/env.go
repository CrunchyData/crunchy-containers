package main

import (
	"log"
	"os"
	"strconv"
)

var user, password, dbName, host string
var port int

func init() {
	var err error
	checkEnv("PG_USER")
	checkEnv("PG_PASSWORD")
	checkEnv("PG_DATABASE")
	checkEnv("PG_HOSTNAME")
	checkEnv("PG_PORT")
	user = os.Getenv("PG_USER")
	password = os.Getenv("PG_PASSWORD")
	dbName = os.Getenv("PG_DATABASE")
	host = os.Getenv("PG_HOSTNAME")

	port, err = strconv.Atoi(os.Getenv("PG_PORT"))
	if err != nil {
		log.Fatalf("%s", err)
	}
}

func checkEnv(env string) {
	if len(os.Getenv(env)) == 0 {
		log.Fatalf("%s must be set.", env)
	}
}
