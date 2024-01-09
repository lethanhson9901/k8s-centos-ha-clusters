#!/bin/bash

# Function to display usage instructions
usage() {
    echo "Usage: $0 -i <NODE_IP>"
    echo "  -i <NODE_IP>: The IP address of this master node."
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

# Reset the existing Kubernetes cluster configuration
sudo kubeadm reset -f

# Remove .kube directory in the user's home directory
rm -rf ~/.kube

# Remove /etc/kubernetes/manifests directory
sudo rm -rf /etc/kubernetes/manifests

# Execute worker join command with certificate key
join_command=$(cat /tmp/kubernetes_join_command)
certificate_key=$(cat /tmp/kubernetes_certificate_key)
sudo $join_command --control-plane --certificate-key $certificate_key --apiserver-advertise-address=${NODE_IP}

# Edit kubeadm.conf
sudo sed -i "/\[Service\]/a Environment=\"KUBELET_EXTRA_ARGS=--node-ip=${NODE_IP}\"" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

# Restart kubelet service
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Create directory for kube config
mkdir -p /root/.kube
chmod 0755 /root/.kube

# Copy /etc/kubernetes/admin.conf to the root user's home directory
cp /etc/kubernetes/admin.conf /root/.kube/config
chmod 0644 /root/.kube/config

echo "Kube config setup for root user complete."

echo "Master node joined to the Kubernetes cluster."
