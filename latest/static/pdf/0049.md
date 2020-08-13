---
title: "Troubleshooting"
date:
draft: false
weight: 8
---

## Kubernetes

[Troubleshooting kubeadm](https://kubernetes.io/docs/setup/independent/troubleshooting-kubeadm/)

### 509 Certificate Errors
If you see `Unable to connect to the server: x509: certificate has expired or is not yet valid`,
try resetting ntp. This generally indicates that the date/time is not set on local system correctly.

If you see `Unable to connect to the server: x509: certificate signed by unknown authority (possibly because of "crypto/rsa: verification error" while trying to verify candidate authority certificate "kubernetes")`,
try running these commands as a regular user:
```
  mv  $HOME/.kube $HOME/.kube.bak
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

```
### gcloud Errors
If you see the error ` ERROR: (gcloud.container.clusters.get-credentials) Unable to create private file [/etc/kubernetes/admin.conf]: [Errno 1] Operation not permitted: '/etc/kubernetes/admin.conf'`, create a backup
of admin.conf and delete the admin.conf before attempting to reconnect to the cluster.

### gcloud Authentication Example
The commands used to authenticate to gcloud are the following:
```
gcloud auth login
gcloud config set project <your gcloud project>
gcloud auth configure-docker
```

If you see gcloud authentication errors, execute `gcloud config list` then re-authenticate using the
commands from above. Finally, rerun `gcloud config list` - the results should show different values
if authentication was indeed the issue.


## OpenShift Container Platform

[Troubleshooting OpenShift Container Platform: Basics](https://access.redhat.com/solutions/1542293)
