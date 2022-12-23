#!/bin/bash

bash /vagrant/provision/common.sh

mkdir -p ~/.kube
mkdir -p /home/vagrant/.kube

echo "KUBELET_EXTRA_ARGS='--node-ip=192.168.56.$1'" > /etc/default/kubelet

kubeadm init --apiserver-advertise-address=192.168.56.10 --pod-network-cidr=10.244.0.0/16
cp /etc/kubernetes/admin.conf ~/.kube/config
cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown -R vagrant: /home/vagrant/.kube

kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
