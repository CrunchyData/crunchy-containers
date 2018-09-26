package kubeapi

import (
	"k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

type ConfigMap struct {
	Name, Filename, Data []byte
}

func (k *KubeAPI) GetConfigMaps(namespace string, label, field string) ([]ConfigMap, error) {
	opts := metav1.ListOptions{
		LabelSelector: label,
		FieldSelector: field,
	}

	mapList, err := k.ListConfigMaps(namespace, opts)
	if err != nil {
		return nil, err
	}

	var configMaps []ConfigMap
	for _, v := range mapList.Items {
		c, err := k.GetConfigMap(namespace, v.GetName(), metav1.GetOptions{})
		if err != nil {
			return nil, err
		}
		var configMap ConfigMap
		for name, data := range c.Data {
			configMap.Name = []byte(c.Name)
			configMap.Filename = []byte(name)
			configMap.Data = []byte(data)
			configMaps = append(configMaps, configMap)
		}
	}

	return configMaps, nil
}

func (k *KubeAPI) GetConfigMap(namespace, name string, opts metav1.GetOptions) (*v1.ConfigMap, error) {
	return k.Client.CoreV1().ConfigMaps(namespace).Get(name, opts)
}

func (k *KubeAPI) ListConfigMaps(namespace string, opts metav1.ListOptions) (*v1.ConfigMapList, error) {
	return k.Client.CoreV1().ConfigMaps(namespace).List(opts)
}
