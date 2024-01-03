ssh 10.16.150.138

# “git” the NGINX ingress controller repo

git clone https://github.com/nginxinc/kubernetes-ingress/ --branch v2.4.2 ~/kubernetes-ingress

# Change to the “deployments” directory of the newly cloned repo

cd ~/kubernetes-ingress/deployments/

# Configure RBAC

# 1.Create NameSpace and Service Account

# The NGINX Ingress Controller runs in an isolated NameSpace and uses a separate ServiceAccount for accessing the Kubernetes API. Run this command to create the “nginx-ingress” namespace and service account:

kubectl apply -f common/ns-and-sa.yaml

# 2.In this lab environment RBAC is enabled and you will need to enable access from the NGINX Service Account to the Kubernetes API.

kubectl apply -f rbac/rbac.yaml

# Create Common Resources

# Create NGINX IC custom resource definitions for VirtualServer and VirtualServerRoute, TransportServer and Policy resources

kubectl apply -f common/crds/k8s.nginx.org_virtualservers.yaml
kubectl apply -f common/crds/k8s.nginx.org_virtualserverroutes.yaml
kubectl apply -f common/crds/k8s.nginx.org_transportservers.yaml
kubectl apply -f common/crds/k8s.nginx.org_policies.yaml

# The Ingress Controller will use a “default” SSL certificate for requests that are not configured to use an explicit certificate. The following loads the default certificate into Kubernetes:

kubectl apply -f common/default-server-secret.yaml

# Create a NGINX ConfigMap

kubectl apply -f common/nginx-config.yaml

# Create an IngressClass resource

kubectl apply -f common/ingress-class.yaml

# Create a Deployment¶

We will be deploying NGINX as a deployment. There are two options:

Deployment. Use a Deployment if you plan to dynamically change the number of Ingress controller replicas.
DaemonSet. Use a DaemonSet for deploying the Ingress controller on every node or a subset of nodes.

# Deploy NGINX

kubectl apply -f deployment/nginx-ingress.yaml
kubectl get pods -n nginx-ingress

# Expose NGINX via NodePort

# 1.Create NodePort service

kubectl create -f service/nodeport.yaml

# Retrieve NodePort

kubectl get svc -n nginx-ingress

# Change port nginx ingress to 80/443

kubectl -n nginx-ingress patch svc nginx-ingress --patch '{"spec": { "type": "NodePort", "ports": [ { "port": 80, "nodePort": 30100 }, { "port": 443, "nodePort": 30101 } ] } }'

# Check Nginx above port 30100 maps to port 80 on NGINX.

Access NGINX From Outside the Cluster(View Browser)

# 5.Deploy your app to k8s cluster

kubectl apply -f hello.yaml
kubectl apply -f my-nginx-deploy.yaml

# Create Ingress resource

vi my-nginx-ingress.yaml
kubectl create -f my-nginx-ingress.yaml

# check status service on ingress nginx

kubectl describe ing hello
kubectl describe ing my-inginx
