package main

/*
 Copyright 2018 - 2023 Crunchy Data Solutions, Inc.
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
	"bytes"
	"io"
	"os"
	"strconv"
	"strings"

	log "github.com/sirupsen/logrus"
	core_v1 "k8s.io/api/core/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"
	"k8s.io/client-go/tools/remotecommand"
)

type KubeAPI struct {
	Client *kubernetes.Clientset
	Config *rest.Config
}

const backrestCommand = "pgbackrest"

const (
	backrestBackupCommand       = "backup"
	backrestInfoCommand         = "info"
	backrestStanzaCreateCommand = "stanza-create"
)

const (
	repoTypeFlagS3    = "--repo1-type=s3"
	noRepoS3VerifyTLS = "--no-repo1-s3-verify-tls"
)

const containerName = "database"

const (
	pgtaskBackrestStanzaCreate = "stanza-create"
	pgtaskBackrestInfo         = "info"
	pgtaskBackrestBackup       = "backup"
)

// getEnvRequired attempts to get an environmental variable that is required
// by this program. If this cannot happen, we fatally exit
func getEnvRequired(envVar string) string {
	val := strings.TrimSpace(os.Getenv(envVar))

	if val == "" {
		log.Fatalf("required environmental variable %q not set, exiting.", envVar)
	}

	log.Debugf("%s set to: %s", envVar, val)

	return val
}

func main() {
	log.Info("crunchy-pgbackrest starts")

	config, err := NewConfig()
	if err != nil {
		panic(err)
	}

	k, err := NewForConfig(config)
	if err != nil {
		panic(err)
	}

	debugFlag, _ := strconv.ParseBool(os.Getenv("CRUNCHY_DEBUG"))
	if debugFlag {
		log.SetLevel(log.DebugLevel)
	}
	log.Info("debug flag set to %t", debugFlag)

	namespace := getEnvRequired("NAMESPACE")
	command := getEnvRequired("COMMAND")
	podName := getEnvRequired("PODNAME")

	commandOpts := os.Getenv("COMMAND_OPTS")
	log.Debugf("COMMAND_OPTS set to: %s", commandOpts)

	repoType := os.Getenv("PGBACKREST_REPO1_TYPE")
	log.Debugf("PGBACKREST_REPO1_TYPE set to: %s", repoType)

	// determine the setting of PGHA_PGBACKREST_LOCAL_S3_STORAGE
	// we will discard the error and treat the value as "false" if it is not
	// explicitly set
	localS3Storage, _ := strconv.ParseBool(os.Getenv("PGHA_PGBACKREST_LOCAL_S3_STORAGE"))
	log.Debugf("PGHA_PGBACKREST_LOCAL_S3_STORAGE set to: %t", localS3Storage)

	// parse the environment variable and store the appropriate boolean value
	// we will discard the error and treat the value as "false" if it is not
	// explicitly set
	s3VerifyTLS, _ := strconv.ParseBool(os.Getenv("PGHA_PGBACKREST_S3_VERIFY_TLS"))
	log.Debugf("PGHA_PGBACKREST_S3_VERIFY_TLS set to: %t", s3VerifyTLS)

	bashCmd := []string{"bash"}
	cmdStrs := []string{backrestCommand}

	switch command {
	default:
		log.Fatalf("unsupported backup command specified: %s", command)
	case pgtaskBackrestStanzaCreate:
		log.Info("backrest stanza-create command requested")
		cmdStrs = append(cmdStrs, backrestStanzaCreateCommand, commandOpts)
	case pgtaskBackrestInfo:
		log.Info("backrest info command requested")
		cmdStrs = append(cmdStrs, backrestInfoCommand, commandOpts)
	case pgtaskBackrestBackup:
		log.Info("backrest backup command requested")
		cmdStrs = append(cmdStrs, backrestBackupCommand, commandOpts)
	}

	if localS3Storage {
		// if the first backup fails, still attempt the 2nd one
		cmdStrs = append(cmdStrs, ";")
		cmdStrs = append(cmdStrs, cmdStrs...)
		cmdStrs[len(cmdStrs)-1] = repoTypeFlagS3 // a trick to overwite the second ";"
		// pass in the flag to disable TLS verification, if set
		// otherwise, maintain default behavior and verify TLS
		if !s3VerifyTLS {
			cmdStrs = append(cmdStrs, noRepoS3VerifyTLS)
		}
		log.Info("backrest command will be executed for both local and s3 storage")
	} else if repoType == "s3" {
		cmdStrs = append(cmdStrs, repoTypeFlagS3)
		// pass in the flag to disable TLS verification, if set
		// otherwise, maintain default behavior and verify TLS
		if !s3VerifyTLS {
			cmdStrs = append(cmdStrs, noRepoS3VerifyTLS)
		}
		log.Info("s3 flag enabled for backrest command")
	}

	log.Infof("command to execute is [%s]", strings.Join(cmdStrs, " "))

	reader := strings.NewReader(strings.Join(cmdStrs, " "))
	output, stderr, err := k.Exec(namespace, podName, containerName, reader, bashCmd)
	if err != nil {
		log.Info("output=[" + output + "]")
		log.Info("stderr=[" + stderr + "]")
		log.Fatal(err)
	}
	log.Info("output=[" + output + "]")
	log.Info("stderr=[" + stderr + "]")

	log.Info("crunchy-pgbackrest ends")

}

// Exec returns the stdout and stderr from running a command inside an existing
// container.
func (k *KubeAPI) Exec(namespace, pod, container string, stdin io.Reader, command []string) (string, string, error) {
	var stdout, stderr bytes.Buffer

	var Scheme = runtime.NewScheme()
	if err := core_v1.AddToScheme(Scheme); err != nil {
		log.Error(err)
		return "", "", err
	}
	var ParameterCodec = runtime.NewParameterCodec(Scheme)

	request := k.Client.CoreV1().RESTClient().Post().
		Resource("pods").SubResource("exec").
		Namespace(namespace).Name(pod).
		VersionedParams(&core_v1.PodExecOptions{
			Container: container,
			Command:   command,
			Stdin:     stdin != nil,
			Stdout:    true,
			Stderr:    true,
		}, ParameterCodec)

	exec, err := remotecommand.NewSPDYExecutor(k.Config, "POST", request.URL())

	if err == nil {
		err = exec.Stream(remotecommand.StreamOptions{
			Stdin:  stdin,
			Stdout: &stdout,
			Stderr: &stderr,
		})
	}

	return stdout.String(), stderr.String(), err
}

func NewConfig() (*rest.Config, error) {
	// The default loading rules try to read from the files specified in the
	// environment or from the home directory.
	loader := clientcmd.NewDefaultClientConfigLoadingRules()

	// The deferred loader tries an in-cluster config if the default loading
	// rules produce no results.
	return clientcmd.NewNonInteractiveDeferredLoadingClientConfig(
		loader, &clientcmd.ConfigOverrides{}).ClientConfig()
}

func NewForConfig(config *rest.Config) (*KubeAPI, error) {
	var api KubeAPI
	var err error

	api.Config = config
	api.Client, err = kubernetes.NewForConfig(api.Config)

	return &api, err
}
