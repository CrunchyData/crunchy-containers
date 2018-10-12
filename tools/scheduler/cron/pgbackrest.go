package cron

import (
	"fmt"

	"github.com/crunchydata/crunchy-containers/tools/kubeapi"
	log "github.com/sirupsen/logrus"
)

type BackRestBackupJob struct {
	backupType string
	stanza     string
	namespace  string
	deployment string
	label      string
	container  string
	client     *kubeapi.KubeAPI
}

func (s *ScheduleTemplate) NewBackRestSchedule(stanza string, client *kubeapi.KubeAPI) BackRestBackupJob {
	return BackRestBackupJob{
		backupType: s.PGBackRest.Type,
		stanza:     stanza,
		namespace:  s.Namespace,
		deployment: s.PGBackRest.Deployment,
		label:      s.PGBackRest.Label,
		container:  s.PGBackRest.Container,
		client:     client,
	}
}

func (b BackRestBackupJob) Run() {
	contextLogger := log.WithFields(log.Fields{
		"namespace":  b.namespace,
		"deployment": b.deployment,
		"label":      b.label,
		"container":  b.container,
		"backupType": b.backupType})

	contextLogger.Info("Running pgBackRest backup")

	cmd := []string{
		"/usr/bin/pgbackrest",
		fmt.Sprintf("--stanza=%s", b.stanza),
		"backup", fmt.Sprintf("--type=%s", b.backupType),
	}

	if b.label != "" {
		deployments, err := b.client.ListDeployments(b.namespace, b.label)
		if err != nil {
			contextLogger.WithFields(log.Fields{
				"error": err,
			}).Error("Failed getting deployments from label")
			return
		}
		if len(deployments.Items) != 1 {
			contextLogger.WithFields(log.Fields{
				"error":       err,
				"label_count": len(deployments.Items),
			}).Error("Failed to get one deployment from label")
			return
		}
		b.deployment = deployments.Items[0].Name
	}

	pods, err := b.client.GetDeploymentPods(b.namespace, b.deployment)
	if err != nil {
		contextLogger.WithFields(log.Fields{
			"error": err,
		}).Error("Failed getting pods from deployment")
		return
	}

	if len(pods) == 0 {
		contextLogger.WithFields(log.Fields{}).Error("No pods found in deployment")
		return
	}

	_, stderr, err := b.client.Exec(b.namespace, pods[0], b.container, cmd)
	if err != nil {
		contextLogger.WithFields(log.Fields{
			"error":  err,
			"output": stderr,
		}).Error("Failed execing into container")
		return
	}
}
