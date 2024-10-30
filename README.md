# udn-cnv-demo

Spins up an environment for a demo using CNV/kubevirt on openshift with OVN-K UDN (user defined networks)

The goal of the demo environment is to have an environment which has both UDN available, and a VM which can be live migrated.

## Requirements

* An AWS account for openshift-dev (you have a ~/.aws/ dir with creds)
  * In my experience you must also have `awscli` installed (via dnf, maybe) and have ran `aws configure`
* You have pull secrets for...
  * `quay.io/openshift-cnv`
  * `registry.ci.openshift.org` (and build repos, e.g. `registry.build01...`, `registry.build05...`)
* `oc`, `jq`, and `virtctl` are installed
  * If you want, try the `99-install-virtctl.sh` to install virtctl

*...It could be potentially useful in parts without an AWS cluster spin up.

## Usage

If by some miracle all your requirements are met, you can just run:

```
./00-all.sh
```

Which runs the following scripts, which you may opt to run one-by-one (especially the first time you use the scripts).

### `01-cluster-create.sh`

Creates an openshift cluster on AWS w/ baremetal workers.

If you want to customize, `export` any of the following variables:

- `OPENSHIFT_RELEASE`: Specifies the OpenShift release version. Default is `4.18.0-0.nightly-2024-10-23-112324`.
- `CLUSTER_NAME`: Name of the cluster to be used in the install configuration. If not set, it defaults to a combination of the current username, `cnvmetal`, and the day of the month.
- `PULL_SECRET_PATH`: Path to the pull secret file. Default is `pull-secret.txt`.
- `PUBKEY_PATH`: Path to the SSH public key file. Default is `ssh.pub`.
- `AWS_REGION`: Which [AWS region](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.RegionsAndAvailabilityZones.html) will be used, default is `us-west-2`.
- `CUSTOM_RELEASE`: A custom release image (e.g. from cluster bot), for example a value like: `registry.build09.ci.openshift.org/ci-ln-mqp72vk/release:latest`, is used only if set, set to empty to not use.
    - See additional notes in [cluster-bot-notes.md](cluster-bot-notes.md)

You can find a log of the install in the downloaded directory based on the release version in the project root, like `./openshift-$OPENSHIFT_RELEASE/install.log`, which includes your login creds.

This will export `KUBECONFIG=./openshift-$OPENSHIFT_RELEASE/install/auth/kubeconfig`

### `02-cnv-setup.sh`

Installs the latest CNV. You can `export`:

- `CNV_VERSION`: Default is `4.99`

Feel free to watch the installation with:

```
watch -n2 oc get pods -n openshift-cnv
```

### `03-storage-setup.sh`

**STATUS: Currently optional** (for now, it might improve perf later? I'll try later.)

Creates an NFS storage scheme to provide RWX PVCs to support Kubevirt migration.

Create a Fedora 40 image, using that storage, to run VMs from.

These assets run in a namespace called `demo` (which this also creates).

No configurable options.

### `04-launch-vm.sh`

Creates a UDN CR and launches a Fedora VM.

These run in the `poc1` namespace, for now.

Notes...

```
oc get ipamclaim -oyaml
```

shows if the ipamclaims have the persistent IPs.

## Validation

You can then [use virtctl](https://kubevirt.io/user-guide/user_workloads/virtctl_client_tool/) to access your vm:

```
virtctl console vmi-fedora-a
```

(login with: `fedora`/`fedora`)

And you can inspect the UDN networks with:

```
oc get pods
oc get pod virt-launcher-vmi-fedora-a-fwt5v -o jsonpath="{.metadata.annotations['k8s\.ovn\.org/pod-networks']}"
```

You can migrate the pod using the openshift console.

First, using the administrator view, browse to:

```
Virtualization -> VirtualMachines -> [select fedora-vm] -> Diagnostics [tab] -> Diagnostics
```

And validate that the `LiveMigratable` property's status is `True` (there's probably a way to this from the CLI, too)

Then you can kick off the migration with...

```
virtctl migrate vmi-fedora-a
```

And then `oc get pods -o wide` to see that it's happened.

I also have a `samplepod` named pod running, I will ping the persistent IP on vmi-fedora-a while it's running.

## Cleaning up your mess...

To delete a cluster, you can do it manually like:

```
cd openshift-4.18.0-0.nightly-2024-10-23-112324/
./openshift-install destroy cluster --dir "$(pwd)/install"
```
