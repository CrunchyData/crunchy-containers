---
title: "Using the Images"
date: 
draft: false
weight: 50
---

# Running the Examples

The Kubernetes and OpenShift examples in this guide have been designed using
single-node Kubernetes/OCP clusters whose host machines provide any required supporting 
infrastructure or services (e.g. local HostPath storage or access to an NFS share). Therefore, for
the best results when running these examples, it is recommended that you utilize a single-node 
architecture as well.

Additionally, the examples located in the **kube** directory work on both Kubernetes and OpenShift.
Please ensure the `CCP_CLI` environment variable is set to the correct binary for your environment,
as shown below:

```bash
# Kubernetes
export CCP_CLI=kubectl

# OpenShift
export CCP_CLI=oc
```
_**NOTE:** Set the `CCP_CLI` environment variable in `.bashrc` to ensure the examples will work
properly in your environment_

## Example Conventions

The examples provided in Crunchy Container Suite are simple examples that
are meant to demonstrate key Crunchy Container Suite features.  These
examples can be used to build more production level deployments
as dictated by user requirements specific to their operating
environments.

The examples generally follow these conventions:
- There is a **run.sh** script that you will execute to start the example
- There is a **cleanup.sh** script that you will execute to shutdown and cleanup the example
- Each example will create resources such as Secrets, ConfigMaps, Services, and 
PersistentVolumeClaims, all which follow a naming convention of 
`<example name>-<optional description suffix>`. For example, an example called **primary** might 
have a PersistentVolumeClaim called **primary-pgconf** to describe the purpose of that particular 
PVC.
- The folder names for each example give a clue as to which Container Suite feature it 
demonstrates. For instance, the `examples/kube/pgaudit` example demonstrates how to enable the 
**pg_audit** capability in the **crunchy-postgres** container.

## Helpful Resources

Here are some useful resources for finding the right commands to troubleshoot and modify containers
in the various environments shown in this guide:

- [Docker Cheat Sheet](http://www.bogotobogo.com/DevOps/Docker/Docker-Cheat-Sheet.php)
- [Kubectl Cheat Sheet](https://kubernetes.io/docs/user-guide/kubectl-cheatsheet/)
- [OpenShift Cheat Sheet](https://github.com/nekop/openshift-sandbox/blob/master/docs/command-cheatsheet.md)
- [Helm Cheat Sheet](https://github.com/kubernetes/helm/blob/master/docs/using_helm.md)

## <a name="crunchy-container-suite-examples"></a>Crunchy Container Suite Examples

Now that your environment has been properly configured for the Crunchy Container Suite and you have
reviewed the guidance for running the examples, you are ready to run the Crunchy 
Container Suite examples.  Therefore, please proceed to the next section in order to find the 
examples that can now be run in your environment.