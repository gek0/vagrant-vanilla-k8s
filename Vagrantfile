# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure("2") do |config|
  # nodes count
  WorkerNodeCount = 3

  # master node
  config.vm.define "master-node" do |master|
    master.vm.box = "bento/ubuntu-22.04"
    master.vm.hostname = "master-node-192-168-56-100"
    master.vm.network "private_network", ip: "192.168.56.100"

    master.vm.provider "virtualbox" do |vb|
      vb.gui = false
      vb.name = "master-node"
      vb.memory = 2512
      vb.cpus = 2
    end

    master.vm.provision "shell",
    inline: "echo 'KUBELET_EXTRA_ARGS=\"--node-ip=192.168.56.100\"' >> /etc/default/kubelet"
    master.vm.provision "shell",
    inline: "echo '192.168.56.100 master-node-192-168-56-100' >> /etc/hosts"

    master.vm.provision :shell, path: "master-provision.sh"
    master.vm.synced_folder "k8s/", "/root/k8s"
  end

  # worker nodes
  (1..WorkerNodeCount).each do |i|
    config.vm.define "worker-node-#{i}" do |worker|
      worker.vm.box = "bento/ubuntu-22.04"
      worker.vm.hostname = "worker-node-192-168-56-#{i+1}"
      worker.vm.network "private_network", ip: "192.168.56.#{i+1}"

      worker.vm.provider "virtualbox" do |vb|
        vb.gui = false
        vb.name = "worker-node-#{i}"
        vb.memory = 3768
        vb.cpus = 2
      end

      worker.vm.provision "shell",
      inline: "echo 'KUBELET_EXTRA_ARGS=\"--node-ip=192.168.56.#{i+1}\"' >> /etc/default/kubelet"
      worker.vm.provision "shell",
      inline: "echo '192.168.56.100 master-node-192-168-56-100' >> /etc/hosts"
      worker.vm.provision "shell",
      inline: "echo \"192.168.56.#{i+1} worker-node-192-168-56-#{i+1}\" >> /etc/hosts"

      worker.vm.provision :shell, path: "worker-provision.sh"
    end
  end
end
