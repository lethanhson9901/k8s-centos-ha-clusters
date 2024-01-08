# NFS Server Setup for File Sharing in Kubernetes

## Overview
This guide provides detailed instructions for setting up an NFS (Network File System) server for file sharing in a Kubernetes environment. The NFS server will be installed directly on a Kubernetes node (independent, not running a POD). Alternatively, it can be installed on a separate machine dedicated to file sharing.

## Prerequisites
- A Kubernetes node with CentOS 7 operating system (In this guide, we use the server with IP `10.16.150.138`).
- SSH access to the Kubernetes node.
- Basic knowledge of Kubernetes and command line operations.

## NFS Server Installation and Configuration

1. **Install NFS Utilities**: 
    SSH into the server and run the following commands:
    ```bash
    yum install nfs-utils
    systemctl enable rpcbind
    systemctl enable nfs-server
    systemctl enable nfs-lock
    systemctl enable nfs-idmap
    systemctl start rpcbind
    systemctl start nfs-server
    systemctl start nfs-lock
    systemctl start nfs-idmap
    ```

2. **Configure Shared Directory**:
    - Edit the `/etc/exports` file to configure the shared directory.
      ```bash
      vi /etc/exports
      ```
    - Add the following line to share the `/data/mydata/` directory:
      ```
      /data/mydata *(rw,sync,no_subtree_check,insecure)
      ```

3. **Create and Set Permissions for Shared Directory**:
    ```bash
    mkdir -p /data/mydata
    chmod -R 777 /data/mydata
    ```

4. **Export and Verify Configuration**:
    ```bash
    exportfs -rav
    exportfs -v
    showmount -e
    ```

5. **Restart and Check NFS Service**:
    ```bash
    systemctl stop nfs-server
    systemctl start nfs-server
    systemctl status nfs-server
    ```

## Client Setup (Worker Node Configuration)
Perform these steps on a worker node (`worker1.xtl` with IP range `10.16.150.133-135`):

1. **Install NFS Utilities**:
    ```bash
    yum install nfs-utils
    ```

2. **Create Mount Point**:
    ```bash
    mkdir /home/data
    ```

3. **Mount NFS Share**:
    ```bash
    mount -t nfs 10.16.150.138:/data/mydata /home/data/
    ```

4. **Unmount After Testing**:
    ```bash
    umount /home/data
    ```

## Setting Up PersistentVolume and PersistentVolumeClaim for NFS

1. **Create PersistentVolume (PV)**:
    - Use the configuration file `1-pv-nfs.yaml`.

2. **Create PersistentVolumeClaim (PVC)**:
    - Use the configuration file `2-pvc-nfs.yaml`.

3. **Deploy and Verify**:
    ```bash
    kubectl apply -f 1-pv-nfs.yaml
    kubectl apply -f 2-pvc-nfs.yaml
    kubectl get pvc,pv -o wide
    ```

## Mounting PVC into a Container

1. **Deploy a Web Server Using an HTTPD Image**:
    - SSH into the master node, navigate to the shared directory `/data/mydata`, and create a simple `index.html` file with the content:
      ```html
      <h1>Apache is running ...</h1>
      ```
    - Create a deployment file `3-httpd.yaml`, which includes a POD running HTTP and a NodePort service mapping host port 31080 to POD's port 80.

2. **Access the Web Server**:
    - Once deployed, access the web server from any node IP at port `31080` to see the message "Apache Running".

## Conclusion
Following these steps will set up an NFS server in a Kubernetes environment, allowing for efficient file sharing across PODs. Ensure to adjust IP addresses and paths as per your specific setup.

