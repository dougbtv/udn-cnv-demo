#!/bin/bash

log() {
  local message="$1"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $message"
}

get_kubevirt_release_url() {
    local VERSION="$1"

    local kubevirt_version
    local kubevirt_release_url

    if [[ "$VERSION" == "stable" ]]; then
        kubevirt_version=$(curl -sL https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)
        kubevirt_release_url="https://github.com/kubevirt/kubevirt/releases/download/${kubevirt_version}"
    elif [[ "$VERSION" == v* ]]; then
        kubevirt_version="$VERSION"
        kubevirt_release_url="https://github.com/kubevirt/kubevirt/releases/download/${kubevirt_version}"
    elif [[ "$VERSION" == "nightly" ]]; then
        kubevirt_version=$(curl -sL https://storage.googleapis.com/kubevirt-prow/devel/nightly/release/kubevirt/kubevirt/latest)
        kubevirt_release_url="https://storage.googleapis.com/kubevirt-prow/devel/nightly/release/kubevirt/kubevirt/${kubevirt_version}"
    elif [[ "$VERSION" =~ ^[0-9]{8}$ ]]; then
        kubevirt_version="$VERSION"
        kubevirt_release_url="https://storage.googleapis.com/kubevirt-prow/devel/nightly/release/kubevirt/kubevirt/${kubevirt_version}"
    else
        echo "Unsupported KUBEVIRT_VERSION value $VERSION (use either stable, vX.Y.Z, nightly or nightly tag)"
        exit 1
    fi

    echo "$kubevirt_release_url"
}

kubevirt_release_url=$(get_kubevirt_release_url nightly)
log "Using kubevirt URL: $kubevirt_release_url"

log "Applying Kubevirt operator yaml"
oc apply -f "${kubevirt_release_url}/kubevirt-operator.yaml"
oc apply -f "${kubevirt_release_url}/kubevirt-cr.yaml"
oc -n kubevirt patch kubevirt kubevirt --type=merge --patch '{"spec":{"configuration":{"virtualMachineOptions":{"disableSerialConsoleLog":{}}}}}'
log "Waiting up to 15 minutes for Kubevirt to be available"
oc wait -n kubevirt kv kubevirt --for condition=Available --timeout 15m
oc -n kubevirt patch kubevirt kubevirt --type=json --patch '[{"op":"add","path":"/spec/configuration/developerConfiguration","value":{"featureGates":[]}},{"op":"add","path":"/spec/configuration/developerConfiguration/featureGates/-","value":"NetworkBindingPlugins"},{"op":"add","path":"/spec/configuration/developerConfiguration/featureGates/-","value":"DynamicPodInterfaceNaming"}]'
kubevirt_stable_release_url=$(get_kubevirt_release_url "stable")
passt_binding_image="quay.io/kubevirt/network-passt-binding:${kubevirt_stable_release_url##*/}"
oc -n kubevirt patch kubevirt kubevirt --type=json --patch '[{"op":"add","path":"/spec/configuration/network","value":{}},{"op":"add","path":"/spec/configuration/network/binding","value":{"passt":{"computeResourceOverhead":{"requests":{"memory":"500Mi"}},"migration":{"method":"link-refresh"},"networkAttachmentDefinition":"default/primary-udn-kubevirt-binding","sidecarImage":"'"${passt_binding_image}"'"},"managedTap":{"domainAttachmentType":"managedTap","migration":{}}}}]'


log "Installing ipam extensions yaml"
manifest="https://raw.githubusercontent.com/kubevirt/ipam-extensions/main/dist/install.yaml"
oc apply -f "$manifest"
log "Waiting 2 minutes for kubevirt ipam controller to be ready"
oc wait -n kubevirt-ipam-controller-system deployment kubevirt-ipam-controller-manager --for condition=Available --timeout 2m

#!/bin/bash -xe
oc patch kubevirts -n kubevirt kubevirt --type=json -p="[{\"op\": \"add\", \"path\": \"/spec/configuration/network\",   \"value\": {
      \"binding\": {
          \"managedTap\": {
              \"domainAttachmentType\": \"managedTap\",
              \"migration\": {},
          }
      }
  }}]"

oc apply -f - <<EOF
---
apiVersion: kubevirt.io/v1
kind: KubeVirt
metadata:
  name: kubevirt
  namespace: kubevirt
spec:
  configuration:
    developerConfiguration:
      featureGates:
        - NetworkBindingPlugins
---
apiVersion: v1
kind: Namespace
metadata:
  name: poc1
---
apiVersion: k8s.cni.cncf.io/v1                                                  
kind: NetworkAttachmentDefinition                                               
metadata:                                                                       
  namespace: poc1
  name: l2
spec:                                                                           
  config: |2                                                                    
    {                                                                           
            "cniVersion": "0.3.0",                                              
            "name": "l2-network",                                               
            "type": "ovn-k8s-cni-overlay",                                      
            "topology":"layer2",                                                
            "subnets": "10.100.200.0/24,2014:100:200::0/60",                                       
            "netAttachDefName": "poc1/l2",                               
            "allowPersistentIPs": true,
            "role": "primary"
    }
---
apiVersion: v1
kind: Service
metadata:
  namespace: poc1
  name: vmi-fedora-a-iperf3
spec:
  type: NodePort
  ipFamilyPolicy: PreferDualStack
  selector:
    vm.kubevirt.io/name: vmi-fedora-a
  ports:
    - protocol: TCP
      port: 5201
---
apiVersion: v1
kind: Service
metadata:
  namespace: poc1
  name: vmi-fedora-b-iperf3
spec:
  type: NodePort
  ipFamilyPolicy: PreferDualStack
  selector:
    vm.kubevirt.io/name: vmi-fedora-b
  ports:
    - protocol: TCP
      port: 5201
---
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  labels:
    special: vmi-fedora-a
  namespace: poc1
  name: vmi-fedora-a
spec:
  running: true
  template:
    spec:
      domain:
        devices:
          disks:
          - disk:
              bus: virtio
            name: containerdisk
          - disk:
              bus: virtio
            name: cloudinitdisk
          interfaces:
          - name: ovn-kubernetes
            binding:
              name: managedTap
          rng: {}
        resources:
          requests:
            memory: 1024M
      networks:
      - name: ovn-kubernetes
        pod: {}
      terminationGracePeriodSeconds: 0
      volumes:
      - containerDisk:
          image: quay.io/ellorent/fedora-with-test-tooling:tcpdump
        name: containerdisk
      - cloudInitNoCloud:
          userData: |-
            #cloud-config
            password: fedora
            chpasswd: { expire: False }
          networkData: |-
            version: 2
            ethernets:
              eth0:
                dhcp4: true
                dhcp6: true
                ipv6-address-generation: eui64
        name: cloudinitdisk
---
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  labels:
    special: vmi-fedora-b
  namespace: poc1
  name: vmi-fedora-b
spec:
  running: true
  template:
    spec:
      domain:
        devices:
          disks:
          - disk:
              bus: virtio
            name: containerdisk
          - disk:
              bus: virtio
            name: cloudinitdisk
          interfaces:
          - name: pod
            binding:
              name: managedTap
          rng: {}
        resources:
          requests:
            memory: 1024M
      networks:
      - name: pod
        pod: {}
      terminationGracePeriodSeconds: 0
      volumes:
      - containerDisk:
          image: quay.io/ellorent/fedora-with-test-tooling:tcpdump
        name: containerdisk
      - cloudInitNoCloud:
          userData: |-
            #cloud-config
            password: fedora
            chpasswd: { expire: False }
          networkData: |-
            version: 2
            ethernets:
              eth0:
                dhcp4: true
                dhcp6: true
                ipv6-address-generation: eui64
        name: cloudinitdisk
EOF