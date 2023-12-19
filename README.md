# Setting Up a Multi-Master Kubernetes Cluster with Kubeadm on CentOS

## Introduction
This guide details the process for setting up a high-availability Kubernetes cluster using Kubeadm on CentOS servers. It is adapted from [Setup a multi-master Kubernetes cluster with kubeadm](https://github.com/tranductrinh/k8s/blob/main/create-ha-cluster/README.md) but tailored for CentOS servers and assumes root user access.

## Cluster Configuration
- **Masters**: 3 nodes, each with 2 CPUs and 2 GB RAM
- **Workers**: 3 nodes, each with 2 CPUs and 2 GB RAM
- **Load Balancers**: 2 nodes, each with 1 CPU and 1 GB RAM

![Cluster Setup Diagram](setup.png "Cluster Setup Diagram")

## Getting Started
1. Clone the repository:
   ```bash
   git clone https://github.com/lethanhson9901/k8s-centos-ha-clusters
   cd k8s-centos-ha-clusters
   sudo su
   chmod +x ./* # Grant execution access to shell scripts
   ```

## Setting Up Load Balancers
1. Modify `lb_config.yml` to configure the IP addresses of your load balancers:
   ```bash
   nano config/lb_config.yml
   ```
2. Run the setup script on each load balancer node:
   ```bash
   ./setup_lb.sh
   ```
3. Verify the HAProxy service status:
   ```bash
   systemctl status haproxy
   ```

## Setting Up Kubernetes Cluster
1. Modify `cluster_config.yml` to list the IP addresses of master and worker nodes:
   ```bash
   nano config/cluster_config.yml
   ```
2. Execute the setup script on each master and worker node to install Kubeadm, Containerd, and other dependencies:
   ```bash
   ./install_kubeadm_containerd.sh
   ```
3. In case of errors, you can reverse the setup by running:
   ```bash
   ./cleanup.sh
   ```
## Setting Up Kubernetes Cluster (Continued)

1. Initializing the First Master Node

    After modifying the `cluster_config.yml` and executing the setup scripts, the next step is to initialize the first master node in the Kubernetes cluster.

2. Choose a CNI Plugin
    - **Options**: Choose a Container Network Interface (CNI) such as Calico, Flannel, etc., for network operations in your Kubernetes cluster.
    - **Documentation**: For more information, visit [Kubernetes CNI plugins documentation](https://kubernetes.io/docs/concepts/cluster-administration/networking/).

3. Initialize with Flannel
    - If you opt for Flannel as your CNI, use `10.244.0.0/16` as the `pod-network-cidr`.
    - **Initialization Command**:
    ```bash
    kubeadm init --control-plane-endpoint "<cluster-vip-ip>:6443" --pod-network-cidr="10.244.0.0/16"
    ```
    Replace `<cluster-vip-ip>` with the virtual IP address of your cluster.

4. Set Up Kubeconfig
    - After initializing the first master node, configure kubeconfig to manage your Kubernetes cluster:
    ```bash
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    ```

5. Verify the Setup
    - Check the setup by listing all pods in the `kube-system` namespace:
    ```bash
    kubectl get pods --namespace=kube-system
    ```

## Installing the CNI Plugin

After the first master node initialization, the next crucial step is to install the selected CNI plugin.

1. Install Flannel CNI
- **Apply Flannel Configuration**: Download and apply the Flannel configuration to your Kubernetes cluster.
  ```bash
  kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
  systemctl restart containerd
  ```
- **Check Installation**: Confirm the deployment of Flannel.
  ```bash
  kubectl get pods --namespace=kube-system
  ```
  Look for `kube-flannel-ds` pods in the `Running` state.

2. Verify Node Network
- Ensure each node is `ready`` and communicating correctly:
  ```bash
  kubectl get nodes
  ```

3. Notes
- **Network Configuration**: By default, Flannel uses the `10.244.0.0/16` subnet.
- **Compatibility**: Ensure there are no conflicts with existing network infrastructures.
- **Alternatives**: If you prefer a different CNI, use the respective configuration file URL for installation.

Following these steps will ensure the successful installation of Flannel as your Kubernetes cluster's CNI, enabling seamless pod-to-pod networking.