#!/bin/bash

# Stopping kubelet service
echo "Stopping kubelet service..."
systemctl stop kubelet

# Disabling kubelet service
echo "Disabling kubelet service..."
systemctl disable kubelet

# Removing kubelet service files
echo "Removing kubelet service files..."
rm -f /etc/systemd/system/kubelet.service
rm -rf /etc/systemd/system/kubelet.service.d

# Removing kubeadm, kubelet, and kubectl binaries
echo "Removing kubeadm, kubelet, and kubectl binaries..."
rm -f /usr/bin/kubeadm
rm -f /usr/bin/kubelet
rm -f /usr/bin/kubectl  # Remove this line if you didn't install kubectl

# Removing CNI plugin files
echo "Removing CNI plugin files..."
rm -rf /opt/cni/bin

# Removing crictl binary
echo "Removing crictl binary..."
rm -f /usr/bin/crictl

# Resetting kubeadm (optional, only if a cluster was initiated)
read -p "Do you want to reset kubeadm? This will clean up any Kubernetes configuration. (y/N) " yn
case $yn in
    [Yy]* ) kubeadm reset; ;;
    * ) echo "Skipping kubeadm reset."; ;;
esac

# Reloading systemd daemon
echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Kubernetes components removal complete."

# Uninstall Kubernetes components
echo "Uninstalling Kubernetes components..."
yum remove -y kubelet kubeadm kubectl

# Stop and disable Docker
echo "Stopping and disabling Docker..."
systemctl stop docker
systemctl disable docker

# Uninstall Docker
echo "Uninstalling Docker..."
yum remove -y docker-ce docker-ce-cli containerd.io

# Remove Docker and Kubernetes configurations
echo "Removing Docker and Kubernetes configuration files..."
rm -rf /etc/docker
rm -f /etc/yum.repos.d/kubernetes.repo

# Revert sysctl and kernel module settings
echo "Reverting sysctl and kernel module settings..."
rm -f /etc/sysctl.d/k8s.conf
sysctl --system

# Re-enable swap (optional)
echo "Re-enabling swap..."
sed -i '/\sswap\s/ s/^#//' /etc/fstab
swapon -a

# Reset SELinux to enforcing (optional)
echo "Resetting SELinux to enforcing mode..."
setenforce 1
sed -i 's/^SELINUX=permissive$/SELINUX=enforcing/' /etc/selinux/config

echo "Cleanup complete. Please reboot your system."
