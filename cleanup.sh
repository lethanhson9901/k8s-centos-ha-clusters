#!/bin/bash

# Stop and disable Kubernetes services
echo "Stopping and disabling Kubernetes services..."
sudo systemctl stop kubelet
sudo systemctl disable kubelet

# Uninstall Kubernetes components
echo "Uninstalling Kubernetes components..."
sudo yum remove -y kubelet kubeadm kubectl

# Stop and disable Docker
echo "Stopping and disabling Docker..."
sudo systemctl stop docker
sudo systemctl disable docker

# Uninstall Docker
echo "Uninstalling Docker..."
sudo yum remove -y docker-ce docker-ce-cli containerd.io

# Remove Docker and Kubernetes configurations
echo "Removing Docker and Kubernetes configuration files..."
sudo rm -rf /etc/docker
sudo rm -f /etc/yum.repos.d/kubernetes.repo

# Revert sysctl and kernel module settings
echo "Reverting sysctl and kernel module settings..."
sudo rm -f /etc/sysctl.d/k8s.conf
sudo sysctl --system

# Re-enable swap (optional)
echo "Re-enabling swap..."
sudo sed -i '/\sswap\s/ s/^#//' /etc/fstab
sudo swapon -a

# Reset SELinux to enforcing (optional)
echo "Resetting SELinux to enforcing mode..."
sudo setenforce 1
sudo sed -i 's/^SELINUX=permissive$/SELINUX=enforcing/' /etc/selinux/config

echo "Cleanup complete. Please reboot your system."
