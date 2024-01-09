#!/bin/bash

# Constants
CONFIG_FILE="config/cluster_config.yml"
CALICO_YAML_URL="https://docs.projectcalico.org/manifests/calico.yaml"
KUBE_CONFIG_DIR="/root/.kube"
KUBE_CONFIG_FILE="/etc/kubernetes/admin.conf"

# Function to read YAML configuration
read_config() {
    local key=$1
    local default_value=$2
    yq e ".$key // \"$default_value\"" "$CONFIG_FILE"
}

# Read configuration values
CLUSTER_VIP=$(read_config "cluster_vip" "10.16.150.140")
NODE_IP=$(read_config "node_ip" "10.16.150.138")
POD_NETWORK_CIDR=$(read_config "pod_network_cidr" "192.168.0.0/16")

# Reset the existing Kubernetes cluster
kubeadm reset -f

# Remove .kube directory in the user's home directory
rm -rf ~/.kube

# Remove /etc/kubernetes/manifests and /var/lib/etcd directories
rm -rf /etc/kubernetes/manifests /var/lib/etcd

# Initialize the Kubernetes cluster
kubeadm init --control-plane-endpoint="${CLUSTER_VIP}:6443" --upload-certs --apiserver-advertise-address=${NODE_IP} --pod-network-cidr=${POD_NETWORK_CIDR}  --v=5
echo "kubeadm init --control-plane-endpoint=\"${CLUSTER_VIP}:6443\" --upload-certs --apiserver-advertise-address=${NODE_IP} --pod-network-cidr=${POD_NETWORK_CIDR} --v=5"

# Download and deploy Calico network
curl -o /root/calico.yaml -L ${CALICO_YAML_URL}
kubectl --kubeconfig=${KUBE_CONFIG_FILE} apply -f /root/calico.yaml

# Create directory for kube config and copy the admin.conf file
mkdir -p ${KUBE_CONFIG_DIR}
chown vagrant:vagrant ${KUBE_CONFIG_DIR}
chmod 0755 ${KUBE_CONFIG_DIR}
cp ${KUBE_CONFIG_FILE} ${KUBE_CONFIG_DIR}/config
# chown vagrant:vagrant ${KUBE_CONFIG_DIR}/config
chmod 0644 ${KUBE_CONFIG_DIR}/config

echo "Kubernetes cluster initialization complete."
