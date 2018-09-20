package kubeapi

import (
	"fmt"
	"time"

	apps "k8s.io/api/apps/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// GetStatefulSet method returns a given statefulset in a given namespace.
func (k *KubeAPI) GetStatefulSet(namespace, statefulset string) (*apps.StatefulSet, error) {
	return k.Client.AppsV1().StatefulSets(namespace).Get(statefulset, metav1.GetOptions{})
}

// GetStatefulSetPods method returns all the pods associated with a given
// StatefulSet.
func (k *KubeAPI) GetStatefulSetPods(namespace, statefulset string) ([]string, error) {
	d, err := k.Client.AppsV1().StatefulSets(namespace).Get(statefulset, metav1.GetOptions{})
	if err != nil {
		return nil, err
	}

	var podList []string
	for key, val := range d.Labels {
		label := fmt.Sprintf("%s=%s", key, val)
		pods, err := k.Client.CoreV1().Pods(namespace).List(metav1.ListOptions{LabelSelector: label})
		if err != nil {
			return nil, err
		}
		for _, pod := range pods.Items {
			podList = append(podList, pod.Name)
		}
	}
	return podList, nil
}

// DeleteStatefulSet method deletes a given statefulset in a given namespace.
func (k *KubeAPI) DeleteStatefulSet(namespace, statefulset string) error {
	return k.Client.AppsV1().StatefulSets(namespace).Delete(statefulset, &metav1.DeleteOptions{})
}

// IsStatefulSetReady method tests if a statefulset is ready to use.
func (k *KubeAPI) IsStatefulSetReady(namespace, statefulset string) (bool, error) {
	timeout := time.After(k.Timeout)
	tick := time.Tick(500 * time.Millisecond)
	for {
		select {
		case <-timeout:
			return false, fmt.Errorf("Timed out waiting for statefulset to run: %s", statefulset)
		case <-tick:
			d, err := k.GetStatefulSet(namespace, statefulset)
			if err != nil {
				return false, err
			}
			if d.Status.Replicas == d.Status.ReadyReplicas {
				return true, nil
			}
		}
	}
}
