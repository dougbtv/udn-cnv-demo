#!/bin/bash

> all.log
OPENSHIFT_RELEASE="${OPENSHIFT_RELEASE:-4.18.0-0.nightly-2024-10-23-112324}"
export KUBECONFIG="$(pwd)/openshift-$OPENSHIFT_RELEASE/install/auth/kubeconfig"
./01-cluster-create.sh && \
  ./02-cnv-setup.sh && \
  ./04-launch-vm.sh | tee -a all.log
#  ./03-storage-setup.sh | tee -a all.log
