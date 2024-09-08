#!/bin/bash

while [ -z "$(ssh -o stricthostkeychecking=no 192.168.56.10 stat /root/.kube)" ]; do
    sleep 5
done

scp -r root@192.168.56.10:/var/cache/apt/archives /var/cache/apt/
bash /vagrant/provision/k8s.sh
echo "KUBELET_EXTRA_ARGS='--node-ip=192.168.56.$1'" > /etc/default/kubelet

while [ -z "$(ssh 192.168.56.10 stat /root/.kube/config)" ]; do
    sleep 5
done

$(ssh 192.168.56.10 kubeadm token create --print-join-command)
apt-get clean
