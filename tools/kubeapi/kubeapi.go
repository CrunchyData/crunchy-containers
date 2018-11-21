package kubeapi

import (
	"bytes"
	"fmt"
	"os"
	"path/filepath"
	"time"

	"k8s.io/client-go/kubernetes"
	_ "k8s.io/client-go/plugin/pkg/client/auth/gcp"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"
)

// KubeAPI is the main data structure containing
// the various settings required to use the package.
// All methods use this structure as the receiver.
type KubeAPI struct {
	Client    *kubernetes.Clientset
	Config    *rest.Config
	Timeout   time.Duration
	InCluster bool
}

// New returns a new instance of KubeAPI.
func New(t time.Duration, inCluster bool) (*KubeAPI, error) {
	var api KubeAPI
	api.Timeout = t
	api.InCluster = inCluster
	var err error

	if api.InCluster {
		api.Config, err = rest.InClusterConfig()
		if err != nil {
			return &api, err
		}
	} else {
		kubeconfig := filepath.Join(homeDir(), ".kube", "config")
		api.Config, err = clientcmd.BuildConfigFromFlags("", kubeconfig)
	}

	if err != nil {
		return &api, err
	}

	api.Client, err = kubernetes.NewForConfig(api.Config)
	if err != nil {
		return &api, err
	}
	return &api, nil
}

func homeDir() string {
	if h := os.Getenv("HOME"); h != "" {
		return h
	}
	return os.Getenv("USERPROFILE") // windows
}

func createLabel(m map[string]string) string {
	b := new(bytes.Buffer)
	count := 0
	for key, value := range m {
		fmt.Fprintf(b, "%s=%s", key, value)
		if count < (len(m) - 1) {
			fmt.Fprintf(b, ",")
		}
		count++
	}
	return b.String()
}
