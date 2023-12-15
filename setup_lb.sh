#!/bin/bash

# Define the cluster VIP (replace with your actual cluster VIP)
CLUSTER_VIP="your_cluster_vip"  # Replace with the actual cluster VIP

# Install HAProxy
sudo yum update -y
sudo yum install -y haproxy

# Configure HAProxy
sudo tee /etc/haproxy/haproxy.cfg << EOF
frontend kube_apiserver_frontend
  bind *:6443
  mode tcp
  option tcplog
  default_backend kube_apiserver_backend

backend kube_apiserver_backend
  option httpchk GET /healthz
  http-check expect status 200
  mode tcp
  option ssl-hello-chk
  balance roundrobin
    server k8s-master-1 172.16.1.11:6443 check fall 3 rise 2
    server k8s-master-2 172.16.1.12:6443 check fall 3 rise 2
    server k8s-master-3 172.16.1.13:6443 check fall 3 rise 2

frontend http_frontend
  bind *:80
  mode tcp
  option tcplog
  default_backend http_backend

backend http_backend
  mode tcp
  balance roundrobin
    server k8s-worker-1 172.16.2.11:30100 check send-proxy-v2
    server k8s-worker-2 172.16.2.12:30100 check send-proxy-v2
    server k8s-worker-3 172.16.2.13:30100 check send-proxy-v2

frontend https_frontend
  bind *:443
  mode tcp
  option tcplog
  default_backend https_backend

backend https_backend
  mode tcp
  balance roundrobin
    server k8s-worker-1 172.16.2.11:30101 check send-proxy-v2
    server k8s-worker-2 172.16.2.12:30101 check send-proxy-v2
    server k8s-worker-3 172.16.2.13:30101 check send-proxy-v2
EOF

# Restart HAProxy
sudo systemctl restart haproxy
sudo systemctl enable haproxy

# Install Keepalived
sudo yum install -y keepalived

# Configure Keepalived
sudo tee /etc/keepalived/keepalived.conf << EOF
vrrp_script check_apiserver {
  script "killall -0 haproxy"
  interval 3
  timeout 10
}

vrrp_instance VI_1 {
    state MASTER
    interface eth1
    virtual_router_id 201
    priority 200
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass secret
    }
    virtual_ipaddress {
        $CLUSTER_VIP/24
    }
    track_script {
        check_apiserver
    }
}
EOF

# Restart Keepalived
sudo systemctl restart keepalived
sudo systemctl enable keepalived

echo "Load balancer setup complete."
