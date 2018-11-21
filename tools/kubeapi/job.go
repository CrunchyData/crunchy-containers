package kubeapi

import (
	"errors"
	"fmt"
	"time"

	v1batch "k8s.io/api/batch/v1"
	kerrors "k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

func (k *KubeAPI) CreateJob(namespace string, job *v1batch.Job) (*v1batch.Job, error) {
	return k.Client.BatchV1().Jobs(namespace).Create(job)
}

func (k *KubeAPI) DeleteJob(namespace string, job *v1batch.Job) error {
	cascade := metav1.DeletePropagationForeground
	return k.Client.BatchV1().Jobs(namespace).Delete(job.Name, &metav1.DeleteOptions{PropagationPolicy: &cascade})
}

// GetJob method returns a job data structure for a
// given job in a given namespace.
func (k *KubeAPI) GetJob(namespace, job string) (*v1batch.Job, error) {
	return k.Client.BatchV1().Jobs(namespace).Get(job, metav1.GetOptions{})
}

// IsJobComplete method tests if a job has completed
// successfully.
func (k *KubeAPI) IsJobComplete(namespace string, job *v1batch.Job) error {
	timeout := time.After(k.Timeout)
	tick := time.Tick(500 * time.Millisecond)
	for {
		select {
		case <-timeout:
			return fmt.Errorf("timed out waiting for job to complete: %s", job.Name)
		case <-tick:
			j, err := k.GetJob(namespace, job.Name)
			if err != nil {
				return err
			}
			if j.Status.Failed != 0 {
				return errors.New("job failed to run")
			}
			if j.Status.Succeeded != 0 {
				return nil
			}
		}
	}
}

// IsJobDeleted method tests if a job has deleted
// successfully.
func (k *KubeAPI) IsJobDeleted(namespace string, job *v1batch.Job) error {
	timeout := time.After(k.Timeout)
	tick := time.Tick(500 * time.Millisecond)
	for {
		select {
		case <-timeout:
			return fmt.Errorf("timed out waiting for job to delete: %s", job.Name)
		case <-tick:
			_, err := k.GetJob(namespace, job.Name)
			if err != nil && kerrors.IsNotFound(err) {
				return nil
			}
		}
	}
}
