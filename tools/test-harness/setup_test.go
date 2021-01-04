package tests

/*
Copyright 2018 - 2021 Crunchy Data Solutions, Inc.
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
	"testing"
	"time"

	"github.com/crunchydata/crunchy-containers/tools/kubeapi"
	pg "github.com/crunchydata/crunchy-containers/tools/test-harness/data"
	"github.com/crunchydata/crunchy-containers/tools/test-harness/runner"
)

const timeout = (time.Second * 120)

type harness struct {
	Namespace string
	Cleanup   bool
	Client    *kubeapi.KubeAPI
	InCluster bool
	Debug     bool
}

func setup(t *testing.T, timeout time.Duration, cleanup bool) *harness {
	var test harness
	test.Cleanup = envCheckBool("CCP_HARNES_CLEANUP", true)
	test.Debug = envCheckBool("CCP_HARNESS_DEBUG", true)
	test.InCluster = envCheckBool("CCP_HARNESS_IN_CLUSTER", false)

	t.Log("Running Initialization Checks...")
	envs := []string{
		"CCPROOT", "CCP_BASEOS", "CCP_PGVERSION", "CCP_POSTGIS_VERSION",
		"CCP_IMAGE_PREFIX", "CCP_IMAGE_TAG", "CCP_POSTGIS_IMAGE_TAG",
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
