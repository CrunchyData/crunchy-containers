package tests

import (
	"testing"
	"time"

	pg "github.com/crunchydata/crunchy-containers/tools/test-harness/data"
	"github.com/crunchydata/crunchy-containers/tools/test-harness/kubeapi"
	"github.com/crunchydata/crunchy-containers/tools/test-harness/runner"
)

const timeout = (time.Second * 120)

type harness struct {
	Namespace string
	Cleanup   bool
	Client    *kubeapi.KubeAPI
	InCluster bool
}

func setup(t *testing.T, timeout time.Duration, cleanup bool) *harness {
	var test harness
	test.Cleanup = true
	test.InCluster = false
	test.Namespace = "default"

	t.Log("Running Initialization Checks...")
	envs := []string{
		"CCPROOT", "CCP_BASEOS", "CCP_PGVERSION",
		"CCP_IMAGE_PREFIX", "CCP_IMAGE_TAG",
		"CCP_STORAGE_MODE", "CCP_STORAGE_CAPACITY", "CCP_CLI"}
	if err := runner.GetEnv(envs); err != nil {
		t.Fatal(err)
	}

	t.Log("Generating Kube Client...")
	var err error
	test.Client, err = kubeapi.New(timeout, test.InCluster)
	if err != nil {
		t.Fatalf("Error creating Kube Client: %s", err)
	}

	namespace := "test-harness-" + randomString(10)
	t.Logf("Generating test namespace '%s'", namespace)
	_, err = test.Client.CreateNamespace(namespace)
	if err != nil {
		t.Fatalf("Error creating test namespace: %s", err)
	}

	test.Namespace = namespace
	return &test
}

func (h *harness) setupProxy(host string, localPort, remotePort int) (*kubeapi.Proxy, error) {
	proxy, err := h.Client.NewProxy(localPort, remotePort, host, h.Namespace)
	if err != nil {
		return nil, err
	}
	if err := proxy.ForwardPort(); err != nil {
		return nil, err
	}
	return proxy, nil
}

func (h *harness) setupDB(dbname, host, user, password, ssl string, port int) (*pg.DB, error) {
	c := &pg.Connection{
		DBName:   dbname,
		Host:     host,
		Password: password,
		SSL:      ssl,
		User:     user,
		Port:     port,
	}
	return c.NewDB()
}
