#!/bin/bash

log() {
  local message="$1"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $message"
}

# Ensure necessary programs are available
for program in helm oc jq; do
    if ! command -v $program &> /dev/null; then
        log "$program is not installed. You need it."
        exit 1
    fi
done

# Define the OpenShift release version, allowing for an override
OPENSHIFT_RELEASE="${OPENSHIFT_RELEASE:-4.18.0-0.nightly-2024-10-23-112324}"

# Set the URL for the OpenShift installer using the release version
INSTALLER_URL="${INSTALLER_URL:-https://openshift-release-artifacts.apps.ci.l2s4.p1.openshiftapps.com/$OPENSHIFT_RELEASE/openshift-install-linux-$OPENSHIFT_RELEASE.tar.gz}"

# Set the installation directory based on the release version
DOWNLOAD_DIR="openshift-$OPENSHIFT_RELEASE"
INSTALL_DIR="$(pwd)/openshift-$OPENSHIFT_RELEASE/install"

# Check if directory already exists
if [ -d "$DOWNLOAD_DIR" ]; then
    log "Installer directory $DOWNLOAD_DIR already exists, skipping download."
else
    # Download and extract the installer
    wget $INSTALLER_URL
    [ $? -ne 0 ] && echo "Error: wget failed. Did you extract the tools? Try visiting: https://openshift-release-artifacts.apps.ci.l2s4.p1.openshiftapps.com/$OPENSHIFT_RELEASE" && exit 1
    mkdir -p "$DOWNLOAD_DIR"
    mkdir -p "$INSTALL_DIR"
    tar -xf openshift-install-linux-$OPENSHIFT_RELEASE.tar.gz -C "$DOWNLOAD_DIR"
    rm openshift-install-linux-$OPENSHIFT_RELEASE.tar.gz
fi

# Check for required files
for file in pull-secret.txt ssh.pub; do
    if [ ! -f "./$file" ]; then
        log "$file is not present in the working directory."
        exit 1
    fi
done

# Build the cluster name from exported variable or generate it
CLUSTER_NAME="${CLUSTER_NAME:-$(whoami)cnvmetal$(date +%d)}"

# Extract the pull secret and SSH key
PULL_SECRET=$(jq -c . < ./pull-secret.txt)
SSH_KEY=$(cat ssh.pub)

# Create the YAML file
cat > "$INSTALL_DIR/install-config.yaml" <<EOF
---
featureSet: TechPreviewNoUpgrade
additionalTrustBundlePolicy: Proxyonly
apiVersion: v1
baseDomain: devcluster.openshift.com
compute:
- architecture: amd64
  hyperthreading: Enabled
  name: worker
  platform:
    aws:
      type: m5.metal
  replicas: 2
controlPlane:
  architecture: amd64
  hyperthreading: Enabled
  name: master
  platform: {}
  replicas: 3
metadata:
  creationTimestamp: null
  name: $CLUSTER_NAME
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  machineNetwork:
  - cidr: 10.0.0.0/16
  networkType: OVNKubernetes
  serviceNetwork:
  - 172.30.0.0/16
platform:
  aws:
    region: us-west-2
publish: External
pullSecret: '$PULL_SECRET'
sshKey: |
  $SSH_KEY
EOF

# Output the cluster name
log "Generated install-config.yaml for cluster: $CLUSTER_NAME"
