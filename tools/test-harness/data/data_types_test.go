package data

/*
Copyright 2018 - 2020 Crunchy Data Solutions, Inc.
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

import (
	dockertest "gopkg.in/ory-am/dockertest.v3"
)

var tag = "centos7-11.9-4.3.3"

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
