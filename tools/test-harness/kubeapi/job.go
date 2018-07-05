package kubeapi

import (
	"fmt"
	"time"

	v1batch "k8s.io/api/batch/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// GetJob method returns a job data structure for a
// given job in a given namespace.
func (k *KubeAPI) GetJob(namespace, job string) (*v1batch.Job, error) {
	return k.Client.BatchV1().Jobs(namespace).Get(job, metav1.GetOptions{})
}

// IsJobComplete method tests if a job has completed
// successfully.
func (k *KubeAPI) IsJobComplete(namespace string, job string) (bool, error) {
	timeout := time.After(k.Timeout)
	tick := time.Tick(500 * time.Millisecond)
	for {
		select {
		case <-timeout:
			return false, fmt.Errorf("timed out waiting for job to complete: %s", job)
		case <-tick:
			j, err := k.GetJob(namespace, job)
			if err != nil {
				return false, err
			}
			if j.Status.Failed != 0 {
				return false, fmt.Errorf("job failed to run: %s", job)
			}
			if j.Status.Succeeded != 0 {
				return true, nil
			}
		}
	}
}
