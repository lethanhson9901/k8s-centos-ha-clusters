#!/bin/bash

# Update all packages
yum update -y

# Disable swap
swapoff -a
sed -i '/\sswap\s/ s/^/#/' /etc/fstab

# Set SELinux in permissive mode
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Load br_netfilter at boot
echo "br_netfilter" | tee /etc/modules-load.d/k8s.conf

# Set sysctl settings for Kubernetes networking
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

# Apply sysctl settings without reboot
sysctl --system

# Install yum-utils and add Docker repository
yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install containerd.io -y
yum install -y docker-ce docker-ce-cli

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Create Docker configuration directory and set permissions
mkdir -p /etc/docker
chmod 0755 /etc/docker
chown root:root /etc/docker

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

chmod 0644 /etc/docker/daemon.json
chown root:root /etc/docker/daemon.json

# Reload and restart Docker
systemctl daemon-reload
systemctl restart docker


# Define Containerd config path
containerd_config_path="/etc/containerd/config.toml"

# Remove existing Containerd config file
if [ -f "$containerd_config_path" ]; then
    echo "Removing existing Containerd config file..."
    rm "$containerd_config_path"
fi

# Create default Containerd config file
echo "Creating default Containerd config file..."
containerd config default > "$containerd_config_path"

# Set SystemdCgroup to true in Containerd config
echo "Setting SystemdCgroup to true in Containerd config..."
sed -i '/^SystemdCgroup = false/c\SystemdCgroup = true' "$containerd_config_path"

echo "Configuration complete."

# Enable and restart containerd
systemctl enable containerd
systemctl restart containerd

#!/bin/bash

# Check Required Ports
# Note: Update the port numbers based on your requirement
echo "Checking required ports..."
nc -zv 127.0.0.1 6443
# Add additional port checks as needed

# Install Container Runtime
# Note: Choose one of the container runtimes (containerd, CRI-O, or Docker Engine with cri-dockerd)
echo "Installing container runtime..."
# Example for containerd (uncomment to use)
# apt-get install -y containerd

# Install CNI Plugins
echo "Installing CNI plugins..."
CNI_PLUGINS_VERSION="v1.3.0"
ARCH="amd64"
DEST="/opt/cni/bin"
mkdir -p "$DEST"
curl -L "https://github.com/containernetworking/plugins/releases/download/${CNI_PLUGINS_VERSION}/cni-plugins-linux-${ARCH}-${CNI_PLUGINS_VERSION}.tgz" | tar -C "$DEST" -xz

# Set Download Directory
DOWNLOAD_DIR="/usr/local/bin"
mkdir -p "$DOWNLOAD_DIR"

# Install crictl
echo "Installing crictl..."
CRICTL_VERSION="v1.28.0"
curl -L "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz" | tar -C $DOWNLOAD_DIR -xz

# Install kubeadm, kubelet, kubectl
echo "Installing kubeadm, kubelet, and kubectl..."
RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"
cd $DOWNLOAD_DIR
curl -L --remote-name-all https://dl.k8s.io/release/${RELEASE}/bin/linux/${ARCH}/{kubeadm,kubelet,kubectl}
chmod +x {kubeadm,kubelet,kubectl}

# Setup kubelet systemd service
RELEASE_VERSION="v0.16.2"
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/krel/templates/latest/kubelet/kubelet.service" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | tee /etc/systemd/system/kubelet.service
mkdir -p /etc/systemd/system/kubelet.service.d
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/krel/templates/latest/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

# Enable and start kubelet
systemctl enable --now kubelet

# Configuring a cgroup driver
# Note: Ensure that the container runtime and kubelet cgroup drivers match.
# This part of the script might need to be adjusted based on the specific runtime and system configuration.
echo "Configuring cgroup driver..."
# Example configurations can be added here

echo "Kubernetes installation script execution completed."


# Load br_netfilter module and apply sysctl settings for Kubernetes networking
modprobe br_netfilter
sysctl -w net.bridge.bridge-nf-call-iptables=1
sysctl -w net.ipv4.ip_forward=1

echo "Setup complete."
