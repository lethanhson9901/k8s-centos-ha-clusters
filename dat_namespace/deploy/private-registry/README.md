[Kubernetes] - Hướng dẫn cài đặt Private Docker Registry trên Kubernetes (k8s)
Bài đăng này đã không được cập nhật trong 2 năm

Bạn nên có kho lưu trữ hoặc đăng ký docker riêng trong cụm Kubernetes của mình để bảo mật. Bài viết này mình chia sẻ các cài kho lưu trữ riêng trên Kubernetes.

1.Chuẩn bị
k8s-master – 10.16.150.140 – CentOS 7
k8s-worker-1 – 10.16.150.134 – CentOS 7

2.Các bước cài đặt
Tạo thư mục lưu trữ trước trên tất cả node

sudo mkdir /opt/certs /opt/registry

Đăng nhập vào node master sử dụng lệnh openssl để tạo chứng chỉ tự ký cho kho lưu trữ.

$ cd /opt
$ sudo openssl req -newkey rsa:4096 -nodes -sha256 -keyout \
 ./certs/registry.key -x509 -days 365 -out ./certs/registry.crt

Nhập tên cho các dòng như: khu vực, công ty,.. và bấm enter

Kiểm tra chứng chỉ vừa tạo

[kadmin@k8s-master opt]$ ls -l certs/
total 8
-rw-r--r--. 1 root root 2114 Sep 26 03:26 registry.crt
-rw-r--r--. 1 root root 3272 Sep 26 03:26 registry.key
[kadmin@k8s-master opt]$

Chép 2 file này lên thư mục /opt/cert máy node worker

Trên node master tạo một private-registry.yaml với nội dung sau

[kadmin@k8s-master ~]$ mkdir docker-repo
[kadmin@k8s-master ~]$ cd docker-repo/
[kadmin@k8s-master docker-repo]$ vi private-registry.yaml

Chạy kubectl với yaml file ở trên

[kadmin@k8s-master docker-repo]$ kubectl create -f private-registry.yaml
deployment.apps/private-repository-k8s created
[kadmin@k8s-master docker-repo]$

Kiểm tra trạng thái của registry deployment với pod được tạo ra.

[kadmin@k8s-master ~]$ kubectl get deployments private-repository-k8s
NAME READY UP-TO-DATE AVAILABLE AGE
private-repository-k8s 1/1 1 1 3m32s
[kadmin@k8s-master ~]$
[kadmin@k8s-master ~]$ kubectl get pods | grep -i private-repo
private-repository-k8s-85cf76b9d7-qsjxq 1/1 Running 0 5m14s
[kadmin@k8s-master ~]$

Chép tệp chứng chỉ đăng ký từ thư mục “/opt/cert” vào trong thư mục “/etc/pki/ca-trust /source/anchor” trên tất cả các node.

$ sudo cp /opt/certs/registry.crt /etc/pki/ca-trust/source/anchors/
$ sudo update-ca-trust
$ sudo systemctl restart docker

Triển khai dưới dạng nodeport service ta tạo thêm yaml file với nội dung sau

[kadmin@k8s-master ~]$ cd docker-repo/
[kadmin@k8s-master docker-repo]$ vi private-registry-svc.yaml

Lưu và thoát file.

Chạy lệnh bên dưới để tạo

$ kubectl create -f private-registry-svc.yaml
service/private-repository-k8s created

Kiểm tra trạng thái NodePort vừa tạo

[kadmin@k8s-master ~]$ kubectl get svc private-repository-k8s
NAME TYPE CLUSTER-IP EXTERNAL-IP PORT(S) AGE
private-repository-k8s NodePort 10.100.113.39 <none> 5000:31320/TCP 2m1s
[kadmin@k8s-master ~]$

Bây giờ chúng ta test bằng cách pull một nginx image và upload image lên private registry, từ master node

$ sudo docker pull nginx
$ sudo docker tag nginx:latest k8s-master:31320/nginx:1.17
$ sudo docker push k8s-master:31320/nginx:1.17

Chạy lệnh sau để kiểm tra nginx upload lên private repository chưa.

[kadmin@k8s-master ~]$ sudo docker image ls | grep -i nginx
nginx latest 7e4d58f0e5f3 2 weeks ago 133MB
k8s-master:31320/nginx 1.17 7e4d58f0e5f3 2 weeks ago 133MB
[kadmin@k8s-master ~]$

Bây giờ chúng ta triển khai một nginx cơ bản trên private docker registry ở trên.

[kadmin@k8s-master ~]$ vi nginx-test-deployment.yaml
Lưu và thoát file

Chạy lệnh sau để khởi tạo

[kadmin@k8s-master ~]$ kubectl create -f nginx-test-deployment.yaml
deployment.apps/nginx-test-deployment created
[kadmin@k8s-master ~]$ kubectl get deployments nginx-test-deployment
NAME READY UP-TO-DATE AVAILABLE AGE
nginx-test-deployment 3/3 3 3 13s
[kadmin@k8s-master ~]$
[kadmin@k8s-master ~]$ kubectl get pods | grep nginx-test-deployment
nginx-test-deployment-f488694b5-2rvmv 1/1 Running 0 80s
nginx-test-deployment-f488694b5-8kb6c 1/1 Running 0 80s
nginx-test-deployment-f488694b5-dgcxl 1/1 Running 0 80s
[kadmin@k8s-master ~]$

Xem chi tiết hơn pod vừa tạo ra

$ kubectl describe pod nginx-test-deployment-f488694b5-2rvmv
