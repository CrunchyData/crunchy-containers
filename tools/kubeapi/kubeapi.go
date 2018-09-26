package kubeapi

import (
	"os"
	"path/filepath"
	"time"

	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"
    _ "k8s.io/client-go/plugin/pkg/client/auth/gcp"
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
