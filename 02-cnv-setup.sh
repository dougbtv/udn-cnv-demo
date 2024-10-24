#!/bin/bash

CNV_VERSION="${CNV_VERSION:-4.99}"
# QUAY_AUTH="BAD"
# QUAY_AUTH_JSON=$(jq -n --arg auth "$QUAY_AUTH" '{"quay.io/openshift-cnv":{"auth":$auth}}')

log() {
  local message="$1"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $message"
}

# -------------------------------------------------------------------------------- 
# I put the pull secret for it in my overall pull secret.
# --------------------------------------------------------------------------------

# # Get the global pull secret and decode it
# oc get secret pull-secret -n openshift-config -o json | \
#     jq -r '.data.".dockerconfigjson"' | base64 -d > global-pull-secret.json

# # Update the pull secret with the new quay.io entry
# jq --argjson QUAY_AUTH_JSON "$QUAY_AUTH_JSON" '.auths += $QUAY_AUTH_JSON' \
#     global-pull-secret.json > global-pull-secret.json.tmp

# # Replace the original pull secret with the updated one
# mv global-pull-secret.json.tmp global-pull-secret.json

# log "Updating openshift pull secret (and waiting 5 seconds)..."

# oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=global-pull-secret.json

# rm global-pull-secret.json

# sleep 5

log "Waiting for mcp master worker..."

oc wait mcp master worker --for condition=updated --timeout=20m

log "Adding catalogue source"

cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: cnv-nightly-catalog-source
  namespace: openshift-marketplace
spec:
  sourceType: grpc
  image: quay.io/openshift-cnv/nightly-catalog:latest
  displayName: OpenShift Virtualization Nightly Index
  publisher: Red Hat
  updateStrategy:
    registryPoll:
      interval: 8h
EOF

oc get packagemanifest -l "catalog=cnv-nightly-catalog-source"

STARTING_CSV=$(oc get packagemanifest -l "catalog=cnv-nightly-catalog-source" -o jsonpath="{$.items[?(@.metadata.name=='kubevirt-hyperconverged')].status.channels[?(@.name==\"nightly-${CNV_VERSION}\")].currentCSV}")

cat <<EOF | oc apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: openshift-cnv
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: kubevirt-hyperconverged-group
  namespace: openshift-cnv
spec:
  targetNamespaces:
  - openshift-cnv
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: hco-operatorhub
  namespace: openshift-cnv
spec:
  source: cnv-nightly-catalog-source
  sourceNamespace: openshift-marketplace
  name: kubevirt-hyperconverged
  startingCSV: ${STARTING_CSV}
  channel: "nightly-${CNV_VERSION}"
EOF

log "Waiting 40 minutes for HyperConverged in api-resources"

# Timeout in seconds (40 minutes * 60 seconds/minute)
timeout=2400
start_time=$(date +%s)

while ! oc api-resources | grep -q HyperConverged; do
    current_time=$(date +%s)
    elapsed_time=$((current_time - start_time))

    if [ "$elapsed_time" -ge "$timeout" ]; then
        log "ERROR: Timeout reached: HyperConverged resource not found after 40 minutes."
        exit 1
    fi

    sleep 2
done

cat <<EOF | oc apply -f -
apiVersion: hco.kubevirt.io/v1beta1
kind: HyperConverged
metadata:
  name: kubevirt-hyperconverged
  namespace: openshift-cnv
spec: 
  featureGates:
    primaryUserDefinedNetworkBinding: true
    deployKubevirtIpamController: true
EOF

log "Waiting 30 minutes for hyperconverged"

oc wait HyperConverged kubevirt-hyperconverged -n openshift-cnv --for condition=Available --timeout=30m