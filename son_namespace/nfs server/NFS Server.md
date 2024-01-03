## Cài đặt NFS làm Server chia sẻ file (Kubernetes)

## Sử dụng Volume để các POD cùng một dữ liệu, cần một loại đĩa mạng, ví dụ này sẽ thực hành dùng NFS. Ta sẽ cài đặt một Server NFS trực tiếp trên một Node của Kubernetes (độc lập, không chạy POD, nếu muốn bạn có thể cài trên một máy khác chuyên chia sẻ file).

## Ta sẽ Server NFS (10.16.150.138) (Node này là HDH CentOS 7), vậy hãy SSH vào svvà thực hiện:

yum install nfs-utils
systemctl enable rpcbind
systemctl enable nfs-server
systemctl enable nfs-lock
systemctl enable nfs-idmap
systemctl start rpcbind
systemctl start nfs-server
systemctl start nfs-lock
systemctl start nfs-idmap

## Tạo (mở) file /etc/exports để soạn thảo, ở đây sẽ cấu hình để chia sẻ thư mục /data/mydata/

vi /etc/exports
/data/mydata \*(rw,sync,no_subtree_check,insecure)
#Lưu thông lại, và thực hiện

# Tạo thư mục

mkdir -p /data/mydata
chmod -R 777 /data/mydata

# export và kiểm tra cấu hình chia sẻ

exportfs -rav
exportfs -v
showmount -e

# Khởi động lại và kiểm tra dịch vụ

systemctl stop nfs-server
systemctl start nfs-server
systemctl status nfs-server

# Server này có địa chỉ IP 10.16.150.138,

# giờ vào máy ở Node worker1.xtl (10.16.150.133-135) thực hiện mount thử ổ đĩa xem có hoạt động không.

yum install nfs-utils
mkdir /home/data

# Gắn ổ đĩa

mount -t nfs 10.16.150.138:/data/mydata /home/data/

# Kiểm tra xong, hủy gắn ổ đĩa

umount /home/data

## Tạo PersistentVolume NFS

1-pv-nfs.yaml

## Tạo PersistentVolumeClaim NFS

2-pvc-nfs.yaml

## Triển khai và kiểm tra

kubectl apply -f 2-pvc-nfs.yaml
kubectl get pvc,pv -o wide

## Mount PersistentVolumeClaim NFS vào Container

## Ta sẽ triển khai chạy máy chủ web từ image httpd.

SSH vào máy master, vào thư mục chia sẻ /data/mydata tạo một file index.html với nội dung đơn giản, ví dụ:

<h1>Apache is running ...</h1>
Tạo file triển khai, gồm có POD chạy http và dịch vụ kiểu NodePort, ánh xạ cổng host 31080 vào cổng 80 của POD

3-httpd.yaml

## Sau khi triển khai, truy cập từ một IP của các node và cổng 31080

## Apache Running
