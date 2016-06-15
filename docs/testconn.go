package main

import (
	"database/sql"
	"fmt"
	_ "github.com/lib/pq"
)

func main() {
	fmt.Println("starting..")

	for i := 0; i < 100; i++ {
		connect()
	}
}
func connect() {
	var dbHost = "pg-slave-rc.pgproject.svc.cluster.local"
	var dbPassword = "apXvkRvw2daW"
	dbConn, err := sql.Open("postgres", "sslmode=disable user=master host="+dbHost+" port=5432 dbname=userdb password="+dbPassword)
	if err != nil {
		fmt.Println(err.Error())
		panic(err)
	}
	fmt.Println("got a connection..")
	query := fmt.Sprintf("select inet_server_addr()")
	value := ""
	sqlerror := dbConn.QueryRow(query).Scan(&value)
	if sqlerror != nil {
		fmt.Println(sqlerror.Error())
	}
	fmt.Println("value=" + value)
	defer dbConn.Close()
}
