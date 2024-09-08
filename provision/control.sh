#!/bin/bash

bash /vagrant/provision/k8s.sh

# The presence of ~/.kube indicate to workers that they 
# can download the packages from control
mkdir -p ~/.kube

echo "KUBELET_EXTRA_ARGS='--node-ip=192.168.56.$1'" > /etc/default/kubelet

# Ensure pause image is the same for kubeadm and crictl
PAUSE=`kubeadm config images list | grep pause`
sed -Ei "s,(signature.*),\1\npause_image = \"$PAUSE\"," /etc/crio/crio.conf.d/10-crio.conf
systemctl restart crio

kubeadm init --apiserver-advertise-address=192.168.56.10 --pod-network-cidr=10.244.0.0/16

# The presence of ~/.kube/config indicate to workers that they
# can join the cluster
cp /etc/kubernetes/admin.conf ~/.kube/config

# Change from docker.io to quay.io to avoid Docker Hub constraints
curl -sL https://docs.projectcalico.org/manifests/calico.yaml | sed 's,docker,quay,' > calico.yml
kubectl create -f calico.yml

# Enable colorful "ls"
sed -Ei 's/# (export LS)/\1/' /root/.bashrc
sed -Ei 's/# (eval ")/\1/' /root/.bashrc
sed -Ei 's/# (alias ls=)/\1/' /root/.bashrc
# Force bash to save history after each command
echo "export PROMPT_COMMAND='history -a'" >> /root/.bashrc

install --mode=755 /vagrant/files/check.sh /usr/local/bin/k8s-check
install --mode=755 /vagrant/files/tasks.sh /usr/local/bin/k8s-tasks
install --mode=755 /vagrant/manifests/solve.sh /usr/local/bin/k8s-solve
install --mode=755 /vagrant/provision/challenge.sh /usr/local/bin/k8s-challenge
