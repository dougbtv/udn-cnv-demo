## OCP Commons cheat sheet

# First let's look at the VM
# Show network-status annotation
# Show primary-udn-ipamclaim
oc describe pod virt-launcher-fedora-vm-a | less

# Then pull up the ipamclaim
oc get ipamclaims
oc describe ipamclaim fedora-vm-a.ovn-kubernetes

# And show that it's reachable
oc exec -it pingpod -- ping -c5 10.0.0.7

# Console into the VM
virtctl console fedora-vm-a

# Start iperf server
iperf3 -s -p 5201

# Get the server IP
./fancy-get-pods.sh

# edit the iperf client pod and create it
vi pod-iperf.yml
oc create -f pod-iperf.yml

# And then tail the logs.
kubectl logs -f iperf3-client -n namespace-c

# In another tab, etc...
watch -n2 ./fancy-get-pods.sh

# And start the migration
virtctl migrate fedora-vm-a