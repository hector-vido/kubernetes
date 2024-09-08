#!/bin/bash

echo 'br_netfilter' > /etc/modules-load.d/k8s.conf
modprobe br_netfilter

echo 'net.ipv4.ip_forward = 1' > /etc/sysctl.d/k8s.conf
sysctl --system

apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg2 vim telnet nfs-common

export K8S_VERSION='v1.31'
export CRIO_VERSION='v1.30'

# Kubernetes
curl -fsSL https://pkgs.k8s.io/core:/stable:/$K8S_VERSION/deb/Release.key |
    gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$K8S_VERSION/deb/ /" |
    tee /etc/apt/sources.list.d/kubernetes.list

# CRI-O
curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/stable:/$CRIO_VERSION/deb/Release.key |
    gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/stable:/$CRIO_VERSION/deb/ /" |
    tee /etc/apt/sources.list.d/cri-o.list

apt-get update
apt-get install -y cri-o kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

systemctl enable --now crio
