package kubeapi

import (
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// CreateNamespace method creates a new namespace in Kubernetes.
func (k *KubeAPI) CreateNamespace(name string) (*corev1.Namespace, error) {
	ns := &corev1.Namespace{
		ObjectMeta: metav1.ObjectMeta{Name: name},
	}
	return k.Client.CoreV1().Namespaces().Create(ns)
}

// CreateNamespace method deletes a namespace in Kubernetes.
func (k *KubeAPI) DeleteNamespace(name string) error {
	k.Client.CoreV1().Namespaces().Delete(name, &metav1.DeleteOptions{})
	return nil
}
