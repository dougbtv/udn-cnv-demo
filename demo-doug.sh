#!/bin/bash

# traditionally programmers, I confess my sins
# I made these subroutines out of haste.

function run_cmd() {
    echo "# $@"

    eval "$@"
    read
}

function run_fakecmd() {
    echo "# $1"

    eval "$2"
    read
}


# pipe this thing to less, it was wonky to do in here
function run_with_scroll() {
    echo "====================================================================="
    echo "    $1"
    echo "====================================================================="
    echo "# $2"
    echo
    eval "$2" 
}


function header() {
	echo "====================================================================="
	echo "    $@"
	echo "====================================================================="
}

function headeronly() {
	echo "====================================================================="
	echo "    $1"
    echo "    $2"
	echo "====================================================================="
    read
}


# --- Cheats and references
# watch -n1 'oc get pods -o custom-columns="NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName" | awk '\''{printf "%-30s %-10s %-30s\n", substr($1, 1, 25), $2, substr($3, 1, 25)}'\'''
# ip -o -4 addr show dev eth0 | awk '{print $2, $4}'

# --- Actual script.

header "We have a fedora VM running on OpenShift 4.18 nightly"
run_cmd oc get vms

# header "We have that VM running with UDN in network-c"
# run_cmd "oc describe userdefinednetwork network-c | grep -P '^Kind|Subnets|Name|10\.'"
# run_cmd "oc describe userdefinednetwork network-c | awk '/^Name:|^Namespace:|^Kind:|^Role:|^Topology:|Subnets:/,/^Status:/'"


run_with_scroll "We have that VM running with UDN in network-c" "oc describe userdefinednetwork network-c" | less

header "A persistent IP is associated via annotation"
RUNNING_VM=$(oc get pods | grep -i running | grep -i virt | awk '{print $1}')
# k8s.ovn.org/primary-udn-ipamclaim: fedora-vm-a.ovn-kubernetes
run_fakecmd "oc describe pod $RUNNING_VM | grep ..." "oc describe pod $RUNNING_VM | grep -iP '^Name|Annotations|ipam' | sed 's/Annotations: .*/Annotations:/' | perl -p -e 's/\s{9}/  /'"

header "We have a persistent IP address assigned to the VM"
# run_cmd "oc describe ipamclaim fedora-vm-a.ovn-kubernetes | grep -Pi '^Kind|^Name:|^Status:|Ips|10\.'"
run_cmd "oc get ipamclaim -o yaml fedora-vm-a.ovn-kubernetes"

headeronly "We can console into the VM" "And see that IP address in the VM, on lower right"

header "There's also a pod running that we can start a ping from"
run_cmd oc get pods

headeronly "Lets start a ping to the VM IP address" "...in the upper right."

headeronly "Before we migrate, lets watch the pods" "...in the lower right."

header "Lets start a VM live migration on our VM"
run_cmd virtctl migrate fedora-vm-a

headeronly "We see a VM is created on a new host" "The previous instance ends, and our ping continues"
