---
title: "Troubleshooting"
date: 
draft: false
weight: 301
---


## Kube  
[Troubleshooting kubeadm](https://kubernetes.io/docs/setup/independent/troubleshooting-kubeadm/)

### 509 cert errors
If you see `Unable to connect to the server: x509: certificate has expired or is not yet valid` 
try resetting ntp, the date/time is not set on local system correctly.

If you see `Unable to connect to the server: x509: certificate signed by unknown authority (possibly because of "crypto/rsa: verification error" while trying to verify candidate authority certificate "kubernetes")`
Try running these commands as a regular user:
```
  mv  $HOME/.kube $HOME/.kube.bak
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config 

```
### gcloud errors
If you see this error ` ERROR: (gcloud.container.clusters.get-credentials) Unable to create private file [/etc/kubernetes/admin.conf]: [Errno 1] Operation not permitted: '/etc/kubernetes/admin.conf'` create a backup
of admin.conf and delete the admin.conf then try and reconnect to the cluster.

### gcloud authentication example
Here are the commands used to authenticate to gcloud
```
cloud auth login
gcloud config set project <your gcloud project>
gcloud auth configure-docker
```

If you see gcloud authentiation errors execute `gcloud config list` then reauthenticate using the
commands from above then rerun `gcloud config list` the results will show different values
if authentication was an issue.


## OCP 
[Troubleshooting OpenShift Container Platform: Basics](https://access.redhat.com/solutions/1542293)
