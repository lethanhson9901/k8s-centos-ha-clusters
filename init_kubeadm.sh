#!/bin/bash

# Default values
DEFAULT_CLUSTER_VIP="10.16.150.140"  # Default cluster VIP
DEFAULT_NODE_IP="10.16.150.138"      # Default node IP
DEFAULT_POD_NETWORK_CIDR="192.168.0.0/16"  # Default pod network CIDR

# Parse command-line arguments
while getopts "c:n:p:h" opt; do
    case $opt in
        c) CLUSTER_VIP="$OPTARG"
        ;;
        n) NODE_IP="$OPTARG"
        ;;
        p) POD_NETWORK_CIDR="$OPTARG"
        ;;
        h) usage
        ;;
    esac
done

# Set defaults if variables are not set
CLUSTER_VIP=${CLUSTER_VIP:-$DEFAULT_CLUSTER_VIP}
NODE_IP=${NODE_IP:-$DEFAULT_NODE_IP}
POD_NETWORK_CIDR=${POD_NETWORK_CIDR:-$DEFAULT_POD_NETWORK_CIDR}

# Constants
CALICO_YAML_URL="https://docs.projectcalico.org/manifests/calico.yaml"
KUBE_CONFIG_DIR="/root/.kube"
KUBE_CONFIG_FILE="/etc/kubernetes/admin.conf"

# Reset the existing Kubernetes cluster
sudo kubeadm reset -f

# Remove .kube directory in the user's home directory
sudo rm -rf ~/.kube

# Remove /etc/kubernetes/manifests and /var/lib/etcd directories
sudo rm -rf /etc/kubernetes/manifests /var/lib/etcd

# Initialize the Kubernetes cluster
sudo kubeadm init --control-plane-endpoint="${CLUSTER_VIP}:6443" --upload-certs --apiserver-advertise-address=${NODE_IP} --pod-network-cidr=${POD_NETWORK_CIDR}

# Download and deploy Calico network
sudo curl -o /root/calico.yaml -L ${CALICO_YAML_URL}
sudo kubectl --kubeconfig=${KUBE_CONFIG_FILE} apply -f /root/calico.yaml

# Create directory for kube config and copy the admin.conf file
sudo mkdir -p ${KUBE_CONFIG_DIR}
sudo chown vagrant:vagrant ${KUBE_CONFIG_DIR}
sudo chmod 0755 ${KUBE_CONFIG_DIR}
sudo cp ${KUBE_CONFIG_FILE} ${KUBE_CONFIG_DIR}/config
sudo chown vagrant:vagrant ${KUBE_CONFIG_DIR}/config
sudo chmod 0644 ${KUBE_CONFIG_DIR}/config

echo "Kubernetes cluster initialization complete."
