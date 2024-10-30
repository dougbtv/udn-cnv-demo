#!/bin/bash

# Function to log messages with a timestamp
log() {
  local message="$1"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $message"
}

oc apply -f udn.yml

oc create -f vm-miguel.yml

# log "Creating UDN CR and VM..."
# oc project demo
# oc create -f vm.yml

log "You can console to your vm with:"
log "virtctl console vm-a"
log "(login with: fedora/fedora)"

# oc get pod virt-launcher-fedora-vm-sz7tr -o jsonpath="{.metadata.annotations['k8s\.ovn\.org/pod-networks']}"

