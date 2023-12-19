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
4. Initializing the First Master Node in Kubernetes Cluster

    **Choose a CNI (Container Network Interface) Plugin**: You have the option to choose any CNI like Calico, Flannel, etc. for your Kubernetes network. Refer to the Kubernetes documentation for [CNI plugins](https://kubernetes.io/docs/concepts/cluster-administration/networking/).

    **Initialization with Flannel**: If you decide to use Flannel as your CNI, you need to specify the `pod-network-cidr` specific to Flannel(The default pod-network-cidr, or pod CIDR (Classless Inter-Domain Routing), for Flannel in a Kubernetes cluster is typically `10.244.0.0/16``). Initialize the first master node using the following command:

        ```bash
        kubeadm init --control-plane-endpoint "<cluster-vip-ip>:6443" --pod-network-cidr="10.244.0.0/16"
        ```

        Replace `<cluster-vip-ip>` with your cluster's virtual IP address.

    **Setting Up Kubeconfig**:
        After the first master node is initialized, set up kubeconfig to interact with your Kubernetes cluster. Run the following commands:

        ```bash
        mkdir -p $HOME/.kube
        sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
        sudo chown $(id -u):$(id -g) $HOME/.kube/config
        ```

    **Verify the Configuration**:
        Ensure that everything is set up correctly by listing all the pods in the `kube-system` namespace. Use the following kubectl command:

        ```bash
        kubectl get pods --namespace=kube-system
        ```
        This command should list all the system pods, and you can check their status to ensure that they are running correctly.

## 5. Installing the Container Network Interface (CNI) in Kubernetes Cluster

    Once you have initialized the first master node in your Kubernetes cluster, the next critical step is to install a Container Network Interface (CNI) plugin. This plugin is responsible for facilitating network connectivity for the pods in your cluster.

    ### Choosing a CNI Plugin

    Kubernetes supports various CNI plugins, such as Calico, Flannel, Weave, etc. Each CNI has its own set of features and configurations. For this setup, we'll continue with Flannel, which is a simple and easy-to-configure option.

    ### Installing Flannel CNI

    **Download and Apply Flannel Configuration**: To install Flannel, you need to apply its configuration file to your Kubernetes cluster. This can be done using the `kubectl` command. The command below will download and apply the latest Flannel configuration:

        ```bash
        kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
        ```

    **Check for Successful Installation**: After applying the Flannel configuration, it's essential to ensure that it is correctly deployed. You can check the status of Flannel pods in the `kube-system` namespace:

        ```bash
        kubectl get pods --namespace=kube-system
        ```

        Look for the pods that start with `kube-flannel-ds` and ensure they are in the `Running` state.

    **Node Network Verification**: Ensure that each node in your Kubernetes cluster can communicate with others. You can do this by checking the node status:

        ```bash
        kubectl get nodes
        ```

        Each node should be in the `Ready` state, indicating that it's correctly configured and communicating within the cluster network.

    ### Notes on Using Flannel

    - **Network Configuration**: Flannel automatically uses the `10.244.0.0/16` subnet for pod networking, as mentioned in the initialization step of the first master node.
    - **Compatibility**: Ensure that Flannel's network range does not conflict with your existing network infrastructure.
    - **Alternatives**: If you prefer a different CNI, replace the Flannel configuration URL with the configuration file URL of your chosen CNI plugin.

    By following these steps, you will have successfully installed Flannel as the CNI for your Kubernetes cluster, enabling pod-to-pod networking across your nodes.

## Conclusion
Following this guide will help you set up a robust, multi-master Kubernetes cluster on CentOS servers. It's essential to ensure the correct configuration of IP addresses and verify the status of services post-setup for a successful deployment.