package kubeapi

import (
	"fmt"
	"time"

	apps "k8s.io/api/apps/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// GetDeployment method returns a deployment data structure for a
// given deployment in a given namespace.
func (k *KubeAPI) GetDeployment(namespace, deployment string) (*apps.Deployment, error) {
	return k.Client.AppsV1().Deployments(namespace).Get(deployment, metav1.GetOptions{})
}

// GetDeploymentPods method returns the pods associated with a
// given deployment in a given namespace.
func (k *KubeAPI) GetDeploymentPods(namespace, deployment string) ([]string, error) {
	d, err := k.Client.AppsV1().Deployments(namespace).Get(deployment, metav1.GetOptions{})
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

// DeleteDeployment method deletes a given deployment in a given
// namespace.
func (k *KubeAPI) DeleteDeployment(namespace, deployment string) error {
	return k.Client.AppsV1().Deployments(namespace).Delete(deployment, &metav1.DeleteOptions{})
}

// IsDeploymentReady method tests if a deployment is ready to be
// used.
func (k *KubeAPI) IsDeploymentReady(namespace, deployment string) (bool, error) {
	timeout := time.After(k.Timeout)
	tick := time.Tick(500 * time.Millisecond)
	for {
		select {
		case <-timeout:
			return false, fmt.Errorf("Timed out waiting for deployment to run: %s", deployment)
		case <-tick:
			d, err := k.GetDeployment(namespace, deployment)
			if err != nil {
				return false, err
			}
			if d.Status.Replicas == d.Status.ReadyReplicas {
				return true, nil
			}
		}
	}
}
