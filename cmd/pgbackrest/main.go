package main

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

const backrestCommand = "pgbackrest"

const backrestBackupCommand = `backup`
const backrestInfoCommand = `info`
const backrestStanzaCreateCommand = `stanza-create`
const containername = "database"
const repoTypeFlagS3 = "--repo1-type=s3"
const noRepoS3VerifyTLS = "--no-repo1-s3-verify-tls"

const PgtaskBackrestStanzaCreate = "stanza-create"
const PgtaskBackrestInfo = "info"
const PgtaskBackrestBackup = "backup"

type KubeAPI struct {
	Client *kubernetes.Clientset
	Config *rest.Config
}

func main() {
	log.Info("pgo-backrest starts")

	config, err := NewConfig()
	if err != nil {
		panic(err)
	}

	k, err := NewForConfig(config)
	if err != nil {
		panic(err)
	}

	debugFlag := os.Getenv("CRUNCHY_DEBUG")
	if debugFlag == "true" {
		log.SetLevel(log.DebugLevel)
		log.Debug("debug flag set to true")
	} else {
		log.Info("debug flag set to false")
	}

	Namespace := os.Getenv("NAMESPACE")
	log.Debugf("setting NAMESPACE to %s", Namespace)
	if Namespace == "" {
		log.Error("NAMESPACE env var not set")
		os.Exit(2)
	}

	Command := os.Getenv("COMMAND")
	log.Debugf("setting COMMAND to %s", Command)
	if Command == "" {
		log.Error("COMMAND env var not set")
		os.Exit(2)
	}

	CommandOpts := os.Getenv("COMMAND_OPTS")
	log.Debugf("setting COMMAND_OPTS to %s", CommandOpts)

	PodName := os.Getenv("PODNAME")
	log.Debugf("setting PODNAME to %s", PodName)
	if PodName == "" {
		log.Error("PODNAME env var not set")
		os.Exit(2)
	}

	RepoType := os.Getenv("PGBACKREST_REPO_TYPE")
	log.Debugf("setting REPO_TYPE to %s", RepoType)

	// determine the setting of PGHA_PGBACKREST_LOCAL_S3_STORAGE
	// we will discard the error and treat the value as "false" if it is not
	// explicitly set
	LocalS3Storage, _ := strconv.ParseBool(os.Getenv("PGHA_PGBACKREST_LOCAL_S3_STORAGE"))
	log.Debugf("setting PGHA_PGBACKREST_LOCAL_S3_STORAGE to %v", LocalS3Storage)

	// parse the environment variable and store the appropriate boolean value
	// we will discard the error and treat the value as "false" if it is not
	// explicitly set
	S3VerifyTLS, _ := strconv.ParseBool(os.Getenv("PGHA_PGBACKREST_S3_VERIFY_TLS"))
	log.Debugf("setting PGHA_PGBACKREST_S3_VERIFY_TLS to %v", S3VerifyTLS)

	/*
		client, err := kubeapi.NewClient()
		if err != nil {
			panic(err)
		}
	*/

	bashcmd := make([]string, 1)
	bashcmd[0] = "bash"
	cmdStrs := make([]string, 0)

	switch Command {
	case PgtaskBackrestStanzaCreate:
		log.Info("backrest stanza-create command requested")
		cmdStrs = append(cmdStrs, backrestCommand)
		cmdStrs = append(cmdStrs, backrestStanzaCreateCommand)
		cmdStrs = append(cmdStrs, CommandOpts)
	case PgtaskBackrestInfo:
		log.Info("backrest info command requested")
		cmdStrs = append(cmdStrs, backrestCommand)
		cmdStrs = append(cmdStrs, backrestInfoCommand)
		cmdStrs = append(cmdStrs, CommandOpts)
	case PgtaskBackrestBackup:
		log.Info("backrest backup command requested")
		cmdStrs = append(cmdStrs, backrestCommand)
		cmdStrs = append(cmdStrs, backrestBackupCommand)
		cmdStrs = append(cmdStrs, CommandOpts)
	default:
		log.Error("unsupported backup command specified " + Command)
		os.Exit(2)
	}

	if LocalS3Storage {
		firstCmd := cmdStrs
		cmdStrs = append(cmdStrs, "&&")
		cmdStrs = append(cmdStrs, strings.Join(firstCmd, " "))
		cmdStrs = append(cmdStrs, repoTypeFlagS3)
		// pass in the flag to disable TLS verification, if set
		// otherwise, maintain default behavior and verify TLS
		if !S3VerifyTLS {
			cmdStrs = append(cmdStrs, noRepoS3VerifyTLS)
		}
		log.Info("backrest command will be executed for both local and s3 storage")
	} else if RepoType == "s3" {
		cmdStrs = append(cmdStrs, repoTypeFlagS3)
		// pass in the flag to disable TLS verification, if set
		// otherwise, maintain default behavior and verify TLS
		if !S3VerifyTLS {
			cmdStrs = append(cmdStrs, noRepoS3VerifyTLS)
		}
		log.Info("s3 flag enabled for backrest command")
	}

	log.Infof("command to execute is [%s]", strings.Join(cmdStrs, " "))

	log.Infof("command is %s ", strings.Join(cmdStrs, " "))
	reader := strings.NewReader(strings.Join(cmdStrs, " "))
	output, stderr, err := k.Exec(Namespace, PodName, containername, reader, bashcmd)
	if err != nil {
		log.Info("output=[" + output + "]")
		log.Info("stderr=[" + stderr + "]")
		log.Error(err)
		os.Exit(2)
	}
	log.Info("output=[" + output + "]")
	log.Info("stderr=[" + stderr + "]")

	log.Info("pgo-backrest ends")

}

// exec returns the stdout and stderr from running a command inside an existing container.
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
