package tests

import (
	"bytes"
	"crypto/tls"
	"fmt"
	"math/rand"
	"net/http"
	"os"
	"testing"
	"time"

	"github.com/crunchydata/crunchy-containers/tools/test-harness/kubeapi"
	"github.com/crunchydata/crunchy-containers/tools/test-harness/runner"
)

func (h *harness) runExample(dir string, env []string, t *testing.T) (string, error) {
	run := fmt.Sprintf("${CCPROOT}/%s", dir)
	env = append(env, fmt.Sprintf("CCP_NAMESPACE=%s", h.Namespace))
	out, err := runner.Run(os.ExpandEnv(run), env)
	return out, err
}

func getStatus(url string) error {
	http.DefaultTransport.(*http.Transport).TLSClientConfig = &tls.Config{InsecureSkipVerify: true}
	resp, err := http.Get(url)
	if err != nil {
		return err
	}

	if resp.StatusCode < 200 && resp.StatusCode > 299 {
		return fmt.Errorf("responded with a non 200 code: %d", resp.StatusCode)
	}
	return nil
}

type report struct {
	Container string
	Namespace string
	Pod       string
	Logs      string
	Env       string
	Image     string
	Volumes   string
}

func (h *harness) createReport() ([]string, error) {
	var reports []*report
	var out []string

	pods, err := h.Client.ListPods(h.Namespace)
	if err != nil {
		return nil, err
	}

	for _, p := range pods.Items {
		for _, container := range p.Spec.Containers {
			logOpts := &kubeapi.LogOpts{
				Container:  container.Name,
				Namespace:  p.Namespace,
				Pod:        p.Name,
				Follow:     false,
				Previous:   false,
				Timestamps: false,
			}
			var logs bytes.Buffer
			if err := h.Client.Logs(logOpts, &logs); err != nil {
				return nil, err
			}

			var envs string
			for _, env := range container.Env {
				envs += fmt.Sprintf("\n\t%s: %s", env.Name, env.Value)
			}

			var vols string
			for _, vol := range container.VolumeMounts {
				vols += fmt.Sprintf("\n\t%s: %s", vol.Name, vol.MountPath)
			}

			report := &report{
				Container: container.Name,
				Image:     container.Image,
				Logs:      logs.String(),
				Namespace: p.Namespace,
				Pod:       p.Name,
				Env:       envs,
				Volumes:   vols,
			}

			reports = append(reports, report)
		}
	}

	for _, v := range reports {
		out = append(out, v.prepare())
	}
	return out, nil
}

func (r *report) prepare() string {
	var report string
	report += "\n##########################################\n"
	report += fmt.Sprintf("Namespace: %s\n", r.Namespace)
	report += fmt.Sprintf("Pod Name: %s\n", r.Pod)
	report += fmt.Sprintf("Container Name: %s\n", r.Container)
	report += fmt.Sprintf("Image: %s\n", r.Image)
	report += fmt.Sprintf("Environment Vars: %s\n", r.Env)
	report += fmt.Sprintf("Volumes: %s\n", r.Volumes)
	report += fmt.Sprintf("Logs: \n%s", r.Logs)
	return report
}

func randomString(length int) string {
	var charset = "abcdefghijklmnopqrstuvwxyz0123456789"

	seededRand := rand.New(
		rand.NewSource(time.Now().UnixNano()))
	b := make([]byte, length)
	for i := range b {
		b[i] = charset[seededRand.Intn(len(charset))]
	}
	return string(b)
}

func randomPort() int {
	const min = 49152
	const max = 65535
	seed := rand.NewSource(time.Now().UnixNano())
	r := rand.New(seed)
	return r.Intn(max-min) + min
}
