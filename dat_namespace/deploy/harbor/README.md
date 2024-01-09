# Install EPEL Release

yum install epel-release wget -y
yum install -y yum-utils

# Install Docker Repo & Docker

yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce

# Install Docker Compose

curl -s https://api.github.com/repos/docker/compose/releases/latest \
 | grep browser_download_url \
 | grep docker-compose-Linux-x86_64 \
 | cut -d '"' -f 4 \
 | wget -qi -
chmod +x docker-compose-Linux-x86_64
sudo mv docker-compose-Linux-x86_64 /usr/local/bin/docker-compose

cd /home/sysadmin/open-sources/harbor_registry

# Make CA && Certificate

cd /home/sysadmin/open-sources/harbor_registry

# GEN Ca

openssl genrsa -des3 -out rootCA.key 2048
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 1825 -out rootCA.pem

# add CA

chrome://settings/security --> Chọn vào Manage certificates Trong hộp thoại hiện ra bạn vào tab Trusted Root Certification Authorities --> Import --> Next --> Browse --> Chọn file rootCA.pem --> Next --> Next --> Finish.
mozilla: truy cập vào đường dẫn sau: about:preferences#privacy. Sau đó, bạn kéo xuống dưới, tại phần Certificates chọn vào View Certificates..., tại popup này, bạn chọn tab Authorities rồi nhấp vào Import... và chọn file rootCA.pem đã tải về bên trên. Hộp thoại Downloading Certificate hiện ra, bạn tick chọn hết 2 mục như hình dưới và chọn OK:

# Gen SSL Certificate Local

nano :openssl.cnf

# Gen key file :

sudo openssl genrsa -out bigdata.key 2048

# Gen Singning Request File :

sudo openssl req -new -out bigdata.csr -key bigdata.key -config openssl.cnf

# Print CA to file : (return file bigdata.crt)

sudo openssl x509 -req -days 3650 -in bigdata.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out bigdata.crt -extensions v3_req -extfile openssl.cnf

# gen File bigdata.pem

cat bigdata.key >> bigdata.pem
cat bigdata.csr >> bigdata.pem
cat bigdata.crt >> bigdata.pem

# Add Client Certificate to Docker Client

mkdir -p /etc/docker/certs.d/harbor.demo.bigdata.com
cd /etc/docker/certs.d/harbor.demo.bigdata.com
cp /certs/harbor.server.demo.bigdata.bigdata . (path fodler gen Cert)
systemctl restart docker

## Download & Extract Harbor

cd /home/sysadmin/open-sources/harbor_registry

# Dowload harbor

wget https://github.com/goharbor/harbor/releases/download/v2.2.3/harbor-offline-installer-v2.2.3.tgz
tar -xvzf harbor-offline-installer-v2.2.3.tgz
cd harbor
cp harbor.yml.tmpl harbor.yml

# Edit config harbor.yml

->edit hostname , port nginx, path certififcate

# Install Harbor

./install.sh --with-notary --with-chartmuseum

# nano domain host

nano etc/hosts 10.16.150.138 harbor.bigdata.com

# Login Harbor

docker login harbor.bigdata.com (admin/Harbor123456)

# Push & Pull Registry

docker pull ubuntu:20.04
docker tag ubuntu:20.04 harbor.server.local/demo/ubuntu:20.04
