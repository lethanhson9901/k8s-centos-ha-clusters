# 1.ssh 10.16.150.138 on local xshell

# 2.fowrard sock4/5 in xhsell with .138 , port 6068

# 3.config foward sock45 in browser , port 6068

# 4.edit hosts in .138:

10.16.150.138 k8s.site

# 4.edit haproxyconfig in .138

frontend Local_Server
bind \*:82
mode http
default_backend k8s_server

backend k8s_server
mode http
balance roundrobin
server worker1 10.16.150.140:30100
server worker1 10.16.150.139:30100

# 4.confis host in ingress-nginx

host:k8s.site

# 5 restart nginx-ingress

kubectl apply -f my-nginx-ingress.yaml

# 6 test on sv harpoxy

curl k8s.site:82 / /dat

#7 test on browser configed shock
http:k8s.site:82 / /dat
