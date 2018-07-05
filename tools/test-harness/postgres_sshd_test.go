package tests

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"os"
	"testing"

	"golang.org/x/crypto/ssh"
)

func TestPostgresSSHD(t *testing.T) {
	t.Parallel()
	t.Log("Testing the 'postgres-sshd' example...")
	harness := setup(t, timeout, true)

	env := []string{}
	_, err := harness.runExample("examples/kube/postgres-sshd/run.sh", env, t)
	if err != nil {
		t.Fatalf("Could not run example: %s", err)
	}

	if harness.Cleanup {
		defer harness.Client.DeleteNamespace(harness.Namespace)
		defer harness.runExample("examples/kube/postgres-sshd/cleanup.sh", env, t)
	}

	t.Log("Checking if pods are ready to use...")
	if err := harness.Client.CheckPods(harness.Namespace, []string{"postgres-sshd"}); err != nil {
		t.Fatal(err)
	}

	local, remote := randomPort(), 2022
	proxy, err := harness.setupProxy("postgres-sshd", local, remote)
	if err != nil {
		t.Fatal(err)
	}
	defer proxy.Close()

	pkey := os.ExpandEnv("$CCPROOT/examples/kube/postgres-sshd/keys/id_rsa")
	if _, err := os.Stat(pkey); os.IsNotExist(err) {
		t.Fatalf("could not find private key for example: %s", err)
	}

	config := &ssh.ClientConfig{
		User: "postgres",
		Auth: []ssh.AuthMethod{
			getPrivateKey(pkey),
		},
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
	}

	host := fmt.Sprintf("127.0.0.1:%d", local)
	connection, err := ssh.Dial("tcp", host, config)
	if err != nil {
		t.Fatalf("Failed to dial: %s", err)
	}

	session, err := connection.NewSession()
	if err != nil {
		t.Fatalf("Failed to create session: %s", err)
	}
	defer session.Close()

	var b bytes.Buffer
	session.Stdout = &b
	cmd := "/usr/bin/pgbackrest --stanza=db backup"
	if err := session.Run(cmd); err != nil {
		t.Fatalf("Failed to run: " + err.Error())
	}

	report, err := harness.createReport()
	if err != nil {
		t.Fatal(err)
	}
	t.Log(report)
}

func getPrivateKey(file string) ssh.AuthMethod {
	buffer, err := ioutil.ReadFile(file)
	if err != nil {
		return nil
	}

	key, err := ssh.ParsePrivateKey(buffer)
	if err != nil {
		return nil
	}
	return ssh.PublicKeys(key)
}
