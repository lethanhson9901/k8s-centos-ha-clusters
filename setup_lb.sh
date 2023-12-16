#!/bin/bash

CONFIG_FILE="config/lb_config.yml"

# Ports configuration
MASTER_PORT="6443"
WORKER_HTTP_PORT="30100"
WORKER_HTTPS_PORT="30101"

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
bash -c "cat <<EOF > /etc/haproxy/haproxy.cfg
frontend kube_apiserver_frontend
  bind *:6443
  mode tcp
  option tcplog
  log global
  default_backend kube_apiserver_backend

$(generate_haproxy_backend kube_apiserver_backend MASTER_NODES[@] tcp $MASTER_PORT)

frontend http_frontend
  bind *:80
  mode tcp
  option tcplog
  log global
  default_backend http_backend

$(generate_haproxy_backend http_backend WORKER_NODES[@] tcp $WORKER_HTTP_PORT)

frontend https_frontend
  bind *:443
  mode tcp
  option tcplog
  log global
  default_backend https_backend

$(generate_haproxy_backend https_backend WORKER_NODES[@] tcp $WORKER_HTTPS_PORT)

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
EOF"

# Restart Keepalived
echo "Restarting Keepalived..."
systemctl restart keepalived
systemctl enable keepalived

echo "Configuration completed."
