Vagrant.configure("2") do |config|

    # Load Balancer Nodes
    LoadBalancerCount = 2
    (1..LoadBalancerCount).each do |i|
        config.vm.define "k8s-lb-#{i}" do |lb|
            lb.vm.box = "centos/7"
            lb.vm.hostname = "k8s-lb-#{i}"
            lb.vm.network "private_network", ip: "192.168.56.13#{i+1}"

            lb.vm.provider "virtualbox" do |vb|
                vb.name = "k8s-lb-#{i}"
                vb.memory = 1024
                vb.cpus = 1
            end
        end
    end

    # Master Nodes
    MasterCount = 2
    (1..MasterCount).each do |i|
        config.vm.define "k8s-master-#{i}" do |master|
            master.vm.box = "centos/7"
            master.vm.hostname = "k8s-master-#{i}"
            master.vm.network "private_network", ip: "192.168.56.13#{i+3}"

            master.vm.provider "virtualbox" do |vb|
                vb.name = "k8s-master-#{i}"
                vb.memory = 2048
                vb.cpus = 2
            end
        end
    end

    # Worker Nodes
    WorkerCount = 1
    (1..WorkerCount).each do |i|
        config.vm.define "k8s-worker-#{i}" do |worker|
            worker.vm.box = "centos/7"
            worker.vm.hostname = "k8s-worker-#{i}"
            worker.vm.network "private_network", ip: "192.168.56.13#{i+6}"

            worker.vm.provider "virtualbox" do |vb|
                vb.name = "k8s-worker-#{i}"
                vb.memory = 1024
                vb.cpus = 1
            end
        end
    end

    config.vm.provision "shell" do |s|
        ssh_pub_key = File.readlines("#{Dir.home}/.ssh/id_rsa.pub").first.strip
        s.inline = <<-SHELL
            # Create ci user
            useradd -s /bin/bash -d /home/ci/ -m -G wheel ci
            echo 'ci ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
            mkdir -p /home/ci/.ssh && chown -R ci:ci /home/ci/.ssh
            echo #{ssh_pub_key} >> /home/ci/.ssh/authorized_keys
            restorecon -Rv /home/ci/.ssh
        SHELL
    end    

end
