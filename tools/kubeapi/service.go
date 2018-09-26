package kubeapi

import (
	"k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// GetService method returns a given service in a given namespace.
func (k *KubeAPI) GetService(namespace, service string) (*v1.Service, error) {
	return k.Client.CoreV1().Services(namespace).Get(service, metav1.GetOptions{})
}

// GetService method deletes a given service in a given namespace.
func (k *KubeAPI) DeleteService(namespace, service string) error {
	return k.Client.CoreV1().Services(namespace).Delete(service, &metav1.DeleteOptions{})
}
