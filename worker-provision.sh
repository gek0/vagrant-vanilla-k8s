#!/usr/bin/env bash
set -ex
nodeIP=$(echo $(hostname -I | awk '{print $2}') | tr "." "-")

# disable swap
sudo hostnamectl set-hostname "worker-node-$nodeIP"
echo "worker-node-$nodeIP" > /etc/hostname
echo "export PS1=\"\[\e[1;35m\]\u\[\033[m\]@\[\e[1;92m\]worker-node-$nodeIP\[\033[m\]:\w \$ \"" >> ~/.bashrc

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

## install docker, kubelet, kubeadm and kubectl
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
sudo apt install -y kubelet kubeadm kubectl net-tools
sudo apt-mark hold kubelet kubeadm kubectl

# prepare for Flannel CNI
sudo mkdir -p /run/flannel
sudo tee /run/flannel/subnet.env <<EOF
FLANNEL_NETWORK=10.244.0.0/16
FLANNEL_SUBNET=10.244.0.1/24
FLANNEL_MTU=1450
FLANNEL_IPMASQ=true
EOF
sudo systemctl restart kubelet

echo "I'm ready to join into the cluster!"