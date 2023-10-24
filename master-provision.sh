#!/usr/bin/env bash
set -ex
nodeIP=$(echo $(hostname -I | awk '{print $2}') | tr "." "-")

# disable swap
sudo hostnamectl set-hostname "master-node-$nodeIP"
echo "master-node-$nodeIP" > /etc/hostname
echo "export PS1=\"\[\e[1;35m\]\u\[\033[m\]@\[\e[1;92m\]master-node-$nodeIP\[\033[m\]:\w \$ \"" >> ~/.bashrc

sudo swapoff -a
sudo sed -i 's/\/swap/#\/swap/g' /etc/fstab

sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system

sleep 1

## install k8s components
sudo apt-get update -y
sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.gpg
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y containerd.io

containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo apt-get update
sudo apt install -y kubelet kubeadm kubectl net-tools siege etcd-client
sudo apt-mark hold kubelet kubeadm kubectl

############# configure kubeadm (master only)
sudo kubeadm init --apiserver-advertise-address=192.168.56.100 --control-plane-endpoint=192.168.56.100 --pod-network-cidr=10.244.0.0/16

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown "$(id -u):$(id -g)" $HOME/.kube/config

echo -e 'alias ku="kubectl"\ncomplete -F __start_kubectl ku' >> /root/.bashrc

# install k9s
cd /tmp
curl -Lo k9s.tar.gz https://github.com/derailed/k9s/releases/download/v0.27.4/k9s_Linux_amd64.tar.gz
tar xvzf k9s.tar.gz && chmod +x k9s && mv k9s /usr/local/bin

echo "I'm ready and installed!"