# Kubernetes (K8s) Metrics Server Installation Guide

This guide will walk you through the installation of the Kubernetes Metrics Server, which is essential for gathering and displaying cluster-wide resource utilization statistics. Follow the steps below to set up Metrics Server on your Kubernetes cluster.

## Pre-built method
```
cd son_namespace/metrics-server
kubectl apply -f components.yaml
```

## Step-by-step:
### Step 1: Download Metrics Server Manifest

The first step is to download the latest Metrics Server manifest file from the Kubernetes GitHub repository using the following `curl` command:

```bash
curl -LO https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

If you intend to install Metrics Server in high-availability mode, use the following command to download the appropriate manifest file:

```bash
curl https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/high-availability-1.21+.yaml
```

### Step 2: Modify Metrics Server Yaml File

Next, you need to modify the Metrics Server YAML file to configure some options. Open the YAML file in a text editor, for example:

```bash
vi components.yaml
```

Find the `args` section under the `container` section and add the following line to enable insecure TLS communication with the kubelet:

```yaml
- --kubelet-insecure-tls
```

Under the `spec` section, add the following parameter to allow host networking:

```yaml
hostNetwork: true
```

Save and close the file.

### Step 3: Deploy Metrics Server

Now that you've configured the Metrics Server YAML file, deploy the Metrics Server using the following `kubectl` command:

```bash
kubectl apply -f components.yaml
```

## Verify Metrics Server Deployment

After deploying the Metrics Server, verify its status by checking the pods running in the `kube-system` namespace:

```bash
kubectl get pods -n kube-system
```

The output should confirm that the metrics-server pod is up and running.

## Test Metrics Server Installation

Finally, test the Metrics Server installation by running the following `kubectl` command to view resource utilization statistics for the nodes in your cluster:

```bash
kubectl top nodes
```

Congratulations! You have successfully installed the Kubernetes Metrics Server on your cluster. You can now monitor and collect resource metrics for your Kubernetes nodes.