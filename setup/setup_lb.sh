#!/bin/bash

CONFIG_FILE="config/lb_config.yml"

# Ports configuration
MASTER_PORT="6443"
WORKER_HTTP_PORT="30100"
WORKER_HTTPS_PORT="30101"

# Set hostname based on IP address
MY_IP=$(hostname -I | awk '{print $1}')
case $MY_IP in
    10.16.150.139) hostnamectl set-hostname k8s-master-1 ;;
    10.16.150.140) hostnamectl set-hostname k8s-master-2 ;;
    10.16.150.134) hostnamectl set-hostname k8s-worker-1 ;;
    10.16.150.135) hostnamectl set-hostname k8s-worker-2 ;;
    10.16.150.136) hostnamectl set-hostname k8s-worker-3 ;;
    10.16.150.132) hostnamectl set-hostname k8s-lb-1 ;;
    10.16.150.133) hostnamectl set-hostname k8s-lb-2 ;;
    10.16.150.252) hostnamectl set-hostname vip ;;
    *) echo "IP address not recognized. Hostname not changed." ;;
esac

# Configure /etc/hosts
cat <<EOF > /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

10.16.150.139      k8s-master-1
10.16.150.140      k8s-master-2
10.16.150.134      k8s-worker-1
10.16.150.135      k8s-worker-2
10.16.150.136      k8s-worker-3
10.16.150.132      k8s-lb-1
10.16.150.133      k8s-lb-2
10.16.150.252      vip
EOF

# Check if the config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Read values from the YAML file
CLUSTER_VIP=$(yq e '.cluster_vip' "$CONFIG_FILE")
MASTER_NODES=($(yq e '.master_nodes[]' "$CONFIG_FILE"))
WORKER_NODES=($(yq e '.worker_nodes[]' "$CONFIG_FILE"))

# Install psmisc
echo "Installing psmisc..."
yum install -y psmisc --enablerepo=extras

# Install haproxy
echo "Installing haproxy..."
yum install -y haproxy

# Create haproxy conf empty file
echo "Creating empty haproxy configuration file..."
touch /etc/haproxy/haproxy.cfg

# Function to generate HAProxy backend configuration
generate_haproxy_backend() {
    local backend_name=$1
    local nodes=("${!2}")
    local mode=$3
    local port=$4

    echo "  backend ${backend_name}"
    echo "    mode ${mode}"
    echo "    balance roundrobin"
    echo "    timeout connect 10s"
    echo "    timeout client 30s"
    echo "    timeout server 30s"

    for node in "${nodes[@]}"; do
        echo "    server ${node} ${node}:${port} check"
    done
}

# Configure HAProxy
echo "Configuring HAProxy..."
bash -c "cat <<EOF | sudo tee /etc/haproxy/haproxy.cfg
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
    server k8s-master-1 10.16.150.139:6443 check fall 3 rise 2
    server k8s-master-2 10.16.150.140:6443 check fall 3 rise 2
  
frontend http_frontend
  bind *:80
  mode tcp
  option tcplog
  default_backend http_backend

backend http_backend
  mode tcp
  balance roundrobin
    server k8s-worker-1 10.16.150.134:30100 check send-proxy-v2
    server k8s-worker-2 10.16.150.135:30100 check send-proxy-v2
    server k8s-worker-3 10.16.150.136:30100 check send-proxy-v2

frontend https_frontend
  bind *:443
  mode tcp
  option tcplog
  default_backend https_backend

backend https_backend
  mode tcp
  balance roundrobin
    server k8s-worker-1 10.16.150.134:30101 check send-proxy-v2
    server k8s-worker-2 10.16.150.135:30101 check send-proxy-v2
    server k8s-worker-3 10.16.150.136:30101 check send-proxy-v2
EOF"

# Restart HAProxy
echo "Restarting HAProxy..."
systemctl restart haproxy
systemctl enable haproxy

# Install keepalived
echo "Installing keepalived..."
yum install -y keepalived

# Create keepalived.conf empty file
echo "Creating empty keepalived configuration file..."
touch /etc/keepalived/keepalived.conf

# Configure Keepalived
echo "Configuring Keepalived..."
bash -c "cat <<EOF > /etc/keepalived/keepalived.conf
global_defs {
    router_id LVS_DEVEL
}

vrrp_script check_apiserver {
  script "/etc/keepalived/check_apiserver.sh"
  interval 3
  weight -2
  fall 10
  rise 2
}

vrrp_instance VI_1 {
    state MASTER
    interface eth0
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
EOF"

# Restart Keepalived
echo "Restarting Keepalived..."
systemctl restart keepalived
systemctl enable keepalived

echo "Configuration completed."
