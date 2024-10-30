```
To use the cluster-bot images could be something like:
Export release extracted from build.
CUSTOM_RELEASE="registry.build05.ci.openshift.org/ci-ln-4ckd6hk/release:latest"
Option 1) To install a cluster (I believe requires CI creds as the build release in CI registry):
OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE=$CUSTOM_RELEASE ./openshift-install create cluster
Option 2) I believe you can also replace the image for the component/controller setting OLM to unmanaged (I also think it'll require CI pull secrets). Steps to replace (may have more simple way lol):
Update pull secret, log in to the build05 https://console-openshift-console.apps.build05.l9oh.p1.openshiftapps.com/k8s/cluster/projects/ci-ln-4ckd6hk
Merge credentials like instructions in https://mtulio.dev/playbooks/openshift/install-credentials-with-ci/
I am unsure if you need to login in both, but it seems my regular CI credentials can't access your image as it was built by your user, so only your creds may be able to access. You need to run oc adm release info $CUSTOM_RELEASE to validate it. After the procedures my registry config will have access to those registries:
$ jq '.auths | keys' ${PULL_SECRET}
[
  "cloud.openshift.com",
  "quay.io",
  "registry.build05.ci.openshift.org",
  "registry.ci.openshift.org",
  "registry.connect.redhat.com",
  "registry.redhat.io"
]
Get the image build from cluster- bot
oc adm release info $CUSTOM_RELEASE | grep autoscaler
Set to controller deployment to unmanaged: https://mtulio.dev/notes/container/openshift/ocp-cvo/?h=unmanaged#add-unmanaged-services
Option 3) Maybe another option will be BYO image, perhaps this step may help?: https://github.com/openshift/cluster-autoscaler-operator?tab=readme-ov-file#development (edited) 
```


## Cluster bot notes

So! First you can build a release image by commanding cluster-bot to:

```
build 4.18.0-0.nightly-2024-10-29-063750,openshift/ovn-kubernetes#2314
```

Then, you'll get a build results link like this:

* https://prow.ci.openshift.org/view/gs/test-platform-results/logs/release-openshift-origin-installer-launch-aws-modern/1851666497991086080


Go ahead and expand the build log, and look for these kind of lines towards the end of it...

```
INFO[2024-10-30T17:17:46Z] Using namespace https://console-openshift-console.apps.build09.ci.devcluster.openshift.com/k8s/cluster/projects/ci-ln-mqp72vk 
[...snip...]
INFO[2024-10-30T17:20:01Z] Snapshot integration stream into release 4.18.0-0.test-2024-10-30-171747-ci-ln-mqp72vk-latest to tag release:latest  
INFO[2024-10-30T17:20:01Z] Ran for 2m14s                                
```

Now! Make note of the `build09` build server.

And also the release name, especially this part: `ci-ln-mqp72vk` of `4.18.0-0.test-2024-10-30-171747-ci-ln-mqp72vk-latest`

Now, we can substitute those into this pattern:

```
registry.build09.ci.openshift.org/ci-ln-mqp72vk/release:latest
```

With that in hand, you can now:


```
export CUSTOM_RELEASE="registry.build09.ci.openshift.org/ci-ln-mqp72vk/release:latest"
```

And then

```
./01-cluster-create.sh
```

It should have log output.

## **IMPORTANT**: You should make sure you have the login credentials for that buildserver!

You can reference Doug's [chicken scratch quick quick quick](https://gist.github.com/dougbtv/67257f060abdf398f2722f8bc911a289#40-aws-quick-quick-quick) gist.

But mostly, you'll have to login at a URL you build from the "Using namespace: " line in the build log, like:

```
https://console-openshift-console.apps.build09.ci.devcluster.openshift.com/k8s/cluster/projects/ci-ln-mqp72vk 
```

Get the login link from the upper right hand corner, and then...


```
 oc login --token=sha256~xxxxx --server=https://api.build05.l9oh.p1.openshiftapps.com:6443
 oc registry login --to /tmp/some-pull-secret.txt
```

Grab the auth lines out of that and put it into your whole pull secret.


## References

I originally saw something like this...

```
CUSTOM_RELEASE="registry.build09.ci.openshift.org/ci-ln-mqp72vk/release:latest"
OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE=$CUSTOM_RELEASE ./openshift-install create cluster
```

And I built on it.
