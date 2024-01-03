
## NGINX Ingress Controller Setup Guide for Kubernetes

This guide provides step-by-step instructions for setting up an NGINX Ingress Controller in a Kubernetes environment. The NGINX Ingress Controller allows for the management of external access to HTTP services in a Kubernetes cluster, providing features like load balancing, SSL termination, and name-based virtual hosting.

### Prerequisites

- A Kubernetes cluster
- kubectl, configured to communicate with your cluster
- Git for cloning the repository

### Installation Steps

1. **Clone the NGINX Ingress Controller Repository**

   Clone the specific version (v2.4.2) of the NGINX Ingress Controller repository:

   ```
   git clone https://github.com/nginxinc/kubernetes-ingress/ --branch v2.4.2 ~/kubernetes-ingress
   ```

2. **Navigate to the Deployments Directory**

   Change to the “deployments” directory of the cloned repository:

   ```
   cd ~/kubernetes-ingress/deployments/
   ```

3. **Configure RBAC**

   - **Create Namespace and Service Account**

     The NGINX Ingress Controller runs in an isolated namespace and uses a separate ServiceAccount for accessing the Kubernetes API:

     ```
     kubectl apply -f common/ns-and-sa.yaml
     ```

   - **Enable Access for NGINX Service Account**

     Apply RBAC rules to grant the necessary permissions:

     ```
     kubectl apply -f rbac/rbac.yaml
     ```

4. **Create Common Resources**

   Apply custom resource definitions for various NGINX Ingress Controller resources:

   ```
   kubectl apply -f common/crds/
   ```

   Load the default SSL certificate into Kubernetes:

   ```
   kubectl apply -f common/default-server-secret.yaml
   ```

   Create the NGINX ConfigMap:

   ```
   kubectl apply -f common/nginx-config.yaml
   ```

   Apply the IngressClass resource:

   ```
   kubectl apply -f common/ingress-class.yaml
   ```

5. **Deploy NGINX**

   Deploy the NGINX Ingress Controller as a Deployment or DaemonSet:

   ```
   kubectl apply -f deployment/nginx-ingress.yaml
   ```

   Verify the deployment:

   ```
   kubectl get pods -n nginx-ingress
   ```

6. **Expose NGINX via NodePort**

   Create a NodePort service to expose NGINX:

   ```
   kubectl create -f service/nodeport.yaml
   ```

   Retrieve the NodePort:

   ```
   kubectl get svc -n nginx-ingress
   ```

   Update the service to use ports 80 and 443:

   ```
   kubectl -n nginx-ingress patch svc nginx-ingress --patch '{"spec": { "type": "NodePort", "ports": [ { "port": 80, "nodePort": 30100 }, { "port": 443, "nodePort": 30101 } ] } }'
   ```

7. **Deploy Applications**

   Apply your application deployments to the Kubernetes cluster:

   ```
   kubectl apply -f hello.yaml
   kubectl apply -f my-nginx-deploy.yaml
   ```

8. **Create Ingress Resources**

   Create Ingress resources to manage external access to the services:

   ```
   kubectl create -f my-nginx-ingress.yaml
   ```

9. **Check Service Status**

   Verify the status of the services:

   ```
   kubectl describe ing hello
   kubectl describe ing my-inginx
   ```

### Conclusion

This guide walks you through the process of setting up an NGINX Ingress Controller in a Kubernetes environment, enabling efficient management and routing of external traffic to your applications.
