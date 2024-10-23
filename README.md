# udn-cnv-demo

A demo using CNV/kubevirt on openshift with OVN-K UDN (user defined networks)

## Requirements

* An AWS account for openshift devcluster* (you have a ~/.aws/ dir with creds)
* 

*...It could be potentially useful in parts without an AWS cluster spin up.

## Usage

## Scratchpad

This worked for a CNV migration!

oc new-project doug
oc label --overwrite ns doug pod-security.kubernetes.io/enforce=privileged

oc create -f nfs.yml

oc get svc

(save the IP and use below)

helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --set nfs.server=172.30.190.178 \
  --set nfs.path=/ \
  --set nfs.mountOptions[0]=nfsvers=4 \
  --set storageClass.accessModes=ReadWriteMany

```
oc create -f dv-url.yml
```

*OR*

```
oc create -f dv.yml
virtctl image-upload dv fedora40-upload   --image-path=/home/centoshdd/qcow/Fedora-Cloud-Base-Generic.x86_64-40-1.14.qcow2   --insecure
```

## UDN

oc create -f udn.yml

oc create -f vm.yml

virtctl console fedora-vm 
(login with: fedora/fedora)

oc get pod virt-launcher-fedora-vm-sz7tr -o jsonpath="{.metadata.annotations['k8s\.ovn\.org/pod-networks']}"

