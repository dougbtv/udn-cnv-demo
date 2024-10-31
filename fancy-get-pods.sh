#!/bin/bash

# Header
printf "%-25s %-10s %-10s %-17s\n" "NAME" "IP" "STATUS" "NODE"

# Get all pod data in a single JSON call
pods_json=$(oc get pods -o json)

# Loop through each pod
echo "$pods_json" | jq -c '.items[]' | while read -r pod; do
    # Extract metadata from each pod JSON object
    name=$(echo "$pod" | jq -r '.metadata.name' | cut -c1-25)
    node=$(echo "$pod" | jq -r '.spec.nodeName' | cut -c1-17)
    status=$(echo "$pod" | jq -r '.status.phase')

    # Extract the IP from network-status annotation
    network_status=$(echo "$pod" | jq -r '.metadata.annotations."k8s.v1.cni.cncf.io/network-status"')
    ip=$(echo "$network_status" | jq -r '.[] | select(.interface == "ovn-udn1") | .ips[0]')

    # Print out each pod's info in a formatted table
    printf "%-25s %-10s %-10s %-17s\n" "$name" "$ip" "$status" "$node"
done
