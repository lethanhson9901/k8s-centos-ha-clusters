```markdown
# Install Kubernetes (K8s) Metrics Server

This guide provides a step-by-step approach to install the Kubernetes Metrics Server.

## Prerequisites
- Kubernetes cluster
- `kubectl` command-line tool installed
- `curl` command-line tool installed

## Installation Steps

### Step 1: Download Metrics Server Manifest

#### Standard Installation
Download the latest Metrics Server manifest file from the Kubernetes GitHub repository using the following command:

```bash
curl -LO https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

#### High Availability Installation
If you are planning to install the Metrics Server in high availability mode, download the following manifest file:

```bash
curl -LO https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/high-availability-1.21+.yaml
```

### Step 2: Modify Metrics Server Yaml File

Next, modify the Metrics Server YAML file to configure specific options:

1. Open the YAML file for editing:
   ```bash
   vi components.yaml
   ```

2. Locate the `args` section under the `container` section and add the following line:
   ```yaml
   - --kubelet-insecure-tls
   ```

3. Under the `spec` section, add the following parameter:
   ```yaml
   hostNetwork: true
   ```

4. Save and close the file.

### Step 3: Deploy Metrics Server

Deploy the Metrics Server using the following `kubectl` command:

```bash
kubectl apply -f components.yaml
```

### Step 4: Verify Metrics Server Deployment

After deploying the Metrics Server, verify its status by checking the pods' status in the `kube-system` namespace:

```bash
kubectl get pods -n kube-system
```

The output will confirm if the metrics-server pod is up and running.

### Step 5: Test Metrics Server Installation

Finally, test the Metrics Server installation using the following command:

```bash
kubectl top nodes
```

This command will display the resource usage of the nodes in your Kubernetes cluster, indicating that the Metrics Server is functioning correctly.

## Conclusion

By following these steps, you should have successfully installed the Kubernetes Metrics Server in your cluster.
```

This README provides clear, professional instructions for installing the Metrics Server in a Kubernetes cluster, including the steps for downloading, modifying, deploying, verifying, and testing the installation.