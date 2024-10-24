# udn-cnv-demo

Spins up an environment for a demo using CNV/kubevirt on openshift with OVN-K UDN (user defined networks)

The goal of the demo environment is to have an environment which has both UDN available, and a VM which can be live migrated.

## Requirements

* An AWS account for openshift devcluster* (you have a ~/.aws/ dir with creds)
* You have pull secrets for...
  * `quay.io/openshift-cnv`
  * `registry.ci.openshift.org` (and build repos, e.g. `registry.build01...`, `registry.build05...`)

*...It could be potentially useful in parts without an AWS cluster spin up.

## Usage

If by some miracle all your requirements are met, you can just run:

```
./00-all.sh
```

Which runs the following scripts, which you may opt to run one-by-one (especially the first time you use the scripts).

### `01-cluster-create.sh`

Creates an openshift cluster on AWS w/ baremetal workers.

If you want customized by exporting these variables:

- `OPENSHIFT_RELEASE`: Specifies the OpenShift release version. Default is `4.18.0-0.nightly-2024-10-23-112324`.
- `CLUSTER_NAME`: Name of the cluster to be used in the install configuration. If not set, it defaults to a combination of the current username, `cnvmetal`, and the day of the month.
- `PULL_SECRET_PATH`: Path to the pull secret file. Default is `pull-secret.txt`.
- `PUBKEY_PATH`: Path to the SSH public key file. Default is `ssh.pub`.

You can find a log of the install in the downloaded directory based on the release version in the project root, like `./openshift-$OPENSHIFT_RELEASE/install.log`, which includes your login creds.

This will export `KUBECONFIG=./openshift-$OPENSHIFT_RELEASE/install/auth/kubeconfig`

### `02-cnv-setup.sh`

Installs the latest CNV.

- `CNV_VERSION`: Default is `4.99`

Feel free to watch the installation with:

```
watch -n2 oc get pods -n openshift-cnv
```

### `03-storage-setup.sh`

Creates an NFS storage scheme to provide RWX PVCs to support Kubevirt migration.

Create a Fedora 40 image, using that storage, to run VMs from.

These assets run in a namespace called `demo` (which this also creates).

No configurable options.

### `04-launch-vm.sh`

Creates a UDN CR and launches a Fedora VM.


### Validation

You can then [use virtctl](https://kubevirt.io/user-guide/user_workloads/virtctl_client_tool/) to access your vm:

```
virtctl console fedora-vm 
```

(login with: `fedora`/`fedora`)

And you can inspect the UDN networks with:

```
oc get pods
oc get pod virt-launcher-fedora-vm-xyz -o jsonpath="{.metadata.annotations['k8s\.ovn\.org/pod-networks']}"
```

