#!/bin/bash

# Function to log messages with a timestamp
log() {
  local message="$1"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $message"
}

# Create a new project
log "Creating a new project called 'demo'."
oc new-project demo

# Set the namespace to use privileged security context
log "Setting security context to privileged for the demo namespace."
oc label --overwrite ns demo pod-security.kubernetes.io/enforce=privileged

# Deploy NFS
log "Deploying NFS server."
oc create -f nfs.yml
if [ $? -ne 0 ]; then
    log "Failed to create NFS server."
    exit 1
fi

# Wait for the NFS server to be ready
log "Waiting for the NFS server to be ready."
while ! oc get pod -l app=nfs-server | grep -q 'Running'; do
    # log "NFS server is not ready yet."
    sleep 2
done
log "NFS server is ready."

# Get the IP address of the NFS service
NFS_IP=$(oc get svc nfs-service -o jsonpath='{.spec.clusterIP}')
log "NFS service IP: $NFS_IP"

# Set up Helm repo if not already added
if helm repo list | grep -q 'nfs-subdir-external-provisioner'; then
    log "Helm repository already added."
else
    log "Adding Helm repository for NFS provisioner."
    helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
    helm repo update
fi

# Install NFS Subdir External Provisioner using Helm
log "Installing NFS Subdir External Provisioner via Helm."
helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --set nfs.server=$NFS_IP \
  --set nfs.path=/ \
  --set nfs.mountOptions[0]=nfsvers=4 \
  --set storageClass.accessModes=ReadWriteMany

# Wait for the NFS provisioner pods to be ready
log "Waiting for NFS Subdir External Provisioner pods to be ready."
until oc get pods -l app=nfs-subdir-external-provisioner -o jsonpath='{.items[*].status.conditions[?(@.type=="Ready")].status}' | grep -q "True"; do
    # log "NFS provisioner pods are not ready yet."
    sleep 2
done
log "NFS provisioner pods are ready."


# Deploy DataVolume
log "Creating DataVolume from dv-url.yml."
oc create -f dv-url.yml

# Wait for DataVolume to be complete
log "Wait 10 minutes for the image to upload..."
oc wait DataVolume/fedora40-upload --for=condition=Succeeded --timeout=10m
log "DataVolume is ready."
