This directory is used to store sample PV and PVCs
used for running the examples.

They give you the option of specifying an NFS or HostPath
configuration for your PVs.

The script "create-pvc.sh" will create three bound PVCs.
These can be viewed through the command "oc get pvc".

The script "create-pv.sh" is used in conjunction with the
command line arguments "hostPath", "nfs", and "gce" to
create the corresponding containers. 
