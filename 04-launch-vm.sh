#!/bin/bash

# Function to log messages with a timestamp
log() {
  local message="$1"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $message"
}

log "creating namespace-c namespace"
oc create -f ns-quique.yml
oc project namespace-c

# Preload pod image
log "Creating DaemonSet for pod image preload..."
oc apply -f image-preload.yml

log "Waiting for all DaemonSet pods to be ready..."
oc wait --for=jsonpath='{.status.numberAvailable}'=$(oc get daemonset image-preload -n namespace-c -o jsonpath='{.status.desiredNumberScheduled}') daemonset/image-preload -n namespace-c --timeout=5m

log "Deleting DaemonSet for pod image preload..."
oc delete -f image-preload.yml


oc apply -f image-preload-vm.yml
log "Waiting for VM image to be pulled to all nodes..."

DESIRED_COUNT=3
TIMEOUT=300  # 5 minutes timeout in seconds
INTERVAL=5   # Check every 5 seconds
elapsed=0

while true; do
  CREATE_ERROR_COUNT=$(oc get pods -n namespace-c | grep image-preload-vm | grep -i createcontainererror | wc -l)

  if [ "$CREATE_ERROR_COUNT" -eq "$DESIRED_COUNT" ]; then
    log "All VM preload daemonset pods reached CreateContainerError, image should be cached on all nodes."
    break
  fi

  if [ "$elapsed" -ge "$TIMEOUT" ]; then
    log "Timeout waiting for all pods to reach CreateContainerError."
    log "Continuing anyway..."
  fi

  sleep "$INTERVAL"
  ((elapsed+=INTERVAL))
done

log "Deleting DaemonSet after image preload..."
oc delete -f image-preload-vm.yml


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

