#!/usr/bin/env bash
# Apply standard OS updates
sudo apt-get update
sudo apt-get upgrade
# 
apt install net-tools
# Shared prerequisite 
sudo apt-get install -y ca-certificates
sudo apt-get install -y curl
# docker prerequisite
sudo apt-get install -y gnupg
sudo apt-get install -y lsb-release
# docker repo setup
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list
# docker install
sudo apt-get update
sudo apt-get install -y docker-ce 
sudo apt-get install -y docker-ce-cli
sudo apt-get install -y containerd.io
# validate docker setup
sudo docker run hello-world
# kubernetes prerequisite
sudo apt-get install -y apt-transport-https
# kubernetes repo setup
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo \
  "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] \
  https://apt.kubernetes.io/ \
  kubernetes-xenial main" \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list
#
sudo apt-get update
sudo apt-get install -y kubeadm
sudo apt-get install -y kubectl
sudo apt-get install -y kubelet
#sudo apt-mark hold kubeadm kubectl kubelet
#
#cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
#br_netfilter
#EOF
#
#cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
#net.bridge.bridge-nf-call-ip6tables = 1
#net.bridge.bridge-nf-call-iptables = 1
#EOF
#sudo sysctl --system
#
#EOF