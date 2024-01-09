#!/bin/bash

#Change nameserver to 8.8.8.8
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null

sudo sed -e 's|^mirrorlist=|#mirrorlist=|g' \
         -e 's|^#baseurl=http://mirror.centos.org/centos|baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos|g' \
         -i.bak \
         /etc/yum.repos.d/CentOS-*.repo

yum update -y && yum -y install  wget psmisc vim net-tools nfs-utils telnet yum-utils device-mapper-persistent-data lvm2 git tar curl

# Download necessary tools
yum -y install createrepo yum-utils wget epel*

# Download all dependency packages
repotrack createrepo wget psmisc vim net-tools nfs-utils telnet yum-utils device-mapper-persistent-data lvm2 git tar curl gcc keepalived haproxy bash-completion chrony sshpass ipvsadm ipset sysstat conntrack libseccomp

# Remove libseccomp
rm -rf libseccomp-*.rpm

# Download libseccomp
wget http://rpmfind.net/linux/centos/8-stream/BaseOS/x86_64/os/Packages/libseccomp-2.5.1-1.el8.x86_64.rpm

#Create yum source information
createrepo -u -d /data/centos7/

# Copy the package to the intranet machine
scp -r /data/centos7/ root@192.168.1.31:
scp -r /data/centos7/ root@192.168.1.32:
scp -r /data/centos7/ root@192.168.1.33:
scp -r /data/centos7/ root@192.168.1.34:
scp -r /data/centos7/ root@192.168.1.35:

# Create a repo configuration file on the intranet machine
rm -rf /etc/yum.repos.d/*
cat > /etc/yum.repos.d/123.repo << EOF
[cby]
name=CentOS-$releasever-Media
baseurl=file:///root/centos7/
gpgcheck=0
enabled=1
EOF

#Install the downloaded package
yum clean all
yum makecache
yum install /root/centos7/* --skip-broken -y

#### Remark #####
# After the installation is completed, there may be a situation where yum cannot be used, so execute it again.
rm -rf /etc/yum.repos.d/*
cat > /etc/yum.repos.d/123.repo << EOF
[cby]
name=CentOS-$releasever-Media
baseurl=file:///root/centos7/
gpgcheck=0
enabled=1
EOF
yum clean all
yum makecache
yum install /root/centos7/* --skip-broken -y

#### Remark #####
# Install chrony and libseccomp
# yum install /root/centos7/libseccomp-2.5.1*.rpm -y
# yum install /root/centos7/chrony-*.rpm -y


