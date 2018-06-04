package data

import (
	"database/sql"
	"os"
	"strconv"
	"testing"

	dockertest "gopkg.in/ory-am/dockertest.v3"
)

var connURL ConnURL

func preparePostgresTestContainer(t *testing.T) (cleanup func()) {
	if os.Getenv("IMAGE_VERSION") == "" {
		t.Fatal("IMAGE_VERSION env is not set, it should be.")
	}

	if os.Getenv("IMAGE") == "" {
		t.Fatal("IMAGE env is not set, it should be.")
	}

	image := os.Getenv("IMAGE")
	imageVersion := os.Getenv("IMAGE_VERSION")

	pool, err := dockertest.NewPool("")
	if err != nil {
		t.Fatalf("Failed to connect to docker: %s", err)
	}

	env := []string{
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

	resource, err := pool.Run(image, imageVersion, env)
	if err != nil {
		t.Fatalf("Could not start local PostgreSQL docker container: %s", err)
	}

	cleanup = func() {
		err := pool.Purge(resource)
		if err != nil {
			t.Fatalf("Failed to cleanup local container: %s", err)
		}
	}

	port, err := strconv.Atoi(resource.GetPort("5432/tcp"))
	if err != nil {
		t.Fatalf("Failed to convert port to int: %s", err)
	}

	connURL = ConnURL{
		DBName:   "userdb",
		Host:     "0.0.0.0",
		Password: "password",
		SSL:      "disable",
		User:     "postgres",
		Port:     port,
	}

	// exponential backoff-retry
	if err = pool.Retry(func() error {
		var err error
		var db *sql.DB
		db, err = sql.Open("postgres", connURL.URL())
		if err != nil {
			return err
		}
		return db.Ping()
	}); err != nil {
		t.Fatalf("Could not connect to PostgreSQL docker container: %s", err)
	}

	return
}
