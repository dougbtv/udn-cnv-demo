
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
