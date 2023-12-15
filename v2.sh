#!/bin/bash

# Update all packages
sudo yum update -y

# Disable swap
swapoff -a
sed -i '/\sswap\s/ s/^/#/' /etc/fstab

# Set SELinux in permissive mode
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Load br_netfilter at boot
echo "br_netfilter" | sudo tee /etc/modules-load.d/k8s.conf

# Set sysctl settings for Kubernetes networking
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

# Apply sysctl settings without reboot
sudo sysctl --system

# Install yum-utils and add Docker repository
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install containerd.io -y
yum install -y docker-ce docker-ce-cli

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Create Docker configuration directory and set permissions
mkdir -p /etc/docker
sudo chmod 0755 /etc/docker
sudo chown root:root /etc/docker

# Configure Docker daemon
cat <<EOF > /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

sudo chmod 0644 /etc/docker/daemon.json
sudo chown root:root /etc/docker/daemon.json

# Reload and restart Docker
sudo systemctl daemon-reload
sudo systemctl restart docker

# Enable and restart containerd
sudo systemctl enable containerd
sudo systemctl restart containerd

# Install CNI plugins (required for most pod networks)
CNI_PLUGINS_VERSION="v1.3.0"
ARCH="amd64"
DEST="/opt/cni/bin"
sudo mkdir -p "$DEST"
curl -L "https://github.com/containernetworking/plugins/releases/download/${CNI_PLUGINS_VERSION}/cni-plugins-linux-${ARCH}-${CNI_PLUGINS_VERSION}.tgz" | sudo tar -C "$DEST" -xz

# Define the directory to download command files
DOWNLOAD_DIR="/usr/local/bin"
sudo mkdir -p "$DOWNLOAD_DIR"

# Install crictl (required for kubeadm / Kubelet Container Runtime Interface (CRI)):
CRICTL_VERSION="v1.28.0"
ARCH="amd64"
curl -L "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz" | sudo tar -C $DOWNLOAD_DIR -xz

# Install kubeadm, kubelet, kubectl (Version 1.28):
RELEASE="v1.28.0"
ARCH="amd64"
cd $DOWNLOAD_DIR
sudo curl -L --remote-name-all https://dl.k8s.io/release/${RELEASE}/bin/linux/${ARCH}/{kubeadm,kubelet,kubectl}
sudo chmod +x {kubeadm,kubelet,kubectl}

# Install and Configure kubelet systemd service
RELEASE_VERSION="v0.16.2"
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/krel/templates/latest/kubelet/kubelet.service" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | sudo tee /etc/systemd/system/kubelet.service
sudo mkdir -p /etc/systemd/system/kubelet.service.d
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/krel/templates/latest/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | sudo tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

# Enable and start kubelet
sudo systemctl enable --now kubelet

# Load br_netfilter module and apply sysctl settings for Kubernetes networking
sudo modprobe br_netfilter
sudo sysctl -w net.bridge.bridge-nf-call-iptables=1
sudo sysctl -w net.ipv4.ip_forward=1

echo "Setup complete."
