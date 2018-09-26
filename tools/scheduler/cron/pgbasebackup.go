package cron

import (
	"bytes"
	"encoding/json"
	"fmt"
	"html/template"
	"io/ioutil"
	"os"

	"github.com/crunchydata/crunchy-containers/tools/kubeapi"
	log "github.com/sirupsen/logrus"
	v1batch "k8s.io/api/batch/v1"
	kerrors "k8s.io/apimachinery/pkg/api/errors"
)

var BackupJobTemplate *template.Template

const templateDirEnv = "TEMPLATE_DIR"

func init() {
	templateDir := os.Getenv(templateDirEnv)
	if templateDir == "" {
		log.WithFields(log.Fields{}).Fatalf("Failed to get template directory environment: %s", templateDirEnv)
	}

	buf, err := ioutil.ReadFile(templateDir)
	if err != nil {
		log.WithFields(log.Fields{}).Fatalf("Failed to open template: %s", err)
	}
	BackupJobTemplate = template.Must(template.New("backup").Parse(string(buf)))
}

type BackBaseBackupJob struct {
	Name            string
	PvcName         string
	CCPImagePrefix  string
	CCPImageTag     string
	BackupHost      string
	BackupUser      string
	BackupPass      string
	BackupPort      string
	SecurityContext SecurityContext
	Secret          string
	Namespace       string
	client          *kubeapi.KubeAPI
}

func (s *ScheduleTemplate) NewBackBaseBackupSchedule(client *kubeapi.KubeAPI) BackBaseBackupJob {
	return BackBaseBackupJob{
		Name:            s.Name,
		CCPImagePrefix:  s.PGBaseBackup.ImagePrefix,
		CCPImageTag:     s.PGBaseBackup.ImageTag,
		BackupHost:      s.PGBaseBackup.BackupHost,
		BackupUser:      s.PGBaseBackup.BackupUser,
		BackupPass:      s.PGBaseBackup.BackupPass,
		BackupPort:      s.PGBaseBackup.BackupPort,
		PvcName:         s.PGBaseBackup.BackupVolume,
		Secret:          s.PGBaseBackup.Secret,
		SecurityContext: s.PGBaseBackup.SecurityContext,
		Namespace:       s.Namespace,
		client:          client,
	}
}

func (b BackBaseBackupJob) Run() {
	contextLogger := log.WithFields(log.Fields{
		"namespace": b.Namespace,
		"host":      b.BackupHost,
		"port":      b.BackupPort})
	contextLogger.Info("Running pgBaseBackup Job")

	secret, err := b.client.GetSecret(b.Namespace, b.Secret)
	if err != nil {
		contextLogger.WithFields(log.Fields{
			"error": err}).Error("Failed to retreive secret for backup credentials")
		return
	}

	if err := b.setCredentials(secret.Data); err != nil {
		contextLogger.WithFields(log.Fields{
			"secret": b.Secret}).Error("Failed to set username and/or password (does not exist in secret)")
	}

	var doc2 bytes.Buffer
	if err := BackupJobTemplate.Execute(&doc2, b); err != nil {
		contextLogger.WithFields(log.Fields{
			"error": err}).Error("Failed to render job template")
		return
	}

	oldJob, err := b.client.GetJob(b.Namespace, b.Name)
	if !(kerrors.IsNotFound(err)) {
		if err := b.client.DeleteJob(b.Namespace, oldJob); err != nil {
			contextLogger.WithFields(log.Fields{
				"error": err,
			}).Error("Failed to delete backup job")
			return
		}
		if err := b.client.IsJobDeleted(b.Namespace, oldJob); err != nil {
			contextLogger.WithFields(log.Fields{
				"error": err,
			}).Error("Failed waiting for backup job to delete")
			return
		}
	}

	newJob := &v1batch.Job{}
	if err := json.Unmarshal(doc2.Bytes(), newJob); err != nil {
		contextLogger.WithFields(log.Fields{
			"error": err,
		}).Error("Failed unmarshaling job template")
		return
	}

	job, err := b.client.CreateJob(b.Namespace, newJob)
	if err != nil {
		contextLogger.WithFields(log.Fields{
			"error": err,
		}).Error("Failed creating backup job")
		return
	}

	if err := b.client.IsJobComplete(b.Namespace, job); err != nil {
		contextLogger.WithFields(log.Fields{
			"error": err,
		}).Error("Failed to run backup job")
		return
	}
}

func (s *ScheduleTemplate) pvcString() string {
	return fmt.Sprintf("\"persistentVolumeClaim\": { \"claimName\": \"%s\"}", s.BackupVolume)
}

func (b *BackBaseBackupJob) setCredentials(data map[string][]byte) error {
	if val, ok := data["username"]; ok {
		b.BackupUser = string(val)
	} else {
		return fmt.Errorf("Username does not exist in secret")
	}

	if val, ok := data["password"]; ok {
		b.BackupPass = string(val)
	} else {
		return fmt.Errorf("Password does not exist in secret")
	}

	return nil
}
