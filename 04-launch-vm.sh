#!/bin/bash

# Function to log messages with a timestamp
log() {
  local message="$1"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $message"
}

log "creating poc1 namespace"
oc create -f ns-quique.yml
oc project poc1

# Preload pod image
log "Creating DaemonSet for image preload..."
oc apply -f image-preload.yml

log "Waiting for all DaemonSet pods to be ready..."
oc wait --for=jsonpath='{.status.numberAvailable}'=$(oc get daemonset image-preload -n poc1 -o jsonpath='{.status.desiredNumberScheduled}') daemonset/image-preload -n poc1 --timeout=5m

log "Deleting DaemonSet for image preload..."
oc delete -f image-preload.yml

log "Creating UDN, and quique VMs..."
oc apply -f udn.yml
oc create -f pod.yml
oc create -f vm-quique.yml

# log "Creating UDN CR and VM..."
# oc project demo
# oc create -f vm.yml

log "You can console to your vm with:"
log "virtctl console vmi-fedora-a"
log "(login with: fedora/fedora)"

# oc get pod virt-launcher-fedora-vm-sz7tr -o jsonpath="{.metadata.annotations['k8s\.ovn\.org/pod-networks']}"

