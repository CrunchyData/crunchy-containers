package cron

import (
	"time"

	"github.com/crunchydata/crunchy-containers/tools/kubeapi"
	cv2 "gopkg.in/robfig/cron.v2"
)

type Cron struct {
	entries       map[string]cv2.EntryID
	kubeClient    *kubeapi.KubeAPI
	CronClient    *cv2.Cron
	label         string
	namespace     string
	scheduleTypes []string
}

type ScheduleTemplate struct {
	Version      string    `json:"version"`
	Name         string    `json:"name"`
	Created      time.Time `json:"created"`
	Schedule     string    `json:"schedule"`
	Namespace    string    `json:"namespace"`
	Type         string    `json:"type"`
	PGBackRest   `json:"pgbackrest,omitempty"`
	PGBaseBackup `json:"pgbasebackup,omitempty"`
}

type PGBackRest struct {
	Deployment string    `json:"deployment"`
	Label      string    `json:"label"`
	Container  string    `json:"container"`
	Type       string    `json:"type"`
	Options    []Options `json:"options"`
}

type PGBaseBackup struct {
	BackupHost      string `json:"backupHost"`
	BackupPass      string `json:"backupPass"`
	BackupPort      string `json:"backupPort"`
	BackupUser      string `json:"backupUser"`
	BackupVolume    string `json:"backupVolume"`
	ImagePrefix     string `json:"imagePrefix"`
	ImageTag        string `json:"imageTag"`
	Secret          string `json:"secret"`
	SecurityContext `json:"securityContext"`
}

type Options struct {
	Name  string `json:"name,omitempty"`
	Value string `json:"value,omitempty"`
}

type SecurityContext struct {
	FSGroup            int   `json:"fsGroup,omitempty"`
	SupplementalGroups []int `json:"supplementalGroups,omitempty"`
}
