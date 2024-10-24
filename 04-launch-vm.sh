#!/bin/bash

# Function to log messages with a timestamp
log() {
  local message="$1"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $message"
}

log "Creating UDN CR and VM..."

oc apply -f udn.yml

oc create -f vm.yml

log "You can console to your vm with:"
log "virtctl console fedora-vm"
log "(login with: fedora/fedora)"

# oc get pod virt-launcher-fedora-vm-sz7tr -o jsonpath="{.metadata.annotations['k8s\.ovn\.org/pod-networks']}"

