#!/bin/bash

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg2 vim telnet nfs-common

export OS='Debian_11'
export VERSION='1.24'
export PREFIX='signed-by=/usr/share/keyrings'

echo "deb [$PREFIX/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" \
	> /etc/apt/sources.list.d/kubernetes.list
echo "deb [$PREFIX/libcontainers-archive-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /" \
	> /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
echo "deb [$PREFIX/libcontainers-crio-archive-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /" \
	> /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list

mkdir -p /usr/share/keyrings
curl -L https://packages.cloud.google.com/apt/doc/apt-key.gpg > /usr/share/keyrings/kubernetes-archive-keyring.gpg
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key \
	| gpg --dearmor > /usr/share/keyrings/libcontainers-archive-keyring.gpg
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/Release.key \
	| gpg --dearmor > /usr/share/keyrings/libcontainers-crio-archive-keyring.gpg

apt-get update
apt-get install -y cri-o cri-o-runc kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

systemctl enable --now crio
