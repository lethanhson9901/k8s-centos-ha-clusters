#!/bin/bash

# Configure /etc/hosts
cat <<EOF >> /etc/hosts
10.16.150.138      k8s-master-1
10.16.150.139      k8s-master-2
10.16.150.140      k8s-master-3
10.16.150.134      k8s-worker-1
10.16.150.135      k8s-worker-2
10.16.150.136      k8s-worker-3
10.16.150.132      k8s-lb-1
10.16.150.133      k8s-lb-2
10.16.150.137      vip
EOF

# Disable SELinux
setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux

# Enable br_netfilter Kernel Module
modprobe br_netfilter
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables

# Disable SWAP
swapoff -a
sed -i '/swap/d' /etc/fstab

# Install Docker CE
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce

# Start and enable Docker service
systemctl start docker && systemctl enable docker

# Install Kubernetes
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

yum install -y kubelet kubeadm kubectl

# Start and enable kubelet service
systemctl start kubelet && systemctl enable kubelet

# Change the cgroup-driver for Kubernetes to match Docker
DOCKER_CGROUP_DRIVER=$(docker info | grep -i "Cgroup Driver" | cut -d' ' -f3)
sed -i "s/cgroup-driver=systemd/cgroup-driver=$DOCKER_CGROUP_DRIVER/g" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

# Reload systemd and restart kubelet
systemctl daemon-reload
systemctl restart kubelet

echo "Kubernetes setup script completed. Please reboot the system."
