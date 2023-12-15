#!/bin/bash

# Stopping kubelet service
echo "Stopping kubelet service..."
sudo systemctl stop kubelet

# Disabling kubelet service
echo "Disabling kubelet service..."
sudo systemctl disable kubelet

# Removing kubelet service files
echo "Removing kubelet service files..."
sudo rm -f /etc/systemd/system/kubelet.service
sudo rm -rf /etc/systemd/system/kubelet.service.d

# Removing kubeadm, kubelet, and kubectl binaries
echo "Removing kubeadm, kubelet, and kubectl binaries..."
sudo rm -f /usr/bin/kubeadm
sudo rm -f /usr/bin/kubelet
sudo rm -f /usr/bin/kubectl  # Remove this line if you didn't install kubectl

# Removing CNI plugin files
echo "Removing CNI plugin files..."
sudo rm -rf /opt/cni/bin

# Removing crictl binary
echo "Removing crictl binary..."
sudo rm -f /usr/bin/crictl

# Resetting kubeadm (optional, only if a cluster was initiated)
read -p "Do you want to reset kubeadm? This will clean up any Kubernetes configuration. (y/N) " yn
case $yn in
    [Yy]* ) sudo kubeadm reset; ;;
    * ) echo "Skipping kubeadm reset."; ;;
esac

# Reloading systemd daemon
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "Kubernetes components removal complete."

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
