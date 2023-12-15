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

# Add Kubernetes repository
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.28/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

# Install Kubernetes components
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

# Enable and start kubelet
sudo systemctl enable --now kubelet

# Load br_netfilter module and apply sysctl settings for Kubernetes networking
sudo modprobe br_netfilter
sudo sysctl -w net.bridge.bridge-nf-call-iptables=1
sudo sysctl -w net.ipv4.ip_forward=1

echo "Setup complete."