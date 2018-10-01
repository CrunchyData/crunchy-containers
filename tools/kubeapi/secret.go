package kubeapi

import (
	"k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

func (k *KubeAPI) GetSecret(namespace, name string) (*v1.Secret, error) {
	return k.Client.CoreV1().Secrets(namespace).Get(name, metav1.GetOptions{})
}
