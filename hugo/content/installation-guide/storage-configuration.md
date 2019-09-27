---
title: "Storage Configuration"
date: 
draft: false
weight: 105
---


# Storage Configuration

## Available Storage Types

The Crunchy Container Suite is officially tested using two different storage backends:

- HostPath (single node testing)
- NFS (single and multi-node testing)

Other storage backends work as well, including GCE, EBS, ScaleIO, and
others, but may require you to modify various examples or configuration.

The Crunchy Container Suite is tested, developed, and examples are 
provided that use the various storage types listed above.  This 
ensures that customers have a high degree of choices when it comes 
to choosing a volume type.  HostPath and NFS allow precise host path
choices for where database volumes are persisted.  HostPath and NFS
also allow governance models where volume creation is performed
by an administrator instead of the application/developer team.

Where customers desire a dynamic form of volume creation (e.g. self service),
storage classes are also supported within the example set.

Environment variables are set to determine how and what storage
is to be used.

_**NOTE:** When running the examples using HostPath or NFS storage, the run scripts 
provided in the examples will create directories using the following pattern:_
```bash
$CCP_STORAGE_PATH/$CCP_NAMESPACE-<EXAMPLE_NAME>
```

## HostPath

HostPath is the simplest storage backend to setup. It is only feasible
on a single node but is sufficient for testing the examples.  In your `.bashrc`
file, add the following variables to specify the proper settings for your
the HostPath storage volume:
```bash
export CCP_SECURITY_CONTEXT=""
export CCP_STORAGE_PATH=/data
export CCP_STORAGE_MODE=ReadWriteMany
export CCP_STORAGE_CAPACITY=400M
```

_**NOTE:** It may be necessary to grant your user in OpenShift or Kubernetes the
rights to modify the **hostaccess** SCC. This can be done with the following command:_
```bash
oadm policy add-scc-to-user hostaccess $(oc whoami)
```

## NFS

NFS can also be utilized as a storage mechanism.  Instructions for setting up a NFS can be 
found in the **Configuration Notes for NFS** section below.

For testing with NFS, include the following variables in your **.bashrc** file, providing 
the proper configuration details for your NFS:
```bash
export CCP_SECURITY_CONTEXT='"supplementalGroups": [65534]'
export CCP_STORAGE_PATH=/nfsfileshare
export CCP_NFS_IP=<IP OF NFS SERVER>
export CCP_STORAGE_MODE=ReadWriteMany
export CCP_STORAGE_CAPACITY=400M
```

In the example above the group ownership of the NFS mount is assumed to be
**nfsnobody** or **65534**.  Additionally, it is recommended that root not be squashed on
the NFS share (using `no_root_squash`) in order to ensure the proper directories can be
created, modified and removed as needed for the various container examples.

Additionally, the examples in the Crunchy Container suite need access to the NFS in order to create
the directories utilized by the examples.  The NFS should therefore be mounted locally so that the 
`run.sh` scripts contained within the examples can complete the proper setup.

### Configuration Notes for NFS

- Most of the Crunchy containers run as the postgres UID (26), but you
will notice that when `supplementalGroups` is specified, the pod
will include the `nfsnobody` group in the list of groups for the pod user
- If you are running your NFS system with SELinux in enforcing mode, you will need to run the 
following command to allow NFS write permissions:

    ```bash
    sudo setsebool -P virt_use_nfs 1
    ```
- Detailed instructions for setting up a NFS server on Centos 7 can be found using the following link: 
    
    http://www.itzgeek.com/how-tos/linux/centos-how-tos/how-to-setup-nfs-server-on-centos-7-rhel-7-fedora-22.html

- If you are running your client on a VM, you will need to
add **insecure** to the exportfs file on the NFS server due to the way port
translation is done between the VM host and the VM instance.  For more details on this bug, please see the 
following link:

    http://serverfault.com/questions/107546/mount-nfs-access-denied-by-server-while-mounting

- A suggested best practice for tuning NFS for PostgreSQL is to configure the PostgreSQL fstab
mount options like so:

    ```bash
    proto=tcp,suid,rw,vers=3,proto=tcp,timeo=600,retrans=2,hard,fg,rsize=8192,wsize=8192
    ```

    And to then change your network options as follows:
    ```bash
    MTU=9000
    ```
- If interested in mounting the same NFS share multiple times on the same mount point,
look into the [noac mount option](https://www.novell.com/support/kb/doc.php?id=7010210)


{{% notice info %}}

When using NFS storage and two or more clusters share the same NFS storage directory, the clusters need to be uniquely named.

{{% / notice %}}


## Dynamic Storage

Dynamic storage classes can be used for the examples.  There
are various providers and solutions for dynamic storage, so please consult 
the Kubernetes documentation for additional details regarding supported 
storage choices.  The environment variable `CCP_STORAGE_CLASS` is used
in the examples to determine whether or not to create a PersistentVolume
manually, or if it will be created dynamically using a StorageClass.  In
the case of GKE, the default StorageClass is named **default**.  Storage
class names are determined by the Kubernetes administrator and can vary.

Using block storage requires a security context to be set
as follows:
```bash
export CCP_SECURITY_CONTEXT='"fsGroup":26'
export CCP_STORAGE_CLASS=standard
export CCP_STORAGE_MODE=ReadWriteOnce
export CCP_STORAGE_CAPACITY=400M
```
