#!/bin/bash

# Stop and disable kubelet, docker, and containerd services
echo "Stopping and disabling kubelet, docker, and containerd services..."
systemctl stop kubelet docker containerd
systemctl disable kubelet docker containerd

# Uninstall kubeadm, kubelet, kubectl
echo "Uninstalling kubeadm, kubelet, and kubectl..."
yum remove -y kubeadm kubelet kubectl

# Remove Kubernetes configuration directory and files
echo "Removing Kubernetes configuration directories and files..."
rm -rf /etc/kubernetes /root/.kube /etc/sysctl.d/k8s.conf /etc/systemd/system/kubelet.service.d /etc/systemd/system/kubelet.service

# Remove Kubernetes binaries if they were manually installed
echo "Removing manually installed Kubernetes binaries..."
rm -rf /usr/bin/kubeadm /usr/bin/kubelet /usr/bin/kubectl
rm -rf /usr/local/bin/kubeadm /usr/local/bin/kubelet /usr/local/bin/kubectl
# Remove CNI plugins
echo "Removing CNI plugins..."
rm -rf /opt/cni

# Uninstall containerd
echo "Uninstalling containerd..."
yum remove -y containerd.io

# Uninstall Docker
echo "Uninstalling Docker..."
yum remove -y docker-ce docker-ce-cli

# Remove Docker configuration directory
echo "Removing Docker configuration directory..."
rm -rf /etc/docker

# Reset SELinux to enforcing mode
echo "Resetting SELinux to enforcing mode..."
setenforce 1
sed -i 's/^SELINUX=permissive$/SELINUX=enforcing/' /etc/selinux/config

# Re-enable swap
echo "Re-enabling swap..."
sed -i '/\sswap\s/ s/^#//' /etc/fstab
swapon -a

# Reload sysctl to reset networking settings
echo "Reloading sysctl to reset networking settings..."
sysctl --system

# Clean yum cache
echo "Cleaning yum cache..."
yum clean all

echo "Uninstallation and cleanup complete."
