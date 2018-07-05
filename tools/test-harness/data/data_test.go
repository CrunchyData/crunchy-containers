package data

import (
	"database/sql"
	"strconv"
	"testing"

	dockertest "gopkg.in/ory-am/dockertest.v3"
)

func preparePostgresTestContainer(t *testing.T, opts *dockertest.RunOptions, c *Connection) func() {
	pool, err := dockertest.NewPool("")
	if err != nil {
		t.Fatalf("Failed to connect to docker: %s", err)
	}

	resource, err := pool.RunWithOptions(opts)
	if err != nil {
		t.Fatalf("Could not start local PostgreSQL docker container: %s", err)
	}

	cleanup := func() {
		err := pool.Purge(resource)
		if err != nil {
			t.Fatalf("Failed to cleanup local container: %s", err)
		}
	}

	port, err := strconv.Atoi(resource.GetPort("5432/tcp"))
	if err != nil {
		t.Fatalf("Failed to convert port to int: %s", err)
	}

	c.Port = port

	// exponential backoff-retry
	if err = pool.Retry(func() error {
		var err error
		var db *sql.DB
		db, err = sql.Open("postgres", c.url())
		if err != nil {
			return err
		}
		return db.Ping()
	}); err != nil {
		t.Fatalf("Could not connect to PostgreSQL docker container: %s", err)
	}

	return cleanup
}
