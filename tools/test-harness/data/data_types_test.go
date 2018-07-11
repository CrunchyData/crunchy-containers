package data

import (
	dockertest "gopkg.in/ory-am/dockertest.v3"
)

var tag = "centos7-10.4-2.0"

var primaryEnv = []string{
	"TEMP_BUFFERS=9MB",
	"PGHOST=/tmp",
	"MAX_CONNECTIONS=10",
	"SHARED_BUFFERS=128MB",
	"MAX_WAL_SENDERS=1",
	"WORK_MEM=5MB",
	"PG_MODE=primary",
	"PG_PRIMARY_PORT=5432",
	"PG_PRIMARY_USER=postgres",
	"PG_PRIMARY_PASSWORD=password",
	"PG_DATABASE=userdb",
	"PG_USER=admin",
	"PG_PASSWORD=password",
	"PG_ROOT_PASSWORD=password",
}

var primaryOptions = &dockertest.RunOptions{
	Name:       "primary",
	Hostname:   "primary",
	Repository: "crunchydata/crunchy-postgres",
	Tag:        tag,
	Env:        primaryEnv,
}

var primaryConn = &Connection{
	DBName:   "userdb",
	Host:     "0.0.0.0",
	Password: "password",
	SSL:      "disable",
	User:     "postgres",
}

var replicaEnv = []string{
	"TEMP_BUFFERS=9MB",
	"PGHOST=/tmp",
	"MAX_CONNECTIONS=10",
	"SHARED_BUFFERS=128MB",
	"MAX_WAL_SENDERS=1",
	"WORK_MEM=5MB",
	"PG_MODE=replica",
	"PG_PRIMARY_PORT=5432",
	"PG_PRIMARY_HOST=primary",
	"PG_PRIMARY_USER=postgres",
	"PG_PRIMARY_PASSWORD=password",
	"PG_DATABASE=userdb",
	"PG_USER=admin",
	"PG_PASSWORD=password",
	"PG_ROOT_PASSWORD=password",
}

var replicaOptions = &dockertest.RunOptions{
	Name:       "replica",
	Hostname:   "replica",
	Repository: "crunchydata/crunchy-postgres",
	Tag:        tag,
	Env:        replicaEnv,
	Links:      []string{"primary"},
}

var replicaConn = &Connection{
	DBName:   "userdb",
	Host:     "0.0.0.0",
	Password: "password",
	SSL:      "disable",
	User:     "postgres",
}
