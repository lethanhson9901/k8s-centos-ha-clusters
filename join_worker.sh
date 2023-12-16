#!/bin/bash

# Function to display usage instructions
usage() {
    echo "Usage: $0 -i <node_ip>"
    echo "  -i <node_ip>: The IP address of this node."
    echo "Example: $0 -i 192.168.1.100"
    exit 1
}

# Parse command-line arguments
while getopts "i:" opt; do
    case $opt in
        i) NODE_IP="$OPTARG"
        ;;
        *) usage
        ;;
    esac
done

# Check if NODE_IP is set
if [ -z "${NODE_IP}" ]; then
    echo "Error: Node IP is not provided."
    usage
fi

# Reset the existing Kubernetes cluster
sudo kubeadm reset -f

# Remove .kube directory in the user's home directory
rm -rf ~/.kube

# Remove /etc/kubernetes/manifests directory
sudo rm -rf /etc/kubernetes/manifests

# Copy join command to workers (Assuming the join command is already present at this location)
sudo cp /tmp/kubernetes_join_command /tmp/kubernetes_join_command
sudo chmod 0777 /tmp/kubernetes_join_command

# Execute worker join command
sudo sh /tmp/kubernetes_join_command

# Edit kubeadm.conf
sudo sed -i '/\[Service\]/a Environment="KUBELET_EXTRA_ARGS=--node-ip=${NODE_IP}"' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

# Restart kubelet service
sudo systemctl daemon-reload
sudo systemctl restart kubelet

echo "Worker node joined to the Kubernetes cluster."
