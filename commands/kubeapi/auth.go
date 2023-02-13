package kubeapi

/*
 Copyright 2017 - 2023 Crunchy Data Solutions, Inc.
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
	"flag"
	log "github.com/sirupsen/logrus"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"
	"os"
	"path/filepath"
)

func GetClientConfig(oocFlag bool, namespaceFlag string) (*kubernetes.Clientset, string, error) {

	var kubeconfig *string
	var config *rest.Config
	var err error

	namespace := getNamespace(oocFlag, namespaceFlag) // this may call os.Exit(non-zero)

	if !oocFlag {
		config, err = rest.InClusterConfig()

		if err != nil {
			log.Error(err.Error())
			log.Info("If running outside of container, use [ -r | --remote ] flag")
			os.Exit(-1)
		}

	} else if home := homeDir(); home != "" {
		kubeconfig = flag.String("kubeconfig", filepath.Join(home, ".kube", "config"), "")
		// use the current context in kubeconfig
		config, err = clientcmd.BuildConfigFromFlags("", *kubeconfig)

		if err != nil {
			panic(err.Error())
		}

	} else {
		panic("Unable to obtain a cluster configuration. Exiting.")
	}
	flag.Parse()

	// create the clientset
	clientset, err := kubernetes.NewForConfig(config)

	if err != nil {
		panic(err.Error())
	}

	return clientset, namespace, err
}

func homeDir() string {
	if h := os.Getenv("HOME"); h != "" {
		return h
	}
	return os.Getenv("USERPROFILE") // windows
}

func getNamespace(outOfContainer bool, namespaceFlag string) string {

	if namespaceFlag != "" {
		return namespaceFlag
	}

	if ns := os.Getenv("CCP_NAMESPACE"); ns != "" || outOfContainer {
		return ns
	}

	log.Error("CCP_NAMESPACE must be set.")
	// if namespace not set, exit
	os.Exit(-1)

	return "" // make compiler happy - never executed
}
