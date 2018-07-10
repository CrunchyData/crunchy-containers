package kubeapi

import (
	"errors"
	"fmt"
	"io"
	"strconv"
	"time"

	"k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// GetPod method returns a pod data structure for a
// given pod in a given namespace.
func (k *KubeAPI) GetPod(namespace, pod string) (*v1.Pod, error) {
	return k.Client.CoreV1().Pods(namespace).Get(pod, metav1.GetOptions{})
}

// ListPods method returns all pods in a given namespace.
func (k *KubeAPI) ListPods(namespace string) (*v1.PodList, error) {
	return k.Client.CoreV1().Pods(namespace).List(metav1.ListOptions{})
}

// DeletePod method deletes a given pod in a given namespace.
func (k *KubeAPI) DeletePod(namespace, pod string) error {
	return k.Client.CoreV1().Pods(namespace).Delete(pod, &metav1.DeleteOptions{})
}

// IsPodDeleted method tests if a pod has been terminated.
func (k *KubeAPI) IsPodDeleted(namespace, pod string) bool {
	timeout := time.After(k.Timeout)
	tick := time.Tick(500 * time.Millisecond)
	for {
		select {
		case <-timeout:
			return false
		case <-tick:
			_, err := k.GetPod(namespace, pod)
			if err != nil {
				return true
			}
		}
	}
}

// IsPodRunning method tests if a pod is running.
func (k *KubeAPI) IsPodRunning(namespace, pod string) (bool, error) {
	timeout := time.After(k.Timeout)
	tick := time.Tick(500 * time.Millisecond)
	for {
		select {
		case <-timeout:
			return false, fmt.Errorf("timed out waiting for pod to run: %s", pod)
		case <-tick:
			p, err := k.GetPod(namespace, pod)
			if err != nil {
				return false, err
			}

			switch p.Status.Phase {
			case "Pending":
				continue
			case "ContainerCreating":
				continue
			case "Failed":
				return false, fmt.Errorf("Pod failed to run: %s", pod)
			case "Running":
				return true, nil
			case "Succeeded":
				return true, nil
			case "Unknown":
				return false, errors.New("Unknown error")
			default:
				return false, errors.New("Unknown pod status (this should not happen)")
			}
		}
	}
}

// IsPodReady method tests if a pod is ready.
func (k *KubeAPI) IsPodReady(namespace string, pod string) (bool, error) {
	timeout := time.After(k.Timeout)
	tick := time.Tick(500 * time.Millisecond)
	for {
		select {
		case <-timeout:
			return false, fmt.Errorf("timed out waiting for pod to be ready: %s", pod)
		case <-tick:
			p, err := k.GetPod(namespace, pod)
			if err != nil {
				return false, err
			}
			for _, v := range p.Status.Conditions {
				if v.Type == "Ready" && v.Status == "True" {
					return true, nil
				}
			}
		}
	}
}

// CheckPods method is a wrapper that checks if a pod is running
// and ready.
func (k *KubeAPI) CheckPods(namespace string, pods []string) error {
	for _, pod := range pods {
		if ok, err := k.IsPodRunning(namespace, pod); !ok {
			return err
		}
	}
	for _, pod := range pods {
		if ok, err := k.IsPodReady(namespace, pod); !ok {
			return err
		}
	}
	return nil
}

// LogOpts is a data structure used to configure
// log captures for a container.
type LogOpts struct {
	Container  string
	Namespace  string
	Pod        string
	Follow     bool
	Previous   bool
	Timestamps bool
}

// Logs method returns the logs for a container within a pod.
func (k *KubeAPI) Logs(l *LogOpts, out io.Writer) error {
	req := k.Client.CoreV1().RESTClient().Get().
		Namespace(l.Namespace).
		Name(l.Pod).
		Resource("pods").
		SubResource("log").
		Param("follow", strconv.FormatBool(l.Follow)).
		Param("container", l.Container).
		Param("previous", strconv.FormatBool(l.Previous)).
		Param("timestamps", strconv.FormatBool(l.Timestamps))

	readCloser, err := req.Stream()
	if err != nil {
		return err
	}

	defer readCloser.Close()
	_, err = io.Copy(out, readCloser)
	return err
}
