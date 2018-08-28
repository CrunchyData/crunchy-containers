package kubeapi

import (
"flag"
"path/filepath"
"os"

// "k8s.io/apimachinery/pkg/api/errors"
// metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
"k8s.io/client-go/kubernetes"
"k8s.io/client-go/tools/clientcmd"
"k8s.io/client-go/rest"
// "k8s.io/kubernetes/pkg/client/clientset_generated/internalclientset/clientset"
)

func GetClientConfigOOC ()(* kubernetes.Clientset, error) {

	var kubeconfig *string
	var config *rest.Config 
	var err error
	if home := homeDir(); home != "" {
		kubeconfig = flag.String("kubeconfig", filepath.Join(home, ".kube", "config"), "")
		// use the current context in kubeconfig
		config, err = clientcmd.BuildConfigFromFlags("", *kubeconfig)

		if err != nil {
				panic(err.Error())
		}

	} else {
		// kubeconfig = flag.String("kubeconfig", "", "/etc/origin/master/admin.kubeconfig")
		config, err = rest.InClusterConfig()
	}
	flag.Parse()


	// create the clientset
	clientset, err := kubernetes.NewForConfig(config)

	if err != nil {
		panic(err.Error())
	}

	return clientset, err
}

func homeDir() string {
	if h := os.Getenv("HOME"); h != "" {
		return h
	}
	return os.Getenv("USERPROFILE") // windows
}