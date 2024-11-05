## OCP Commons cheat sheet

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